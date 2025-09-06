AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

local ENT = ENT

local MAX_BORDER_HEIGHT = 2048
local BORDER_HEIGHT_STEP = 8

-- Network strings
util.AddNetworkString("MinigolfDesigner_OpenMenu")
util.AddNetworkString("MinigolfDesigner_AddPart")
util.AddNetworkString("MinigolfDesigner_UpdateMesh")
util.AddNetworkString("MinigolfDesigner_SetBorderHeight")
util.AddNetworkString("MinigolfDesigner_ToggleEditMode")
util.AddNetworkString("MinigolfDesigner_SyncMesh")

--- Spawns the track designer flush with the ground
function ENT:SpawnFunction(player, trace, className)
  if not IsValid(player) or not trace.Hit then return end

  local spawnPos = trace.HitPos
  local spawnAngles = player:EyeAngles()
  spawnAngles.pitch = 0
  local entity = ents.Create(className)
  entity:SetPos(spawnPos)
  entity:SetAngles(spawnAngles)
  entity:Spawn()
  entity:Activate()

  return entity
end

function ENT:Initialize()
  self:SetModel("models/hunter/blocks/cube025x025x025.mdl")
  self:PhysicsInit(SOLID_VPHYSICS)
  self:SetMoveType(MOVETYPE_NONE)
  self:SetSolid(SOLID_VPHYSICS)
  self:SetUseType(SIMPLE_USE)

  local phys = self:GetPhysicsObject()
  if IsValid(phys) then
    phys:Wake()
    phys:EnableMotion(false)
  end

  -- Initialize track system
  self.trackParts = {}
  self.currentEditingPart = nil
  self.nextPartID = 1
  self.editMode = false

  -- Create the starting piece
  self:CreateStartPart()
  self:BuildPhysicsFromCurrentParts()

  self:ToggleEditMode(false)
end

