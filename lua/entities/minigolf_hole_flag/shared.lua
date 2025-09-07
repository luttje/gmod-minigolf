DEFINE_BASECLASS("base_anim")

ENT.PrintName = "Minigolf Hole Flag"
ENT.Author = "Luttje"
ENT.Information = "The flag for the end of a hole"
ENT.Category = "Minigolf"

ENT.Spawnable = false
ENT.AdminOnly = true

ENT.Model = Model("models/props_c17/signpole001.mdl")

function ENT:CanProperty(player, property)
	return false
end
