include("shared.lua")

local ENT = ENT

ENT.Icon = "entities/minigolf_track_designer.png"

function ENT:Initialize()
  -- Client-side initialization
  self.meshParts = {}
  self.materials = {}
  self.renderBounds = { min = Vector(0, 0, 0), max = Vector(0, 0, 0) }

  -- Initialize materials for all registered part types
  for partTypeId, config in pairs(self.PART_TYPES) do
    self.materials[partTypeId] = type(config.material) == "string" and Material(config.material) or config.material
  end

  -- Border material is unlit generic to avoid lighting issues (cant receive flashlight + we have a bug causing black triangles)
  self.materials.border = self.MATERIALS.WOOD_BORDER

  -- Set initial render bounds to prevent culling
  self:SetRenderBounds(Vector(-1000, -1000, -1000), Vector(1000, 1000, 1000))
end

function ENT:Draw()
  self:DrawModel()

  -- Draw all mesh parts
  for partID, meshPart in pairs(self.meshParts) do
    self:DrawMeshPart(meshPart)
  end
end

function ENT:DrawMeshPart(meshPart)
  if not meshPart.meshes or #meshPart.meshes == 0 then return end

  -- Draw all meshes in this part
  for _, meshInfo in ipairs(meshPart.meshes) do
    if meshInfo.mesh then
      local material = self.materials[meshInfo.materialKey] or self.materials.border
      render.SetMaterial(material)
      meshInfo.mesh:Draw()
    end
  end
end

