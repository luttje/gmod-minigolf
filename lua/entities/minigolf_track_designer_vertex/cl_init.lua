include("shared.lua")

local ENT = ENT

ENT.RenderGroup = RENDERGROUP_OTHER

function ENT:Initialize()
  self.GripMaterial = Material("sprites/grip")
  self.GripMaterialHover = Material("sprites/grip_hover")
end

function ENT:Draw()
  -- Don't draw the grip if there's no chance of us picking it up
  local ply = LocalPlayer()
  local wep = ply:GetActiveWeapon()
  if (not IsValid(wep)) then return end

  local weaponName = wep:GetClass()

  if (weaponName ~= "weapon_physgun" and weaponName ~= "gmod_tool") then
    return
  end

  if (self:BeingLookedAtByLocalPlayer()) then
    render.SetMaterial(self.GripMaterialHover)
  else
    render.SetMaterial(self.GripMaterial)
  end

  render.DrawSprite(self:GetPos(), 16, 16, color_white)
end

-- Copied from base_gmodentity.lua
ENT.MaxWorldTipDistance = 256

function ENT:BeingLookedAtByLocalPlayer()
  local ply = LocalPlayer()
  if (not IsValid(ply)) then return false end

  local view = ply:GetViewEntity()
  local dist = self.MaxWorldTipDistance
  dist = dist * dist

  -- If we're spectating a player, perform an eye trace
  if (view:IsPlayer()) then
    return view:EyePos():DistToSqr(self:GetPos()) <= dist and view:GetEyeTrace().Entity == self
  end

  -- If we're not spectating a player, perform a manual trace from the entity's position
  local pos = view:GetPos()

  if (pos:DistToSqr(self:GetPos()) <= dist) then
    return util.TraceLine({
      start = pos,
      endpos = pos + (view:GetAngles():Forward() * dist),
      filter = view
    }).Entity == self
  end

  return false
end
