AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

local ENT = ENT

local MAX_BORDER_HEIGHT = 2048
local BORDER_HEIGHT_STEP = 8

resource.AddFile("materials/entities/minigolf_track_designer.png")

-- Network strings
util.AddNetworkString("MinigolfDesigner_OpenMenu")
util.AddNetworkString("MinigolfDesigner_AddPart")
util.AddNetworkString("MinigolfDesigner_UpdateMesh")
util.AddNetworkString("MinigolfDesigner_SetBorderHeight")
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
  local startPart = self:CreateTrackPart("start", self:GetPos(), self:GetAngles())
  self.trackParts[1] = startPart
  return startPart
end

function ENT:CreateTrackPart(partTypeId, position, angles, connectionSide)
  local config = self:GetPartTypeConfig(partTypeId)
  if not config then
    print("Error: Unknown part type: " .. tostring(partTypeId))
    return nil
  end

  local part = {
    id = self.nextPartID,
    type = partTypeId,
    position = position or Vector(0, 0, 0),
    angles = angles or Angle(0, 0, 0),
    connectedSides = {}, -- Use a table to track multiple connected sides
    meshData = {},
    entities = {},
    borderHeight = self.BORDER_HEIGHT,
  }

  -- Add the initial connection if provided
  if connectionSide then
    part.connectedSides[connectionSide] = true
  end

  self.nextPartID = self.nextPartID + 1

  self:CreatePartEntities(part)
  self:SyncMeshToClients(part)
  self:BuildPhysicsFromCurrentParts()

  return part
end

-- Flag to prevent feedback loops
ENT.isUpdatingConnections = false

function ENT:OnVertexMoved(partID, vertexIndex, vertexType, newPos)
  local part = self:GetPartByID(partID)
  if not part then return end

  -- Check if vertex manipulation is blocked for this part type
  local config = self:GetPartTypeConfig(part.type)
  if config and config.blockVertexManipulation and vertexType == "track" then
    -- Don't allow track vertex manipulation for parts with blockVertexManipulation = true
    return
  end

  if vertexType == "track" and self:IsVertexConnectedToBlockedPart(part, vertexIndex) then
    -- Don't allow manipulation of vertices connected to blocked parts
    return
  end

  if self.isUpdatingConnections then return end

  if vertexType == "border" then
    -- Handle border height changes
    local newHeight = math.max(8, math.min(MAX_BORDER_HEIGHT, newPos.z - part.position.z))

    -- Snap to step increments
    newHeight = math.Round(newHeight / BORDER_HEIGHT_STEP) * BORDER_HEIGHT_STEP

    if math.abs(part.borderHeight - newHeight) > 1 then
      part.borderHeight = newHeight
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
  -- Check if the source part has blocked vertex manipulation
  local sourceConfig = self:GetPartTypeConfig(part.type)
  if sourceConfig and sourceConfig.blockVertexManipulation then
    return -- Don't propagate changes from blocked parts
  end

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
    local prevConfig = self:GetPartTypeConfig(prevPart.type)

    -- Only update if the target part allows vertex manipulation
    if not prevConfig or not prevConfig.blockVertexManipulation then
      local connectVertexIndex = (movedVertexIndex == 1) and 4 or 3 -- 1->4, 2->3
      self:UpdateConnectedVertex(prevPart, connectVertexIndex, deltaPos)
    end
  end

  -- Update next part connection
  if partIndex < #self.trackParts and (movedVertexIndex == 3 or movedVertexIndex == 4) then
    local nextPart = self.trackParts[partIndex + 1]
    local nextConfig = self:GetPartTypeConfig(nextPart.type)

    -- Only update if the target part allows vertex manipulation
    if not nextConfig or not nextConfig.blockVertexManipulation then
      local connectVertexIndex = (movedVertexIndex == 4) and 1 or 2 -- 4->1, 3->2
      self:UpdateConnectedVertex(nextPart, connectVertexIndex, deltaPos)
    end
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

  -- Update the mesh for this part
  self:UpdatePartMesh(targetPart.id)
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
      elseif boxConfig.type == "floor" then
        -- Use oriented box mesh for floor elements that need rotation support
        self:CreateOrientedFloorMesh(part, boxMeshData.vertices, boxConfig)
      else
        ErrorNoHalt("Warning: Unsupported box type in part config: " .. tostring(boxConfig.type) .. "\n")
      end

      table.insert(meshData.boxes, boxMeshData)
    end
  end

  -- Generate border boxes (these remain at original height for now)
  self:GenerateBorderMeshData(part, meshData)

  return meshData
