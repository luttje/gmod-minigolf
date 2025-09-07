include("shared.lua")

local ENT = ENT

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

  render.SetMaterial(self.GripMaterial)

  render.DrawSprite(self:GetPos(), 16, 16, color_white)
end
