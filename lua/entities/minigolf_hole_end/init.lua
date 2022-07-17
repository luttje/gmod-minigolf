AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
end

function ENT:StartTouch(entity)
	if(IsValid(entity) and entity:GetClass() == "minigolf_ball")then
		if(self:GetStart() == entity:GetStart())then
			Minigolf.Holes.End(entity:GetPlayer(), entity, entity:GetStart(), self)
		else
			hook.Call("Minigolf.BallOutOfBounds", Minigolf.GM(), entity:GetPlayer(), entity, self)
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
	elseif(key == "start_hole")then
		self:SetStartName(tostring(value):Trim())
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

function ENT:SetStartName(startName)
	self._StartName = startName
end

function ENT:GetStart()
	if(self._Start)then
		return self._Start
	end

	if(self._StartName)then
		local start = ents.FindByName(self._StartName)[1]
	
		if(not IsValid(start))then
			error("Minigolf: Start hole ".. tostring(self._StartName) .." did not exist for entity ".. tostring(self) .."!")
		end

		self._Start = start
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