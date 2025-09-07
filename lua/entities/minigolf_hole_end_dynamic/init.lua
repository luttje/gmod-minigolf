AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

util.AddNetworkString("Minigolf.HoleConfigEnd")
util.AddNetworkString("Minigolf.HoleConfigEndSave")

resource.AddFile("materials/entities/minigolf_hole_end_dynamic.png")

function ENT:SpawnFunction(player, trace, className)
	if (not trace.Hit) then return end

	local entity = ents.Create(className)
	entity:SetPos(trace.HitPos)
	entity:Spawn()

	return entity
end

function ENT:Initialize()
	self:SetModel(self.Model)

	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:DrawShadow(false)

	self:Activate()

	local phys = self:GetPhysicsObject()
	if (IsValid(phys)) then
		phys:EnableMotion(false)
		phys:Wake()
	end

	self._Flag = ents.Create("minigolf_hole_flag")
	self._Flag:SetPos(self:GetPos())
	self._Flag:SetAngles(self:GetAngles())
	self._Flag:Spawn()
	self._Flag:Activate()
	self._Flag:SetParent(self)
end

function ENT:Touch(entity)
	if (IsValid(entity) and entity:GetClass() == "minigolf_ball" and not entity._MinigolfRemoving) then
		if (self:GetStart() == entity:GetStart()) then
			Minigolf.Holes.End(entity:GetPlayer(), entity, entity:GetStart(), self)
		else
			hook.Call("Minigolf.BallOutOfBounds", Minigolf.GM(), entity:GetPlayer(), entity, self)
		end
	elseif (entity.OnHoleEndTouched) then
		entity:OnHoleEndTouched(self)
	end
end

function ENT:SetHoleName(holeName)
	self._HoleName = holeName
	self:SetNWString("HoleName", holeName)
end

function ENT:GetHoleName()
	return self._HoleName
end

function ENT:GetUniqueHoleName()
	return self:GetCourse() .. self:GetHoleName()
end

function ENT:SetCourse(courseName)
	self._HoleCourse = courseName
	self:SetNWString("CourseName", courseName)
end

function ENT:GetCourse()
	return self._HoleCourse or ""
end

function ENT:SetStartName(startName)
	self._StartName = startName
	self:SetNWString("StartName", startName)
end

function ENT:GetStart()
	return self._Start
end

function ENT:UpdateTransmitState()
	return TRANSMIT_ALWAYS
end

function ENT:OnRemove()
	if (IsValid(self._Flag)) then
		self._Flag:Remove()
	end
end

--[[
	Net Messages
--]]

net.Receive("Minigolf.HoleConfigEndSave", function(length, player)
	local entity = net.ReadEntity()

	if (not IsValid(entity) or entity:GetClass() ~= "minigolf_hole_end_dynamic") then return end
	if (not properties.CanBeTargeted(entity, player)) then return end
	if (not player:IsAdmin()) then return end

	-- Read the new values
	local course = net.ReadString()
	local startName = net.ReadString()
	local holeName = net.ReadString()

	entity:SetHoleName(holeName)
	entity:SetCourse(course)
	entity:SetStartName(startName)

	if (startName) then
		local start = ents.FindByName(startName)[1]

		if (IsValid(start)) then
			entity._Start = start
		end
	end

	if (not entity._Start) then
		for _, otherEntity in pairs(ents.FindByClass("minigolf_hole_start")) do
			if (otherEntity:GetUniqueHoleName() == entity:GetUniqueHoleName()
					-- WORKAROUND: golf_rocket_hub_alpha2 didn't correctly specify the course name on the end holes.
					or otherEntity:GetHoleName() == entity:GetHoleName()) then
				entity._Start = otherEntity
			end
		end
	end

	if (not IsValid(entity:GetStart())) then
		Minigolf.Messages.Send(player, "Minigolf hole '" .. (entity:GetHoleName() or "Unknown") ..
			"' is not linked to any start hole.", nil, Minigolf.TEXT_EFFECT_DANGER)
	else
		entity._Flag:SetStart(entity._Start)
	end

	player:ChatPrint("Minigolf hole '" .. (entity:GetHoleName() or "Unknown") .. "' has been configured.")
end)
