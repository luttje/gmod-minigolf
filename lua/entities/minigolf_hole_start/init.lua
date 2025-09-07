AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

util.AddNetworkString("Minigolf.HoleConfigStart")
util.AddNetworkString("Minigolf.HoleConfigStartSave")

resource.AddFile("materials/entities/minigolf_hole_start.png")

function ENT:SpawnFunction(player, trace, className)
	if (not trace.Hit) then return end

	local entity = ents.Create(className)
	entity:SetPos(trace.HitPos + (trace.HitNormal * 15))
	entity:Spawn()
	entity:SetHoleName("Custom Hole")
	entity:SetCourse("Custom Course")
	entity:SetIsCustom(true)

	return entity
end

function ENT:Initialize()
	self._MaxRetryRules = self._MaxRetryRules or {}
	self:SetModel(self.Model)
	self:SetMoveType(MOVETYPE_NONE)
	self:SetUseType(SIMPLE_USE)
	self:SetSolid(SOLID_BBOX)
	self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
	self:DrawShadow(false)
end

function ENT:SpawnBall(activator)
	local ball = ents.Create("minigolf_ball")
	ball:SetPos(self:GetPos())
	ball:Spawn()

	ball:SetStart(self)
	ball:SetPlayer(activator)
	ball:ShowForceMeter() -- start immediately

	return ball
end

function ENT:Use(activator, caller)
	local ball = self:GetBall()

	if (not IsValid(ball) and activator:IsPlayer()) then
		local activeHole = activator:GetActiveHole()

		if (not IsValid(activeHole)) then
			local canPlay = hook.Call("Minigolf.CanStartPlaying", Minigolf.GM(), activator, self)

			if (canPlay ~= false) then
				ball = self:SetBall(self:SpawnBall(activator))

				Minigolf.Holes.Start(activator, ball, self)

				ball:ShowForceMeter(true)
			end
		elseif (activeHole == self) then
			if (IsValid(ball)) then
				ball:ReturnToStart()
			else
				-- It seems the ball has glitched out and gone missing? Respawn it
				self:SetBall(self:SpawnBall(activator))
			end
		else
			Minigolf.Messages.Send(activator,
				"You can not play on this hole as you are already playing the hole '" .. activeHole:GetHoleName() .. "'!",
				nil, Minigolf.TEXT_EFFECT_DANGER)
		end
	else
		local ballPlayer = ball:GetPlayer()

		if (ballPlayer ~= activator) then
			if (IsValid(ballPlayer)) then
				Minigolf.Messages.Send(activator,
					"You can not play on this hole as '" .. ballPlayer:Nick() .. "' is already playing'!", nil,
					Minigolf.TEXT_EFFECT_DANGER)
			else
				Minigolf.Holes.End(nil, ball, ball:GetStart())
				Minigolf.Messages.Send(activator,
					"A player disconnected while playing here. Removed their ball, try again to start playing.", nil,
					Minigolf.TEXT_EFFECT_ATTENTION)
			end
		end
	end
end

function ENT:OnBallHit(ball)
end

function ENT:KeyValue(key, value)
	key = string.lower(key)

	if (key == "hole") then
		self:SetHoleName(tostring(value):Trim())
	elseif (key == "course") then
		self:SetCourse(tostring(value):Trim())
	elseif (key == "order") then
		self:SetOrder(tonumber(value))
	elseif (key == "par") then
		self:SetPar(tonumber(value))
	elseif (key == "limit") then
		self:SetLimit(tonumber(value))
	elseif (key == "description") then
		self:SetDescription(tostring(value):Trim())
	elseif (key == "maxstrokes") then
		self:SetMaxStrokes(tonumber(value))
	elseif (key == "maxpitch") then
		self:SetMaxPitch(tonumber(value))
	elseif (key == "maxretriesaftercompleting") then
		self:SetMaxRetries(Minigolf.RETRY_RULE_AFTER_COMPLETING, tonumber(value))
	elseif (key == "maxretriesaftertimelimit") then
		self:SetMaxRetries(Minigolf.RETRY_RULE_AFTER_TIME_LIMIT, tonumber(value))
	elseif (key == "maxretriesaftermaxstrokes") then
		self:SetMaxRetries(Minigolf.RETRY_RULE_AFTER_MAX_STROKES, tonumber(value))
	end
end

function ENT:SetBall(ball)
	self._Ball = ball

	return ball
end

function ENT:GetBall()
	return self._Ball
end

function ENT:GetPlayer()
	if (not IsValid(self._Ball)) then
		return
	end

	return self._Ball:GetPlayer()
end

function ENT:SetMaxStrokes(maxStrokes)
	self._MaxStrokes = maxStrokes
	self:SetNWInt("MaxStrokes", maxStrokes)
end

function ENT:GetMaxStrokes()
	return self._MaxStrokes or 12
end