end

function ENT:CreateOrientedFloorMesh(part, vertices, boxConfig)
  local pos = part.position
  local angles = part.angles or Angle(0, 0, 0)

  -- Get the relative min/max from the box config
  local relativeMin = boxConfig.min
  local relativeMax = boxConfig.max

  -- Create the 8 corners of the box in local space
  local localCorners = {
    Vector(relativeMin.x, relativeMin.y, relativeMin.z), -- 1: min corner
    Vector(relativeMax.x, relativeMin.y, relativeMin.z), -- 2: +X from min
    Vector(relativeMax.x, relativeMax.y, relativeMin.z), -- 3: +X+Y from min
    Vector(relativeMin.x, relativeMax.y, relativeMin.z), -- 4: +Y from min
    Vector(relativeMin.x, relativeMin.y, relativeMax.z), -- 5: +Z from min
    Vector(relativeMax.x, relativeMin.y, relativeMax.z), -- 6: +X+Z from min
    Vector(relativeMax.x, relativeMax.y, relativeMax.z), -- 7: max corner
    Vector(relativeMin.x, relativeMax.y, relativeMax.z)  -- 8: +Y+Z from min
  }

  -- Rotate all corners and convert to world coordinates
  local worldCorners = {}
  for i, corner in ipairs(localCorners) do
    local rotatedCorner = Vector(corner)
    rotatedCorner:Rotate(angles)
    worldCorners[i] = pos + rotatedCorner
  end

  -- Use the existing CreateOrientedBoxMesh function
  self:CreateOrientedBoxMesh(vertices, worldCorners)
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
  -- For some reason these are at -thickness, otherwise the normals are inverted
  local bottomVerts = {}
  for i = 1, 4 do
    bottomVerts[i] = Vector(vertexPositions[i].x, vertexPositions[i].y, vertexPositions[i].z - thickness)
  end

  -- Create the top surface (the playable track surface)
  local topVerts = {}
  for i = 1, 4 do
    topVerts[i] = Vector(vertexPositions[i].x, vertexPositions[i].y, vertexPositions[i].z)
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
  local angles = part.angles or Angle(0, 0, 0)
  local w = self.TRACK_WIDTH / 2
  local l = self.TRACK_LENGTH / 2
  local trackHeight = 2 -- Match the thickness used in track generation

  -- Define relative positions first
  local relativePositions = {
    Vector(-w, -l, trackHeight), -- 1: Bottom left (front-left) at track surface level
    Vector(w, -l, trackHeight),  -- 2: Bottom right (front-right) at track surface level
    Vector(w, l, trackHeight),   -- 3: Top right (back-right) at track surface level
    Vector(-w, l, trackHeight),  -- 4: Top left (back-left) at track surface level
  }

  -- Rotate the relative position by the part's angles and add to world position
  local relativePos = Vector(relativePositions[vertexIndex])
  relativePos:Rotate(angles)
  return pos + relativePos
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

