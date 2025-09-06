AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

local ENT = ENT

function ENT:Initialize()
  self:SetModel("models/props_junk/watermelon01.mdl")
  self:PhysicsInit(SOLID_VPHYSICS)
  self:SetMoveType(MOVETYPE_NONE)
  self:SetSolid(SOLID_VPHYSICS)

  -- Slightly bigger for easier grabbing
  self:SetModelScale(2, 0)
  self:Activate()

  self:SetColor(Color(255, 100, 100, 200))
  self:SetRenderMode(RENDERMODE_TRANSALPHA)

  -- Initialize properties
  self.isTrackVertex = true
  self.parentDesigner = nil
  self.partID = 0
  self.vertexIndex = 0
  self.vertexType = "track" -- "track" or "border"
  self.borderSide = ""
  self.lastKnownPos = self:GetPos()
end

function ENT:SetVertexData(parentDesigner, partID, vertexIndex, vertexType, borderSide)
  self.parentDesigner = parentDesigner
  self.partID = partID
  self.vertexIndex = vertexIndex
  self.vertexType = vertexType or "track"
  self.borderSide = borderSide or ""

  -- Set appearance based on type
  if vertexType == "border" then
    self:SetModel("models/props_junk/PopCan01a.mdl")
    self:SetModelScale(0.5, 0)
    self:SetColor(Color(139, 69, 19, 200)) -- Brown
  end
end

function ENT:Think()
  local currentPos = self:GetPos()

  if self.lastKnownPos:Distance(currentPos) > 1 then
    self.lastKnownPos = currentPos

    -- Notify parent designer of position change
    if IsValid(self.parentDesigner) then
      self.parentDesigner:OnVertexMoved(self.partID, self.vertexIndex, self.vertexType, currentPos)
    end
  end

  self:NextThink(CurTime() + 0.1)
  return true
end

function ENT:OnRemove()
  -- Notify parent designer
  if IsValid(self.parentDesigner) then
    self.parentDesigner:OnVertexRemoved(self.partID, self.vertexIndex, self.vertexType)
  end
end