function ENT:CreateMeshFromData(partID, meshData)
  local meshPart = {
    partID = partID,
    partType = meshData.partType,
    meshes = {},
    localTris = {}
  }

  if meshData.boxes then
    for i, boxData in ipairs(meshData.boxes) do
      if boxData.vertices and #boxData.vertices > 0 and #boxData.vertices % 3 == 0 then
        local material = self.materials[boxData.materialKey] or self.materials.border
        local mesh = Mesh(material)

        local validVertices = {}
        for j, vertex in ipairs(boxData.vertices) do
          if vertex.pos and vertex.normal and vertex.u and vertex.v then
            validVertices[#validVertices + 1] = {
              pos = vertex.pos,
              normal = vertex.normal,
              u = vertex.u,
              v = vertex.v
            }
          end
        end

        if #validVertices > 0 and #validVertices % 3 == 0 then
          mesh:BuildFromTriangles(validVertices)

          -- collect local-space triangles for PhysicsFromMesh
          for k = 1, #validVertices, 3 do
            local p1 = self:WorldToLocal(validVertices[k].pos)
            local p2 = self:WorldToLocal(validVertices[k + 1].pos)
            local p3 = self:WorldToLocal(validVertices[k + 2].pos)
            meshPart.localTris[#meshPart.localTris + 1] = { pos = p1 }
            meshPart.localTris[#meshPart.localTris + 1] = { pos = p2 }
            meshPart.localTris[#meshPart.localTris + 1] = { pos = p3 }
          end

          table.insert(meshPart.meshes, {
            mesh = mesh,
            materialKey = boxData.materialKey,
            boxType = boxData.boxType
          })
        end
      end
    end
  end

  self.meshParts[partID] = meshPart

  self:UpdateRenderBounds()
  self:BuildPhysicsFromCurrentParts()
end

function ENT:BuildPhysicsFromCurrentParts()
  if not self.meshParts then return end

  local tris = {}
  for _, mp in pairs(self.meshParts) do
    if mp.localTris and #mp.localTris > 0 then
      for i = 1, #mp.localTris do
        tris[#tris + 1] = { pos = mp.localTris[i].pos }
      end
    end
  end

  if #tris == 0 then return end

  self:PhysicsFromMesh(tris)
  self:EnableCustomCollisions()
end

function ENT:UpdateMeshPart(partID, meshData)
  -- Remove old meshes
  if self.meshParts[partID] then
    for _, meshInfo in ipairs(self.meshParts[partID].meshes) do
      if meshInfo.mesh then
        meshInfo.mesh:Destroy()
      end
    end
  end

  self:CreateMeshFromData(partID, meshData)
end

function ENT:UpdateRenderBounds()
  -- Calculate bounds based on all mesh parts
  local minBounds = Vector(math.huge, math.huge, math.huge)
  local maxBounds = Vector(-math.huge, -math.huge, -math.huge)
  local hasBounds = false

  -- Go through all mesh parts and find the overall bounds
  for partID, meshPart in pairs(self.meshParts) do
    if meshPart.bounds then
      hasBounds = true
      minBounds.x = math.min(minBounds.x, meshPart.bounds.min.x)
      minBounds.y = math.min(minBounds.y, meshPart.bounds.min.y)
      minBounds.z = math.min(minBounds.z, meshPart.bounds.min.z)

      maxBounds.x = math.max(maxBounds.x, meshPart.bounds.max.x)
      maxBounds.y = math.max(maxBounds.y, meshPart.bounds.max.y)
      maxBounds.z = math.max(maxBounds.z, meshPart.bounds.max.z)
    end
  end

  -- If we have bounds, apply them with some padding
  if hasBounds then
    local padding = 100 -- Add some padding to ensure nothing gets culled
    minBounds = minBounds - Vector(padding, padding, padding)
    maxBounds = maxBounds + Vector(padding, padding, padding)

    self:SetRenderBounds(minBounds, maxBounds)
    self.renderBounds.min = minBounds
    self.renderBounds.max = maxBounds
  else
    -- Fallback to large bounds if we can't calculate proper ones
    self:SetRenderBounds(Vector(-1000, -1000, -1000), Vector(1000, 1000, 1000))
  end
end

function ENT:OnRemove()
  -- Clean up all meshes
  for partID, meshPart in pairs(self.meshParts) do
    for _, meshInfo in ipairs(meshPart.meshes) do
      if meshInfo.mesh then
        meshInfo.mesh:Destroy()
      end
    end
  end
  self.meshParts = {}
end

-- Menu system
net.Receive("MinigolfDesigner_OpenMenu", function()
  local designerEnt = net.ReadEntity()

  if not IsValid(designerEnt) then return end

  local frame = vgui.Create("DFrame")
  frame:SetSize(500, 400)
  frame:Center()
  frame:SetTitle("Minigolf Track Designer")
  frame:MakePopup()

  -- Instructions
  local instructions = vgui.Create("DLabel", frame)
  instructions:SetText(
    "Instructions:\n• Enable Edit Mode to see vertex handles\n• Use the Physgun to drag and reshape the track or change the border height\n• Add new parts to extend your course")
  instructions:SetPos(20, 70)
  instructions:SetSize(460, 80)
  instructions:SetWrap(true)

  -- Part addition buttons - dynamically create from registered types
  local y = 160
  local buttonWidth = 140
  local buttonHeight = 40
  local buttonSpacing = 150
  local x = 20

  for i, partTypeId in ipairs(designerEnt:GetPartTypeList()) do
    local config = designerEnt:GetPartTypeConfig(partTypeId)

    local addBtn = vgui.Create("DButton", frame)
    addBtn:SetText("Add " .. config.name)
    addBtn:SetPos(x, y)
    addBtn:SetSize(buttonWidth, buttonHeight)
    addBtn.DoClick = function()
      net.Start("MinigolfDesigner_AddPart")
      net.WriteEntity(designerEnt)
      net.WriteString(partTypeId)
      net.SendToServer()
    end

    x = x + buttonSpacing
    if x > 400 then -- Wrap to next row if too wide
      x = 20
      y = y + buttonHeight + 10
    end
  end
end)

-- Network message to receive mesh data from server
net.Receive("MinigolfDesigner_SyncMesh", function()
  local designerEnt = net.ReadEntity()
  local partID = net.ReadUInt(16)
  local meshData = net.ReadTable()

  if IsValid(designerEnt) and designerEnt.UpdateMeshPart then
    designerEnt:UpdateMeshPart(partID, meshData)
  end
end)
