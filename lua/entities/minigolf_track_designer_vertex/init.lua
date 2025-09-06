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

  -- Constrain movement based on vertex type
  local constrainedPos = self:ConstrainMovement(currentPos)

  -- If position needed to be constrained, update it
  if constrainedPos ~= currentPos then
    self:SetPos(constrainedPos)
    currentPos = constrainedPos
  end

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

function ENT:ConstrainMovement(newPos)
  if not IsValid(self.parentDesigner) then
    return newPos
  end

  -- Get the part this vertex belongs to
  local part = self.parentDesigner:GetPartByID(self.partID)
  if not part then
    return newPos
  end

  local constrainedPos = Vector(newPos.x, newPos.y, newPos.z)

  if self.vertexType == "border" then
    -- Border vertices can only move up/down (Z axis)
    -- Keep them fixed to their border position
    local pos = part.position
    local w = self.parentDesigner.TRACK_WIDTH / 2
    local l = self.parentDesigner.TRACK_LENGTH / 2
    local bw = self.parentDesigner.BORDER_WIDTH

    if self.borderSide == "left" then
      constrainedPos.x = pos.x - w - bw
      constrainedPos.y = pos.y
    elseif self.borderSide == "right" then
      constrainedPos.x = pos.x + w + bw
      constrainedPos.y = pos.y
    elseif self.borderSide == "front" then
      constrainedPos.x = pos.x
      constrainedPos.y = pos.y - l - bw
    elseif self.borderSide == "back" then
      constrainedPos.x = pos.x
      constrainedPos.y = pos.y + l + bw
    end
  elseif self.vertexType == "track" then
    -- Track vertices can move along their edge and up/down
    local pos = part.position
    local w = self.parentDesigner.TRACK_WIDTH / 2
    local l = self.parentDesigner.TRACK_LENGTH / 2

    -- Determine which edge this vertex is on and constrain accordingly
    if self.vertexIndex == 1 then -- Bottom left (front-left)
      constrainedPos.x = pos.x - w
      constrainedPos.y = pos.y - l
    elseif self.vertexIndex == 2 then -- Bottom right (front-right)
      constrainedPos.x = pos.x + w
      constrainedPos.y = pos.y - l
    elseif self.vertexIndex == 3 then -- Top right (back-right)
      constrainedPos.x = pos.x + w
      constrainedPos.y = pos.y + l
    elseif self.vertexIndex == 4 then -- Top left (back-left)
      constrainedPos.x = pos.x - w
      constrainedPos.y = pos.y + l
    end
  end

  return constrainedPos
end

function ENT:OnRemove()
  -- Notify parent designer
  if IsValid(self.parentDesigner) then
    self.parentDesigner:OnVertexRemoved(self.partID, self.vertexIndex, self.vertexType)
  end
end
