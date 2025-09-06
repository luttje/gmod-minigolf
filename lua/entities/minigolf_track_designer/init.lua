AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

local ENT = ENT

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

  -- Create simple rectangular vertex entities for now
  -- This could be made more complex based on part type configuration
  local vertexPositions = {
    pos + Vector(-w, -l, 0), -- Bottom left
    pos + Vector(w, -l, 0),  -- Bottom right
    pos + Vector(w, l, 0),   -- Top right
    pos + Vector(-w, l, 0),  -- Top left
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

  -- Create border height controls on each side
  local borderPositions = {
    { name = "left",  pos = pos + Vector(-w - self.BORDER_WIDTH, 0, bh / 2) },
    { name = "right", pos = pos + Vector(w + self.BORDER_WIDTH, 0, bh / 2) },
    { name = "front", pos = pos + Vector(0, -l - self.BORDER_WIDTH, bh / 2) },
    { name = "back",  pos = pos + Vector(0, l + self.BORDER_WIDTH, bh / 2) }
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

function ENT:OnVertexMoved(partID, vertexIndex, vertexType, newPos)
  local part = self:GetPartByID(partID)
  if not part then return end

  if vertexType == "border" then
    -- Handle border height changes
    local newHeight = math.max(8, math.min(64, newPos.z - part.position.z))
    if math.abs(part.borderHeight - newHeight) > 1 then
      part.borderHeight = newHeight
      self:UpdatePartMesh(partID)
    end
  else
    -- Handle track vertex changes
    self:UpdatePartMesh(partID)
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

  -- Generate floor boxes from part type configuration
  local config = self:GetPartTypeConfig(part.type)
  if config and config.boxes then
    for i, boxConfig in ipairs(config.boxes) do
      local boxMeshData = {
        vertices = {},
        materialKey = self:GetMaterialKeyForBox(boxConfig),
        boxType = boxConfig.type
      }

      -- Use CreateBoxMesh to generate vertices
      local adjustedMin = part.position + boxConfig.min
      local adjustedMax = part.position + boxConfig.max

      self:CreateBoxMesh(boxMeshData.vertices, adjustedMin, adjustedMax)

      table.insert(meshData.boxes, boxMeshData)
    end
  end

  -- Generate border boxes
  self:GenerateBorderMeshData(part, meshData)

  return meshData
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
  table.insert(self.trackParts, newPart)

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