-- Replace the GenerateBorderMeshData function with this version
function ENT:GenerateBorderMeshData(part, meshData)
  local pos = part.position
  local angles = part.angles or Angle(0, 0, 0)
  local w = self.TRACK_WIDTH / 2
  local l = self.TRACK_LENGTH / 2
  local bw = self.BORDER_WIDTH
  local bh = part.borderHeight

  -- Define border data with 8 corner points for each border
  local borders = {
    {
      name = "left",
      corners = {
        Vector(-w - bw, -l, 0),  -- 1: bottom-front-left
        Vector(-w, -l, 0),       -- 2: bottom-front-right
        Vector(-w, l, 0),        -- 3: bottom-back-right
        Vector(-w - bw, l, 0),   -- 4: bottom-back-left
        Vector(-w - bw, -l, bh), -- 5: top-front-left
        Vector(-w, -l, bh),      -- 6: top-front-right
        Vector(-w, l, bh),       -- 7: top-back-right
        Vector(-w - bw, l, bh),  -- 8: top-back-left
      }
    },
    {
      name = "right",
      corners = {
        Vector(w, -l, 0),       -- 1: bottom-front-left
        Vector(w + bw, -l, 0),  -- 2: bottom-front-right
        Vector(w + bw, l, 0),   -- 3: bottom-back-right
        Vector(w, l, 0),        -- 4: bottom-back-left
        Vector(w, -l, bh),      -- 5: top-front-left
        Vector(w + bw, -l, bh), -- 6: top-front-right
        Vector(w + bw, l, bh),  -- 7: top-back-right
        Vector(w, l, bh),       -- 8: top-back-left
      }
    },
    {
      name = "front",
      corners = {
        Vector(-w, -l - bw, 0),  -- 1: bottom-front-left
        Vector(w, -l - bw, 0),   -- 2: bottom-front-right
        Vector(w, -l, 0),        -- 3: bottom-back-right
        Vector(-w, -l, 0),       -- 4: bottom-back-left
        Vector(-w, -l - bw, bh), -- 5: top-front-left
        Vector(w, -l - bw, bh),  -- 6: top-front-right
        Vector(w, -l, bh),       -- 7: top-back-right
        Vector(-w, -l, bh),      -- 8: top-back-left
      }
    },
    {
      name = "back",
      corners = {
        Vector(-w, l, 0),       -- 1: bottom-front-left
        Vector(w, l, 0),        -- 2: bottom-front-right
        Vector(w, l + bw, 0),   -- 3: bottom-back-right
        Vector(-w, l + bw, 0),  -- 4: bottom-back-left
        Vector(-w, l, bh),      -- 5: top-front-left
        Vector(w, l, bh),       -- 6: top-front-right
        Vector(w, l + bw, bh),  -- 7: top-back-right
        Vector(-w, l + bw, bh), -- 8: top-back-left
      }
    }
  }

  for _, border in ipairs(borders) do
    -- Check if this side is connected
    if not part.connectedSides[border.name] then
      -- Rotate all corner points and convert to world coordinates
      local worldCorners = {}
      for i, corner in ipairs(border.corners) do
        local rotatedCorner = Vector(corner)
        rotatedCorner:Rotate(angles)
        worldCorners[i] = pos + rotatedCorner
      end

      local borderMeshData = {
        vertices = {},
        materialKey = "border",
        boxType = "border"
      }

      -- Create the oriented box mesh directly from the 8 corners
      self:CreateOrientedBoxMesh(borderMeshData.vertices, worldCorners)
      table.insert(meshData.boxes, borderMeshData)
    end
  end
end

