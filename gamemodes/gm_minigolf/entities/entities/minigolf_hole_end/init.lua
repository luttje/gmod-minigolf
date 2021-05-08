AddCSLuaFile("cl_init.lua");
AddCSLuaFile("shared.lua");
include("shared.lua");

function ENT:Initialize()
end

function ENT:StartTouch(entity)
	if(IsValid(entity) and entity:GetClass() == "minigolf_ball")then
		if(self:GetHoleName() == entity:GetStart():GetHoleName())then
			Minigolf.Holes.End(entity:GetPlayer(), entity, entity:GetStart(), self)
		else
			hook.Call("MinigolfBallOutOfBounds", gm(), entity:GetPlayer(), entity, self)
		end
	elseif(entity.OnHoleEndTouched)then
		entity:OnHoleEndTouched(self)
	end
end

function ENT:KeyValue(key, value)
	key = string.lower(key)
	
	if(key == "hole")then
		self:SetHoleName(tostring(value):Trim())
	elseif(key == "course")then
		self:SetCourse(tostring(value):Trim())
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
end

function ENT:GetCourse()
	return self._HoleCourse or ""
end

function ENT:GetStart()
	if(self._Start)then
		return self._Start
	end
	
	for _, otherEntity in pairs(ents.FindByClass("minigolf_hole_start")) do
		if(otherEntity:GetUniqueHoleName() == self:GetUniqueHoleName())then
			self._Start = otherEntity

			return self._Start
		end
	end
end

function ENT:UpdateTransmitState()	
	return TRANSMIT_ALWAYS 
end