function ENT:SetMaxPitch(maxPitch)
	self._MaxPitch = maxPitch
	self:SetNWInt("MaxPitch", maxPitch)
end

function ENT:GetMaxPitch()
	return self._MaxPitch or 0
end

function ENT:SetHoleName(holeName)
	self._HoleName = holeName
	self:SetNWString("HoleName", holeName)
end

function ENT:GetHoleName()
	return self._HoleName
end

function ENT:GetUniqueHoleName()
	return string.format("%s%s", self:GetCourse(), self:GetHoleName())
end

function ENT:SetCourse(courseName)
	self._HoleCourse = courseName
	self:SetNWString("HoleCourse", courseName)
end

function ENT:GetCourse()
	return self._HoleCourse or ""
end

--- Set the order in the scoreboard
function ENT:SetOrder(order)
	self._HoleOrder = order
	self:SetNWInt("HoleOrder", order)
end

function ENT:GetOrder()
	return self._HoleOrder
end

function ENT:SetPar(par)
	self._HolePar = par
	self:SetNWInt("HolePar", par)
end

function ENT:GetPar()
	return self._HolePar or 3
end

function ENT:SetLimit(limitInSeconds)
	self._HoleLimit = limitInSeconds
	self:SetNWInt("HoleLimit", limitInSeconds)
end

function ENT:GetLimit()
	return self._HoleLimit or 60
end

function ENT:SetDescription(description)
	self._HoleDescription = description
	self:SetNWString("HoleDescription", description)
end

function ENT:GetDescription()
	return self._HoleDescription
end

function ENT:SetMaxRetries(rule, maxRetries)
	self._MaxRetryRules = self._MaxRetryRules or {}
	self._MaxRetryRules[rule] = maxRetries
end

function ENT:GetMaxRetries(rule)
	if (self._MaxRetryRules[rule] ~= nil) then
		return self._MaxRetryRules[rule]
	end

	local globalConfig = ents.FindByClass("minigolf_config")[1]

	if (not IsValid(globalConfig)) then
		return
	end

	return globalConfig:GetDefaultMaxRetries(rule)
end

function ENT:UpdateTransmitState()
	return TRANSMIT_ALWAYS
end

function ENT:OnRemove()
	local players = Minigolf.Player.GetActiveOnHole(self)

	for _, player in ipairs(players) do
		Minigolf.Holes.ForceEnd(player)
	end
end

--[[
	Net Messages
--]]

net.Receive("Minigolf.HoleConfigStartSave", function(length, player)
	local entity = net.ReadEntity()

	if (not IsValid(entity) or entity:GetClass() ~= "minigolf_hole_start") then return end
	if (not properties.CanBeTargeted(entity, player)) then return end
	if (not player:IsAdmin()) then return end

	-- Read the new values
	local holeName = net.ReadString()
	local course = net.ReadString()
	local order = net.ReadInt(16)
	local par = net.ReadInt(8)
	local limit = net.ReadInt(16)
	local description = net.ReadString()
	local maxStrokes = net.ReadInt(8)
	local maxPitch = net.ReadInt(8)
	local maxRetriesCompleting = net.ReadInt(8)
	local maxRetriesTimeLimit = net.ReadInt(8)
	local maxRetriesMaxStrokes = net.ReadInt(8)

	-- Validate and apply the values
	if (holeName and holeName ~= "") then
		entity:SetHoleName(holeName)
	end

	if (course) then
		entity:SetCourse(course)
	end

	if (order and order > 0) then
		entity:SetOrder(order)
	end

	if (par and par > 0 and par <= 10) then
		entity:SetPar(par)
	end

	if (limit and limit > 0) then
		entity:SetLimit(limit)
	end

	if (description) then
		entity:SetDescription(description)
	end

	if (maxStrokes and maxStrokes > 0 and maxStrokes <= 50) then
		entity:SetMaxStrokes(maxStrokes)
	end

	if (maxPitch and maxPitch >= 0 and maxPitch <= 90) then
		entity:SetMaxPitch(maxPitch)
	end

	-- Set retry rules (allow -1 for infinite)
	if (maxRetriesCompleting and maxRetriesCompleting >= -1) then
		entity:SetMaxRetries(Minigolf.RETRY_RULE_AFTER_COMPLETING, maxRetriesCompleting)
	end

	if (maxRetriesTimeLimit and maxRetriesTimeLimit >= -1) then
		entity:SetMaxRetries(Minigolf.RETRY_RULE_AFTER_TIME_LIMIT, maxRetriesTimeLimit)
	end

	if (maxRetriesMaxStrokes and maxRetriesMaxStrokes >= -1) then
		entity:SetMaxRetries(Minigolf.RETRY_RULE_AFTER_MAX_STROKES, maxRetriesMaxStrokes)
	end

	player:ChatPrint("Minigolf hole '" .. (entity:GetHoleName() or "Unknown") .. "' has been configured.")
end)