-- New function to create a box mesh from 8 oriented corner points
function ENT:CreateOrientedBoxMesh(vertices, corners)
  -- Validate that we have 8 corners
  if #corners ~= 8 then
    print("Warning: CreateOrientedBoxMesh requires exactly 8 corners")
    return
  end

  -- Define the 6 faces of the box using the corner indices
  -- corners[1-4] are bottom face, corners[5-8] are top face
  local faces = {
    -- Bottom face (1,2,3,4) - looking up from below
    { corners[1], corners[2], corners[3], corners[4], normal = Vector(0, 0, -1) },
    -- Top face (5,8,7,6) - looking down from above (reversed winding)
    { corners[5], corners[8], corners[7], corners[6], normal = Vector(0, 0, 1) },
    -- Front face (1,5,6,2) - looking from front
    { corners[1], corners[5], corners[6], corners[2], normal = Vector(0, -1, 0) },
    -- Back face (3,7,8,4) - looking from back
    { corners[3], corners[7], corners[8], corners[4], normal = Vector(0, 1, 0) },
    -- Left face (4,8,5,1) - looking from left
    { corners[4], corners[8], corners[5], corners[1], normal = Vector(-1, 0, 0) },
    -- Right face (2,6,7,3) - looking from right
    { corners[2], corners[6], corners[7], corners[3], normal = Vector(1, 0, 0) }
  }

  -- Convert each quad face into two triangles
  for _, face in ipairs(faces) do
    local p1, p2, p3, p4 = face[1], face[2], face[3], face[4]

    -- Calculate the actual normal from the face geometry
    local v1 = p2 - p1
    local v2 = p3 - p1
    local normal = v1:Cross(v2)
    normal:Normalize()

    -- Calculate UV coordinates based on face orientation
    local u1, v1, u2, v2, u3, v3, u4, v4

    if math.abs(normal.z) > 0.9 then
      -- Top/bottom face - use X,Y for UV
      local texScale = 64
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
    -- First triangle (p1, p2, p3)
    table.insert(vertices, { pos = p1, u = u1, v = v1, normal = normal })
    table.insert(vertices, { pos = p2, u = u2, v = v2, normal = normal })
    table.insert(vertices, { pos = p3, u = u3, v = v3, normal = normal })

    -- Second triangle (p1, p3, p4)
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

  local angles = part.angles or Angle(0, 0, 0)

  for _, entityConfig in ipairs(config.entities) do
    local entity = ents.Create(entityConfig.type)

    -- Rotate the offset by the part's angles before adding to position
    local rotatedOffset = Vector(entityConfig.offset)
    rotatedOffset:Rotate(angles)
    entity:SetPos(part.position + rotatedOffset)
    entity:SetAngles(angles) -- Set the entity's angles to match the part

    -- Apply keyvalues with string formatting support
    for key, value in pairs(entityConfig.keyvalues) do
      local formattedValue = string.format(value, part.id, part.id) -- Support %d placeholders
      entity:SetKeyValue(key, formattedValue)
    end

    entity:Spawn()
    part.entities[entityConfig.type] = entity
  end
end

function ENT:AddPartToTrack(partTypeId, connectionSide)
  local lastPart = self.trackParts[#self.trackParts]
  local lastAngles = lastPart.angles or Angle(0, 0, 0)

  -- Calculate connection point based on the last part's forward direction
  local forwardVector = lastAngles:Right() * -1
  local connectionPoint = lastPart.position + forwardVector * self.TRACK_LENGTH

  -- Mark the last part as connected on the back side
  lastPart.connectedSides["back"] = true

  self:SyncMeshToClients(lastPart)

  -- Create the new part with front side connected, inheriting angles from the last part
  local newPart = self:CreateTrackPart(partTypeId, connectionPoint, lastAngles, "front")

  -- Inherit vertex heights from the last part's back vertices
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
  end

  -- Also inherit border height from the last part
  newPart.borderHeight = lastPart.borderHeight

  table.insert(self.trackParts, newPart)

  -- Resync the new part's mesh with the updated vertex positions
  self:SyncMeshToClients(newPart)
  self:BuildPhysicsFromCurrentParts()

  return newPart
end

function ENT:RemoveBorderConnection(part, side)
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

-- Helper function to check if a vertex is connected to a blocked part
function ENT:IsVertexConnectedToBlockedPart(part, vertexIndex)
  -- Find the part index in the track
  local partIndex = nil
  for i, trackPart in ipairs(self.trackParts) do
    if trackPart.id == part.id then
      partIndex = i
      break
    end
  end

  if not partIndex then return false end

  -- Check if this vertex connects to previous part (vertices 1,2 connect to previous part's vertices 3,4)
  if partIndex > 1 and (vertexIndex == 1 or vertexIndex == 2) then
    local prevPart = self.trackParts[partIndex - 1]
    local prevConfig = self:GetPartTypeConfig(prevPart.type)
    if prevConfig and prevConfig.blockVertexManipulation then
      return true -- Connected to a blocked part
    end
  end

  -- Check if this vertex connects to next part (vertices 3,4 connect to next part's vertices 1,2)
  if partIndex < #self.trackParts and (vertexIndex == 3 or vertexIndex == 4) then
    local nextPart = self.trackParts[partIndex + 1]
    local nextConfig = self:GetPartTypeConfig(nextPart.type)
    if nextConfig and nextConfig.blockVertexManipulation then
      return true -- Connected to a blocked part
    end
  end

  return false
end

function ENT:OnRemove()
  -- Clean up all created entities
  for _, part in ipairs(self.trackParts) do
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
