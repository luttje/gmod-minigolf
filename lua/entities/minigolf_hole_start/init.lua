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

	--- Will contain all balls mapped by player SteamID
	--- This is so on disconnect (when we only have the SteamID) we can find the ball to remove.
	self._Balls = {}
end

--- Spawn a ball for the player at this start position
--- @param activator Player
--- @param canCollide? boolean
function ENT:SpawnBall(activator, canCollide)
	local ball = ents.Create("minigolf_ball")
	ball:SetPos(self:GetPos())
	ball:Spawn()

	ball:SetStart(self)
	ball:SetPlayer(activator)
	ball:ShowForceMeter() -- start immediately

	if (canCollide) then
		ball:SetNWBool("MinigolfBallsCollide", true)
	end

	ball:CallOnRemove("MinigolfBallRemoved", function()
		if (IsValid(activator)) then
			local networkID = activator:SteamID()
			self._Balls[networkID] = nil
		else
			-- If the player is not valid, we need to search for the ball by entity
			for networkID, existingBall in pairs(self._Balls) do
				if (existingBall == ball) then
					self._Balls[networkID] = nil
					break
				end
			end
		end
	end)

	return ball
end

function ENT:Use(player, caller)
	if (not IsValid(player) or not player:IsPlayer()) then
		return
	end

	if (player:InVehicle() or not player:Alive()) then
		Minigolf.Messages.Send(
			player,
			"You can not play on this hole while dead or in a vehicle!",
			nil,
			Minigolf.TEXT_EFFECT_DANGER
		)

		return
	end

	local holeMode = Minigolf.Convars.HoleMode:GetString()

	-- If the interacting player is already playing a hole, handle that first
	if (not self:CanPlayActiveHoleCheck(player)) then
		return
	end

	if (holeMode == "turn_based") then
		self:TryStartTurnBased(player)
		return
	elseif (holeMode == "simultaneous") then
		self:TryStartSimultaneous(player, false)
		return
	elseif (holeMode == "simultaneous_collide") then
		self:TryStartSimultaneous(player, true)
		return
	elseif (holeMode == "furthest_to_nearest") then
		self:TryStartFurthestToNearest(player, false)
		return
	elseif (holeMode == "furthest_to_nearest_collide") then
		self:TryStartFurthestToNearest(player, true)
		return
	end
end

--- Check if there are any balls near the start position
--- @return boolean # true if there are balls near the start position, false if there aren't
function ENT:CheckForBallsNearStart()
	local balls = self:GetBalls()

	for _, ball in pairs(balls) do
		if (IsValid(ball) and ball:GetPos():Distance(self:GetPos()) < 20) then
			return true
		end
	end

	return false
end

--- If the player has an active hole, they can't play this one, unless it's this one
--- @param player Player
--- @return boolean # true if the player can play this hole, false if they can't
function ENT:CanPlayActiveHoleCheck(player)
	local activeHole = player:GetActiveHole()

	if (IsValid(activeHole)) then
		if (activeHole ~= self) then
			Minigolf.Messages.Send(
				player,
				"You can not play on this hole as you are already playing the hole '" ..
				activeHole:GetHoleName() .. "'!",
				nil,
				Minigolf.TEXT_EFFECT_DANGER
			)

			return false
		end

		local ball = player:GetMinigolfBall()

		if (IsValid(ball)) then
			ball:ReturnToStart()
		else
			-- It seems the ball has glitched out and gone missing? Respawn it
			self:AddOrReplaceBall(self:SpawnBall(player), player)
		end

		return false
	end

	return true
end

--- If hooks allow it, spawn the ball for the player
--- @param player Player
--- @param canCollide boolean
function ENT:TryStart(player, canCollide)
	-- If the player is new to this hole, let them play if hooks allow it
	local canPlay = hook.Call("Minigolf.CanStartPlaying", Minigolf.GM(), player, self)

	if (canPlay == false) then
		return false
	end

	local ball = self:AddOrReplaceBall(self:SpawnBall(player, canCollide), player)

	Minigolf.Holes.Start(player, ball, self)

	ball:ShowForceMeter(true)
end

