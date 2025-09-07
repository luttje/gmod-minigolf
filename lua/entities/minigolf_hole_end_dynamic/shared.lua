DEFINE_BASECLASS("base_anim")

ENT.PrintName = "Minigolf Goal"
ENT.Author = "Luttje"
ENT.Information = "The goal which ends a hole when the ball touches it"
ENT.Category = "Minigolf"

ENT.Spawnable = true
ENT.AdminOnly = true
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

ENT.Model = Model("models/props_phx/gears/bevel9.mdl")

function ENT:CanProperty(player, property)
	if (property == "remover" or property == "minigolf_configure_end") then
		return player:IsAdmin()
	end

	return false
end

properties.Add("minigolf_configure_end", {
	MenuLabel = "Configure Minigolf Hole End",
	Order = 500,
	MenuIcon = "icon16/sport_golf.png",

	Filter = function(self, entity, player)
		if (not IsValid(entity)) then return false end
		if (entity:GetClass() ~= "minigolf_hole_end_dynamic") then return false end
		if (not gamemode.Call("CanProperty", player, "minigolf_configure_end", entity)) then return false end

		return player:IsAdmin()
	end,

	Action = function(self, entity)
		self:MsgStart()
		net.WriteEntity(entity)
		self:MsgEnd()
	end,

	Receive = function(self, length, player)
		local entity = net.ReadEntity()

		if (not properties.CanBeTargeted(entity, player)) then return end
		if (not self:Filter(entity, player)) then return end

		net.Start("Minigolf.HoleConfigEnd")
		net.WriteEntity(entity)
		net.Send(player)
	end
})