function ENT:BuildPhysicsFromCurrentParts()
  local tris = {}

  for _, part in ipairs(self.trackParts) do
    local md = self:GenerateMeshData(part)
    if md and md.boxes then
      for _, box in ipairs(md.boxes) do
        local v = box.vertices or {}
        for i = 1, #v, 3 do
          local p1 = self:WorldToLocal(v[i].pos)
          local p2 = self:WorldToLocal(v[i + 1].pos)
          local p3 = self:WorldToLocal(v[i + 2].pos)
          tris[#tris + 1] = { pos = p1 }
          tris[#tris + 1] = { pos = p2 }
          tris[#tris + 1] = { pos = p3 }
        end
      end
    end
  end

  if #tris > 0 then
    self:PhysicsFromMesh(tris)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_NONE)
    self:EnableCustomCollisions(true)
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
      phys:Wake()
      phys:EnableMotion(false)
    end
  end
end

function ENT:Use(activator, caller)
  if not IsValid(activator) or not activator:IsPlayer() then return end

  -- Open the track designer menu
  net.Start("MinigolfDesigner_OpenMenu")
  net.WriteEntity(self)
  net.Send(activator)
end

function ENT:CreateStartPart()
  local startPart = self:CreateTrackPart("start", self:GetPos())
  self.trackParts[1] = startPart
  return startPart
end

function ENT:CreateTrackPart(partTypeId, position, connectionSide)
  local config = self:GetPartTypeConfig(partTypeId)
  if not config then
    print("Error: Unknown part type: " .. tostring(partTypeId))
    return nil
  end

  local part = {
    id = self.nextPartID,
    type = partTypeId,
    position = position or Vector(0, 0, 0),
    connectedSides = {}, -- Use a table to track multiple connected sides
    vertexEntities = {},
    meshData = {},
    entities = {},
    borderHeight = self.BORDER_HEIGHT,
  }

  -- Add the initial connection if provided
  if connectionSide then
    part.connectedSides[connectionSide] = true
  end

  self.nextPartID = self.nextPartID + 1

  self:CreateVertexEntities(part)
  self:CreatePartEntities(part)
  self:SyncMeshToClients(part)
  self:BuildPhysicsFromCurrentParts()

  return part
end

function ENT:CreateVertexEntities(part)
  local pos = part.position
  local w = self.TRACK_WIDTH / 2
  local l = self.TRACK_LENGTH / 2
  local trackHeight = 2 -- Match the track surface height

  -- Create vertex entities at the track surface level
  local vertexPositions = {
    pos + Vector(-w, -l, trackHeight), -- Bottom left at track surface
    pos + Vector(w, -l, trackHeight),  -- Bottom right at track surface
    pos + Vector(w, l, trackHeight),   -- Top right at track surface
    pos + Vector(-w, l, trackHeight),  -- Top left at track surface
  }

  -- Create vertex entities
  for i, vertexPos in ipairs(vertexPositions) do
    local vertexEnt = ents.Create("minigolf_track_designer_vertex")
    vertexEnt:SetPos(vertexPos)
    vertexEnt:SetAngles(Angle(0, 0, 0))
    vertexEnt:Spawn()
    vertexEnt:SetVertexData(self, part.id, i, "track", "")

    part.vertexEntities[i] = vertexEnt
  end

  -- Create border height control entities
  self:CreateBorderControls(part)
end

function ENT:CreateBorderControls(part)
  local pos = part.position
  local w = self.TRACK_WIDTH / 2
  local l = self.TRACK_LENGTH / 2
  local bh = part.borderHeight

  -- Create border height controls on each side at the TOP of the border
  local borderPositions = {
    { name = "left",  pos = pos + Vector(-w - self.BORDER_WIDTH, 0, bh) },
    { name = "right", pos = pos + Vector(w + self.BORDER_WIDTH, 0, bh) },
    { name = "front", pos = pos + Vector(0, -l - self.BORDER_WIDTH, bh) },
    { name = "back",  pos = pos + Vector(0, l + self.BORDER_WIDTH, bh) }
  }

  for _, borderData in ipairs(borderPositions) do
    -- Check if this side is connected
    if not part.connectedSides[borderData.name] then
      local borderControl = ents.Create("minigolf_track_designer_vertex")
      borderControl:SetPos(borderData.pos)
      borderControl:Spawn()
      borderControl:SetVertexData(self, part.id, borderData.name, "border", borderData.name)

      part.vertexEntities["border_" .. borderData.name] = borderControl
    end
  end
end

-- Flag to prevent feedback loops
ENT.isUpdatingConnections = false

function ENT:OnVertexMoved(partID, vertexIndex, vertexType, newPos)
  local part = self:GetPartByID(partID)
  if not part then return end

  if self.isUpdatingConnections then return end

  if vertexType == "border" then
    -- Handle border height changes
    local newHeight = math.max(8, math.min(MAX_BORDER_HEIGHT, newPos.z - part.position.z))

    -- Snap to step increments
    newHeight = math.Round(newHeight / BORDER_HEIGHT_STEP) * BORDER_HEIGHT_STEP

    if math.abs(part.borderHeight - newHeight) > 1 then
      part.borderHeight = newHeight
      -- self:UpdateBorderControls(part) -- causes glitching
      self:UpdatePartMesh(partID)
    end
  else
    self:UpdateTrackVertexDirect(part, vertexIndex, newPos)
  end
end

function ENT:UpdateTrackVertexDirect(part, vertexIndex, newPos)
  if not part.customVertices then
    part.customVertices = {}
  end

  part.customVertices[vertexIndex] = newPos

  -- Update connected neighboring vertices for path continuity
  self:UpdateConnectedNeighbors(part, vertexIndex, newPos)

  self.isUpdatingConnections = false

  -- Regenerate mesh with new vertex positions
  self:UpdatePartMesh(part.id)
end

function ENT:UpdateConnectedNeighbors(part, movedVertexIndex, movedPos)
  -- Find the part index in the track
  local partIndex = nil
  for i, trackPart in ipairs(self.trackParts) do
    if trackPart.id == part.id then
      partIndex = i
      break
    end
  end

  if not partIndex then return end

  -- Define which vertices connect between parts to form a continuous path
  -- For a rectangular track part:
  -- Vertex 1 (bottom-left) and 2 (bottom-right) connect to the PREVIOUS part's vertices 3,4
  -- Vertex 3 (top-right) and 4 (top-left) connect to the NEXT part's vertices 1,2

  -- Get the original position to calculate the change
  local originalPos = self:GetDefaultVertexPosition(part, movedVertexIndex)
  local deltaPos = movedPos - originalPos

  -- Update previous part connection
  if partIndex > 1 and (movedVertexIndex == 1 or movedVertexIndex == 2) then
    local prevPart = self.trackParts[partIndex - 1]
    local connectVertexIndex = (movedVertexIndex == 1) and 4 or 3 -- 1->4, 2->3

    self:UpdateConnectedVertex(prevPart, connectVertexIndex, deltaPos)
  end

  -- Update next part connection
  if partIndex < #self.trackParts and (movedVertexIndex == 3 or movedVertexIndex == 4) then
    local nextPart = self.trackParts[partIndex + 1]
    local connectVertexIndex = (movedVertexIndex == 4) and 1 or 2 -- 4->1, 3->2

    self:UpdateConnectedVertex(nextPart, connectVertexIndex, deltaPos)
  end
end

function ENT:UpdateConnectedVertex(targetPart, vertexIndex, deltaPos)
  -- Get the current default position of the target vertex
  local defaultPos = self:GetDefaultVertexPosition(targetPart, vertexIndex)

  -- Calculate the new position based on the delta
  local newPos = defaultPos + deltaPos

  -- Store the custom vertex position (don't move the entity directly)
  if not targetPart.customVertices then
    targetPart.customVertices = {}
  end
  targetPart.customVertices[vertexIndex] = newPos

  -- Update the vertex entity position WITHOUT triggering events
  if targetPart.vertexEntities[vertexIndex] and IsValid(targetPart.vertexEntities[vertexIndex]) then
    -- Use a safe method to update position that doesn't trigger movement events
    targetPart.vertexEntities[vertexIndex]:SetPos(newPos)

    -- If the vertex entity has a method to update position without triggering events, use that
    -- You might need to add a flag to the vertex entity to ignore position updates
    if targetPart.vertexEntities[vertexIndex].SetPositionSilent then
      targetPart.vertexEntities[vertexIndex]:SetPositionSilent(newPos)
    end
  end

  -- Update the mesh for this part
  self:UpdatePartMesh(targetPart.id)
end

function ENT:UpdateBorderControls(part)
  local pos = part.position
  local w = self.TRACK_WIDTH / 2
  local l = self.TRACK_LENGTH / 2
  local bh = part.borderHeight

  -- Position border controls at the TOP of the border, not the middle
  local borderPositions = {
    { name = "left",  pos = pos + Vector(-w - self.BORDER_WIDTH, 0, bh) }, -- Changed from bh/2 to bh
    { name = "right", pos = pos + Vector(w + self.BORDER_WIDTH, 0, bh) },  -- Changed from bh/2 to bh
    { name = "front", pos = pos + Vector(0, -l - self.BORDER_WIDTH, bh) }, -- Changed from bh/2 to bh
    { name = "back",  pos = pos + Vector(0, l + self.BORDER_WIDTH, bh) }   -- Changed from bh/2 to bh
  }

  for _, borderData in ipairs(borderPositions) do
    local controlKey = "border_" .. borderData.name
    if part.vertexEntities[controlKey] and IsValid(part.vertexEntities[controlKey]) then
      part.vertexEntities[controlKey]:SetPos(borderData.pos)
    end
  end
end

function ENT:OnVertexRemoved(partID, vertexIndex, vertexType)
  -- Handle vertex removal if needed
end

function ENT:GenerateMeshData(part)
  local meshData = {
    boxes = {},
    partType = part.type,
    borderHeight = part.borderHeight
  }

  -- Generate floor boxes from part type configuration with custom vertices
  local config = self:GetPartTypeConfig(part.type)
  if config and config.boxes then
    for i, boxConfig in ipairs(config.boxes) do
      local boxMeshData = {
        vertices = {},
        materialKey = self:GetMaterialKeyForBox(boxConfig),
        boxType = boxConfig.type
      }

      -- Use custom vertex positions if available for floor elements
      if part.customVertices and boxConfig.type == "floor" then
        self:CreateCustomTrackMesh(part, boxMeshData.vertices, boxConfig)
      else
        -- Use standard box mesh for non-track elements
        local adjustedMin = part.position + boxConfig.min
        local adjustedMax = part.position + boxConfig.max
        self:CreateBoxMesh(boxMeshData.vertices, adjustedMin, adjustedMax)
      end

      table.insert(meshData.boxes, boxMeshData)
    end
  end

  -- Generate border boxes (these remain at original height for now)
  self:GenerateBorderMeshData(part, meshData)

  return meshData
end

function ENT:CreateCustomTrackMesh(part, vertices, boxConfig)
  -- Get vertex positions (custom or default)
  local vertexPositions = {}

  for i = 1, 4 do
    if part.customVertices and part.customVertices[i] then
      vertexPositions[i] = part.customVertices[i]
    else
      vertexPositions[i] = self:GetDefaultVertexPosition(part, i)
    end
  end

  -- Create the track surface using the vertex positions
  local thickness = 2 -- Track thickness

  -- Create the bottom surface
  -- The bottom surface should be AT the vertex height
  local bottomVerts = {}
  for i = 1, 4 do
    bottomVerts[i] = Vector(vertexPositions[i].x, vertexPositions[i].y, vertexPositions[i].z)
  end

  -- Create the top surface (the playable track surface)
  local topVerts = {}
  for i = 1, 4 do
    topVerts[i] = Vector(vertexPositions[i].x, vertexPositions[i].y, vertexPositions[i].z + thickness)
  end

  -- Create the top surface (counter-clockwise winding)
  self:CreateQuadSurface(vertices, bottomVerts[1], bottomVerts[2], bottomVerts[3], bottomVerts[4], Vector(0, 0, 1))

  -- Create the bottom surface (clockwise winding for proper normals)
  self:CreateQuadSurface(vertices, topVerts[4], topVerts[3], topVerts[2], topVerts[1], Vector(0, 0, -1))

  -- Create the side surfaces connecting top to bottom
  self:CreateQuadSurface(vertices, topVerts[1], topVerts[2], bottomVerts[2], bottomVerts[1],
    self:CalculateNormal(topVerts[1], topVerts[2], bottomVerts[2])) -- Front
  self:CreateQuadSurface(vertices, topVerts[2], topVerts[3], bottomVerts[3], bottomVerts[2],
    self:CalculateNormal(topVerts[2], topVerts[3], bottomVerts[3])) -- Right
  self:CreateQuadSurface(vertices, topVerts[3], topVerts[4], bottomVerts[4], bottomVerts[3],
    self:CalculateNormal(topVerts[3], topVerts[4], bottomVerts[4])) -- Back
  self:CreateQuadSurface(vertices, topVerts[4], topVerts[1], bottomVerts[1], bottomVerts[4],
    self:CalculateNormal(topVerts[4], topVerts[1], bottomVerts[1])) -- Left
end

function ENT:GetDefaultVertexPosition(part, vertexIndex)
  local pos = part.position
  local w = self.TRACK_WIDTH / 2
  local l = self.TRACK_LENGTH / 2
  local trackHeight = 2 -- Match the thickness used in track generation

  local positions = {
    pos + Vector(-w, -l, trackHeight), -- 1: Bottom left (front-left) at track surface level
    pos + Vector(w, -l, trackHeight),  -- 2: Bottom right (front-right) at track surface level
    pos + Vector(w, l, trackHeight),   -- 3: Top right (back-right) at track surface level
    pos + Vector(-w, l, trackHeight),  -- 4: Top left (back-left) at track surface level
  }

  return positions[vertexIndex]
end

function ENT:CalculateNormal(p1, p2, p3)
  local v1 = p2 - p1
  local v2 = p3 - p1
  local normal = v1:Cross(v2)
  normal:Normalize()
  return normal
end

function ENT:CreateQuadSurface(vertices, p1, p2, p3, p4, normal)
  -- Calculate UV coordinates based on world position
  local texScale = 64
  local u1, v1 = p1.x / texScale, p1.y / texScale
  local u2, v2 = p2.x / texScale, p2.y / texScale
  local u3, v3 = p3.x / texScale, p3.y / texScale
  local u4, v4 = p4.x / texScale, p4.y / texScale

  -- First triangle (p1, p2, p3) - counter-clockwise
  table.insert(vertices, { pos = p1, u = u1, v = v1, normal = normal })
  table.insert(vertices, { pos = p2, u = u2, v = v2, normal = normal })
  table.insert(vertices, { pos = p3, u = u3, v = v3, normal = normal })

  -- Second triangle (p1, p3, p4) - counter-clockwise
  table.insert(vertices, { pos = p1, u = u1, v = v1, normal = normal })
  table.insert(vertices, { pos = p3, u = u3, v = v3, normal = normal })
  table.insert(vertices, { pos = p4, u = u4, v = v4, normal = normal })
end

function ENT:GetMaterialKeyForBox(boxConfig)
  -- Extract material key from the material path
  local material = boxConfig.material
  if material == self.MATERIALS.RED_CARPET then
    return "start"
  elseif material == self.MATERIALS.GREEN_CARPET then
    return "continuous"
  else
    return "border"
  end
end

function ENT:GenerateBorderMeshData(part, meshData)
  local pos = part.position
  local w = self.TRACK_WIDTH / 2
  local l = self.TRACK_LENGTH / 2
  local bw = self.BORDER_WIDTH
  local bh = part.borderHeight

  local borders = {
    {
      name = "left",
      min = pos + Vector(-w - bw, -l, 0),
      max = pos + Vector(-w, l, bh)
    },
    {
      name = "right",
      min = pos + Vector(w, -l, 0),
      max = pos + Vector(w + bw, l, bh)
    },
    {
      name = "front",
      min = pos + Vector(-w, -l - bw, 0),
      max = pos + Vector(w, -l, bh)
    },
    {
      name = "back",
      min = pos + Vector(-w, l, 0),
      max = pos + Vector(w, l + bw, bh)
    }
  }

  for _, border in ipairs(borders) do
    -- Check if this side is connected
    if not part.connectedSides[border.name] then
      local borderMeshData = {
        vertices = {},
        materialKey = "border",
        boxType = "border"
      }

      self:CreateBoxMesh(borderMeshData.vertices, border.min, border.max)
      table.insert(meshData.boxes, borderMeshData)
    end
  end
end

function ENT:CreateBoxMesh(vertices, minPos, maxPos)
  -- Validate that we have a proper box
  local size = maxPos - minPos
  if size.x <= 0 or size.y <= 0 or size.z <= 0 then
    print("Warning: Invalid box dimensions", size)
    return
  end

  -- Define the 8 corners of the box
  local corners = {
    minPos,                               -- 1: min corner
    Vector(maxPos.x, minPos.y, minPos.z), -- 2: +X from min
    Vector(maxPos.x, maxPos.y, minPos.z), -- 3: +X+Y from min
    Vector(minPos.x, maxPos.y, minPos.z), -- 4: +Y from min
    Vector(minPos.x, minPos.y, maxPos.z), -- 5: +Z from min
    Vector(maxPos.x, minPos.y, maxPos.z), -- 6: +X+Z from min
    maxPos,                               -- 7: max corner
    Vector(minPos.x, maxPos.y, maxPos.z)  -- 8: +Y+Z from min
  }

  -- Define the 6 faces of the box with correct winding order (counter-clockwise when viewed from outside)
  local faces = {
    -- Bottom face (looking up at it from below) - Z down
    { corners[1], corners[2], corners[3], corners[4], normal = Vector(0, 0, -1) },
    -- Top face (looking down at it from above) - Z up
    { corners[5], corners[8], corners[7], corners[6], normal = Vector(0, 0, 1) },
    -- Front face (-Y) - looking at it from negative Y direction
    { corners[1], corners[5], corners[6], corners[2], normal = Vector(0, -1, 0) },
    -- Back face (+Y) - looking at it from positive Y direction
    { corners[3], corners[7], corners[8], corners[4], normal = Vector(0, 1, 0) },
    -- Left face (-X) - looking at it from negative X direction
    { corners[4], corners[8], corners[5], corners[1], normal = Vector(-1, 0, 0) },
    -- Right face (+X) - looking at it from positive X direction
    { corners[2], corners[6], corners[7], corners[3], normal = Vector(1, 0, 0) }
  }

  -- Convert each quad face into two triangles with improved UV mapping
  for _, face in ipairs(faces) do
    local p1, p2, p3, p4 = face[1], face[2], face[3], face[4]
    local normal = face.normal

    -- Calculate UV coordinates based on face orientation
    local u1, v1, u2, v2, u3, v3, u4, v4

    if math.abs(normal.z) > 0.9 then
      -- Top/bottom face - use X,Y for UV with improved scaling
      local texScale = 64 -- Texture units per world unit
      u1, v1 = p1.x / texScale, p1.y / texScale
      u2, v2 = p2.x / texScale, p2.y / texScale
      u3, v3 = p3.x / texScale, p3.y / texScale
      u4, v4 = p4.x / texScale, p4.y / texScale
    elseif math.abs(normal.x) > 0.9 then
      -- Left/right face - use Y,Z for UV
      local texScale = 64
      u1, v1 = p1.y / texScale, p1.z / texScale
      u2, v2 = p2.y / texScale, p2.z / texScale
      u3, v3 = p3.y / texScale, p3.z / texScale
      u4, v4 = p4.y / texScale, p4.z / texScale
    else
      -- Front/back face - use X,Z for UV
      local texScale = 64
      u1, v1 = p1.x / texScale, p1.z / texScale
      u2, v2 = p2.x / texScale, p2.z / texScale
      u3, v3 = p3.x / texScale, p3.z / texScale
      u4, v4 = p4.x / texScale, p4.z / texScale
    end

    -- Create triangles with consistent counter-clockwise winding order
    -- First triangle (p1, p2, p3) - counter-clockwise when viewed from outside
    table.insert(vertices, { pos = p1, u = u1, v = v1, normal = normal })
    table.insert(vertices, { pos = p2, u = u2, v = v2, normal = normal })
    table.insert(vertices, { pos = p3, u = u3, v = v3, normal = normal })

    -- Second triangle (p1, p3, p4) - counter-clockwise when viewed from outside
    table.insert(vertices, { pos = p1, u = u1, v = v1, normal = normal })
    table.insert(vertices, { pos = p3, u = u3, v = v3, normal = normal })
    table.insert(vertices, { pos = p4, u = u4, v = v4, normal = normal })
  end
end

function ENT:SyncMeshToClients(part)
  local meshData = self:GenerateMeshData(part)

  -- Send mesh data to all clients
  net.Start("MinigolfDesigner_SyncMesh")
  net.WriteEntity(self)
  net.WriteUInt(part.id, 16)
  net.WriteTable(meshData)
  net.Broadcast()
end

function ENT:CreatePartEntities(part)
  local config = self:GetPartTypeConfig(part.type)
  if not config or not config.entities then return end

  for _, entityConfig in ipairs(config.entities) do
    local entity = ents.Create(entityConfig.type)
    entity:SetPos(part.position + entityConfig.offset)

    -- Apply keyvalues with string formatting support
    for key, value in pairs(entityConfig.keyvalues) do
      local formattedValue = string.format(value, part.id, part.id) -- Support %d placeholders
      entity:SetKeyValue(key, formattedValue)
    end

    entity:Spawn()
    part.entities[entityConfig.type] = entity
  end

  -- Create OOB trigger above borders
  local oobTrigger = ents.Create("minigolf_trigger_oob")
  oobTrigger:SetPos(part.position + Vector(0, 0, self.BORDER_HEIGHT + 32))
  oobTrigger:SetKeyValue("mins",
    string.format("%d %d %d", -self.TRACK_WIDTH / 2 - self.BORDER_WIDTH, -self.TRACK_LENGTH / 2 - self.BORDER_WIDTH, 0))
  oobTrigger:SetKeyValue("maxs",
    string.format("%d %d %d", self.TRACK_WIDTH / 2 + self.BORDER_WIDTH, self.TRACK_LENGTH / 2 + self.BORDER_WIDTH, 64))
  oobTrigger:Spawn()

  part.entities.oobTrigger = oobTrigger
end

function ENT:AddPartToTrack(partTypeId, connectionSide)
  local lastPart = self.trackParts[#self.trackParts]
  local connectionPoint = lastPart.position + Vector(0, self.TRACK_LENGTH, 0)

  -- Mark the last part as connected on the back side
  lastPart.connectedSides["back"] = true
  -- Remove the back border control entity if it exists
  local backControlKey = "border_back"
  if lastPart.vertexEntities[backControlKey] and IsValid(lastPart.vertexEntities[backControlKey]) then
    lastPart.vertexEntities[backControlKey]:Remove()
    lastPart.vertexEntities[backControlKey] = nil
  end
  self:SyncMeshToClients(lastPart)

  -- Create the new part with front side connected
  local newPart = self:CreateTrackPart(partTypeId, connectionPoint, "front")

  -- NEW: Inherit vertex heights from the last part's back vertices
  if lastPart.customVertices then
    if not newPart.customVertices then
      newPart.customVertices = {}
    end

    -- Get the back vertices from the last part (vertices 3 and 4)
    -- and apply them to the front vertices of the new part (vertices 1 and 2)
    if lastPart.customVertices[3] then                           -- top-right of last part
      newPart.customVertices[2] = Vector(newPart.customVertices[2] or self:GetDefaultVertexPosition(newPart, 2))
      newPart.customVertices[2].z = lastPart.customVertices[3].z -- inherit Z height
    end

    if lastPart.customVertices[4] then                           -- top-left of last part
      newPart.customVertices[1] = Vector(newPart.customVertices[1] or self:GetDefaultVertexPosition(newPart, 1))
      newPart.customVertices[1].z = lastPart.customVertices[4].z -- inherit Z height
    end

    -- Update the vertex entity positions to match the inherited heights
    if newPart.vertexEntities[1] and IsValid(newPart.vertexEntities[1]) and newPart.customVertices[1] then
      newPart.vertexEntities[1]:SetPos(newPart.customVertices[1])
    end
    if newPart.vertexEntities[2] and IsValid(newPart.vertexEntities[2]) and newPart.customVertices[2] then
      newPart.vertexEntities[2]:SetPos(newPart.customVertices[2])
    end
  end

  -- Also inherit border height from the last part
  newPart.borderHeight = lastPart.borderHeight

  -- Update border control positions with the inherited height
  self:UpdateBorderControls(newPart)

  table.insert(self.trackParts, newPart)

  -- Resync the new part's mesh with the updated vertex positions
  self:SyncMeshToClients(newPart)
  self:BuildPhysicsFromCurrentParts()

  return newPart
end

function ENT:RemoveBorderConnection(part, side)
  -- Also remove the border control entity
  local controlKey = "border_" .. side
  if part.vertexEntities[controlKey] and IsValid(part.vertexEntities[controlKey]) then
    part.vertexEntities[controlKey]:Remove()
    part.vertexEntities[controlKey] = nil
  end

  part.connectionSide = side

  self:SyncMeshToClients(part)
  self:BuildPhysicsFromCurrentParts()
end

function ENT:UpdatePartMesh(partID)
  local part = self:GetPartByID(partID)
  if not part then return end

  self:SyncMeshToClients(part)
  self:BuildPhysicsFromCurrentParts()
end

function ENT:GetPartByID(id)
  for _, part in ipairs(self.trackParts) do
    if part.id == id then
      return part
    end
  end
  return nil
end

function ENT:ToggleEditMode(enable)
  self.editMode = enable

  -- Show/hide vertex entities
  for _, part in ipairs(self.trackParts) do
    for _, vertexEnt in pairs(part.vertexEntities) do
      if IsValid(vertexEnt) then
        if enable then
          vertexEnt:SetNoDraw(false)
          vertexEnt:GetPhysicsObject():Wake()
        else
          vertexEnt:SetNoDraw(true)
          vertexEnt:GetPhysicsObject():Sleep()
        end
      end
    end
  end
end

function ENT:OnRemove()
  -- Clean up all created entities
  for _, part in ipairs(self.trackParts) do
    -- Remove vertex entities
    for _, vertexEnt in pairs(part.vertexEntities) do
      if IsValid(vertexEnt) then
        vertexEnt:Remove()
      end
    end

    -- Remove game entities
    for _, entity in pairs(part.entities) do
      if IsValid(entity) then
        entity:Remove()
      end
    end
  end
end

-- Network message handlers
net.Receive("MinigolfDesigner_AddPart", function(len, ply)
  local designerEnt = net.ReadEntity()
  local partType = net.ReadString()

  if IsValid(designerEnt) and designerEnt:GetClass() == "minigolf_track_designer" then
    designerEnt:AddPartToTrack(partType, "front")
  end
end)

net.Receive("MinigolfDesigner_ToggleEditMode", function(len, ply)
  local designerEnt = net.ReadEntity()
  local enable = net.ReadBool()

  if IsValid(designerEnt) and designerEnt:GetClass() == "minigolf_track_designer" then
    designerEnt:ToggleEditMode(enable)
  end
end)
