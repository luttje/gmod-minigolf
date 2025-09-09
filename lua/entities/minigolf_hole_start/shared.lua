DEFINE_BASECLASS("base_anim")

ENT.Type = "anim"
ENT.Base = "base_anim"

ENT.PrintName = "Minigolf Start"
ENT.Author = "Luttje"
ENT.Information = "The start of a hole"
ENT.Category = "Minigolf"

ENT.Spawnable = true
ENT.AdminOnly = true

ENT.Model = Model("models/xqm/rails/gumball_1.mdl")

function ENT:SetupDataTables()
	self:NetworkVar("Bool", "IsCustom")
end

function ENT:CanProperty(player, property)
	if (property == "remover" or property == "minigolf_configure_start") then
		return player:IsAdmin()
	end

	return false
end

properties.Add("minigolf_configure_start", {
	MenuLabel = "Configure Minigolf Hole Start",
	Order = 500,
	MenuIcon = "icon16/sport_golf.png",

	Filter = function(self, entity, player)
		if (not IsValid(entity)) then return false end
		if (entity:GetClass() ~= "minigolf_hole_start") then return false end
		if (not gamemode.Call("CanProperty", player, "minigolf_configure_start", entity)) then return false end

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

		net.Start("Minigolf.HoleConfigStart")
		net.WriteEntity(entity)
		net.WriteInt(entity:GetMaxRetries(Minigolf.RETRY_RULE_AFTER_COMPLETING) or 0, 8)
		net.WriteInt(entity:GetMaxRetries(Minigolf.RETRY_RULE_AFTER_TIME_LIMIT) or 0, 8)
		net.WriteInt(entity:GetMaxRetries(Minigolf.RETRY_RULE_AFTER_MAX_STROKES) or 0, 8)
		net.Send(player)
	end
})
