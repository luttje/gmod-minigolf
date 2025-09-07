AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
	self._MaxRetryRules = self._MaxRetryRules or {}
	self:SetMoveType(MOVETYPE_NONE)
	self:SetSolid(SOLID_BBOX)
	self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
	self:SetNoDraw(true)
end

function ENT:KeyValue(key, value)
	key = string.lower(key)

	if (key == "defaultmaxretriesaftercompleting") then
		self:SetDefaultMaxRetries(Minigolf.RETRY_RULE_AFTER_COMPLETING, tonumber(value))
	elseif (key == "defaultmaxretriesaftertimelimit") then
		self:SetDefaultMaxRetries(Minigolf.RETRY_RULE_AFTER_TIME_LIMIT, tonumber(value))
	elseif (key == "defaultmaxretriesaftermaxstrokes") then
		self:SetDefaultMaxRetries(Minigolf.RETRY_RULE_AFTER_MAX_STROKES, tonumber(value))
	end
end

function ENT:SetDefaultMaxRetries(rule, maxRetries)
	self._MaxRetryRules = self._MaxRetryRules or {}
	self._MaxRetryRules[rule] = maxRetries
end

function ENT:GetDefaultMaxRetries(rule)
	return self._MaxRetryRules[rule] or 0
end

function ENT:UpdateTransmitState()
	return TRANSMIT_ALWAYS
end
