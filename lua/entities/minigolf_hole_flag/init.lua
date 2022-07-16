AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

resource.AddFile("materials/minigolf/flag.png")
resource.AddFile("materials/minigolf/flag_done.png")

local FLAG_RAISE_DISTANCE = 128
local RAISE_FLAG_BY = 50
local DURATION = 1

function ENT:Initialize()
	if ( CLIENT ) then return end

	self:SetModel(self.Model)
	self:SetMoveType(MOVETYPE_NONE)
	self:SetUseType(SIMPLE_USE)
	self:SetSolid(SOLID_BBOX)
end

function ENT:OnHoleEndTouched(holeEnd)
	self:SetCollisionGroup(COLLISION_GROUP_WEAPON)

	-- Needs to be set next frame or the start entity can still be NULL (if the brush touches the hole end before hole start has loaded)
	Minigolf.WaitOneTick(function()
		self:SetStart(holeEnd:GetStart())
	end, self)
end

function ENT:SetStart(start)
	self._Start = start
	self:SetNWEntity("HoleStart", start)
end

function ENT:GetStart()
	return self._Start
end

function ENT:RaiseDown()
	self._MoveUntil = CurTime() + DURATION
	self._MovingFrom = self:GetPos()
	self._MovingTo = self._OldPos
	self._OldPos = nil
	self._RaisedBy = nil
end

function ENT:RaiseUp(activator)
	-- Raise self in the air
	self._OldPos = self:GetPos()
	self._MovingFrom = self._OldPos
	self._MovingTo = self._OldPos + Vector(0,0, RAISE_FLAG_BY)
	self._MoveUntil = CurTime() + DURATION
	self._RaisedBy = activator
end

--[[function ENT:Use(activator, caller)
	if(self._MoveUntil)then
		return
	end

	if(self._OldPos)then
		self:RaiseDown()
		return
	end

	self:RaiseUp(activator)
end]]

function ENT:Think()
	local start = self:GetStart()

	if(not IsValid(start))then
		return
	end

	local player = start:GetPlayer()

	if(self._MoveUntil)then
		if(self._MoveUntil - CurTime() <= 0)then
			self:SetPos(self._MovingTo)
			self._MoveUntil = nil
			self._MovingTo = nil
			self._MovingFrom = nil
			return
		end

		local fraction = 1 - ((self._MoveUntil - CurTime()) / DURATION)
		
		self:SetPos(LerpVector(fraction, self._MovingFrom, self._MovingTo))
	elseif(self._RaisedBy)then
		if(not IsValid(self._RaisedBy) or not self._RaisedBy:IsInDistanceOf(self, FLAG_RAISE_DISTANCE) or not IsValid(self._RaisedBy:GetActiveHole()))then
			self:RaiseDown()
			return
		end
	elseif(IsValid(player) and not self._MoveUntil)then
		if(player:IsInDistanceOf(self, FLAG_RAISE_DISTANCE))then
			self:RaiseUp(player)
		end
	end
end

function ENT:UpdateTransmitState()	
	return TRANSMIT_ALWAYS 
end