--- Players take turns playing the hole, finishing the hole before the next player can play.
--- @param player Player
--- @return boolean # true if the player can play this hole, false if they can't
function ENT:TryStartTurnBased(player)
	-- Check if there is already a player playing this hole
	local activePlayers = self:GetPlayers()

	if (#activePlayers > 0 and not table.HasValue(activePlayers, player)) then
		local ballPlayer = activePlayers[1]

		Minigolf.Messages.Send(
			player,
			"You can not play on this hole as '" ..
			ballPlayer:Nick() .. "' is already playing here! Wait for them to finish.",
			nil,
			Minigolf.TEXT_EFFECT_DANGER
		)

		return false
	end

	self:TryStart(player, false)

	return true
end

--- All players can play the hole at the same time.
--- @param player Player
--- @param canCollide boolean # Whether the balls can collide with each other
--- @return boolean # true if the player can play this hole, false if they can't
function ENT:TryStartSimultaneous(player, canCollide)
	-- If the balls can collide, make sure all players on this hole have a ball not near the start
	-- Otherwise spawning the ball will cause immediate collisions
	if (canCollide and self:CheckForBallsNearStart()) then
		Minigolf.Messages.Send(
			player,
			"You can not play on this hole as there are other balls near the start! Wait for them to move away.",
			nil,
			Minigolf.TEXT_EFFECT_DANGER
		)

		return false
	end

	self:TryStart(player, canCollide)

	return true
end

--- Players take turns, after which the player furthest from the hole plays next.
--- @param player Player
--- @param canCollide boolean # Whether the balls can collide with each other
--- @return boolean # true if the player can play this hole, false if they can't
function ENT:TryStartFurthestToNearest(player, canCollide)
	-- Same logic as simultaneous, except all balls have to be stationary when we start
	if (canCollide and self:CheckForBallsNearStart()) then
		Minigolf.Messages.Send(
			player,
			"You can not play on this hole as there are other balls near the start! Wait for them to move away.",
			nil,
			Minigolf.TEXT_EFFECT_DANGER
		)

		return false
	end

	local balls = self:GetBalls()

	for _, ball in pairs(balls) do
		if (not IsValid(ball)) then
			continue
		end

		if (not ball:GetStationary()) then
			Minigolf.Messages.Send(
				player,
				"You can not play on this hole as '" ..
				ball:GetPlayer():Nick() .. "' their ball is still moving! Wait for it to stop.",
				nil,
				Minigolf.TEXT_EFFECT_DANGER
			)

			return false
		end

		-- If the player is currently giving force, don't let a new player start
		local ballPlayer = ball:GetPlayer()

		if (IsValid(ballPlayer) and IsValid(ballPlayer:GetBallGivingForce())) then
			Minigolf.Messages.Send(
				player,
				"You can not play on this hole as '" ..
				ballPlayer:Nick() ..
				"' is currently hitting their ball! Wait for them to finish or step away from their ball.",
				nil,
				Minigolf.TEXT_EFFECT_DANGER
			)

			return false
		end
	end

	self:TryStart(player, canCollide)

	return true
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

function ENT:AddOrReplaceBall(ball, player)
	for networkID, existingBall in pairs(self._Balls) do
		if (IsValid(existingBall) and existingBall:GetPlayer() == player) then
			self._Balls[networkID] = ball

			return ball
		end
	end

	-- If we didn't find an existing ball for the player, just add it
	local networkID = player:SteamID()
	self._Balls[networkID] = ball

	return ball
end

function ENT:GetBalls()
	return self._Balls
end

function ENT:GetBallByNetworkID(networkID)
	for id, ball in pairs(self._Balls) do
		if (IsValid(ball) and id == networkID) then
			return ball
		end
	end

	return nil
end

function ENT:GetPlayers()
	local players = {}

	for networkID, ball in pairs(self._Balls) do
		local player = ball:GetPlayer()

		if (IsValid(player)) then
			table.insert(players, player)
		end
	end

	return players
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

--- Find all hole ends that point to this start
--- @return Entity[] # List of hole end entities that point to this start
function ENT:GetEnds()
	local ends = {}

	local possibleEnds = {}
	table.Add(possibleEnds, ents.FindByClass("minigolf_hole_end"))
	table.Add(possibleEnds, ents.FindByClass("minigolf_hole_end_dynamic"))

	for _, otherEntity in pairs(possibleEnds) do
		if (otherEntity:GetStart() == self) then
			table.insert(ends, otherEntity)
		end
	end

	return ends
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
