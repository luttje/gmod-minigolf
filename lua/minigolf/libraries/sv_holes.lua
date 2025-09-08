util.AddNetworkString("Minigolf.SetPlayerTimeLimit")
util.AddNetworkString("Minigolf.PlayerHasFinished")

Minigolf.Holes = Minigolf.Holes or {}
Minigolf.Holes.NetworkIDCache = Minigolf.Holes.NetworkIDCache or {}
Minigolf.Holes.Cache = Minigolf.Holes.Cache or {}

function Minigolf.Holes.GetByName(findHoleName)
	if (Minigolf.Holes.Cache[findHoleName]) then
		return Minigolf.Holes.Cache[findHoleName]
	end

	for _, hole in pairs(ents.FindByClass("minigolf_hole_start")) do
		local holeName = hole:GetUniqueHoleName()

		Minigolf.Holes.Cache[holeName] = hole

		if (holeName == findHoleName) then
			return hole
		end
	end

	return nil
end

function Minigolf.Holes.GetStartByNetworkID(networkID)
	local hole = Minigolf.Holes.NetworkIDCache[networkID]

	return hole, IsValid(hole) and hole:GetBallByNetworkID(networkID) or nil
end

function Minigolf.Holes.ResetForPlayer(player)
	player:ResetHoleScores()

	for _, hole in pairs(ents.FindByClass("minigolf_hole_start")) do
		player:SetHoleScore(hole, Minigolf.HOLE_NOT_PLAYED)
	end
end

function Minigolf.Holes.Start(player, ball, start)
	local holeName = start:GetUniqueHoleName()
	local timeLimit = start:GetLimit()
		* (Minigolf.Convars.TimeLimitMultiplierGlobal:GetFloat() or 1)
		* (player._MinigolfTimeMultiplier or 1)

	if (not player:HasWeapon("minigolf_club")) then
		player:Give("minigolf_club")
	end

	player:SelectWeapon("minigolf_club")

	player:SetActiveHole(start)

	net.Start("Minigolf.SetPlayerTimeLimit")
	net.WriteEntity(player)
	net.WriteUInt(math.min(timeLimit, 4294967295), 32)
	net.Broadcast()

	Minigolf.Holes.NetworkIDCache[player:SteamID()] = start
	hook.Call("Minigolf.PlayerStarted", Minigolf.GM(), player, start, ball)

	Minigolf.Holes.CreateTimeLimit(timeLimit, player, ball, start)
end

function Minigolf.Holes.CreateTimeLimit(timeLimit, player, ball, start)
	local ball = player:GetMinigolfBall()

	timer.Create((player:AccountID() or player:UserID()) .. start:GetUniqueHoleName() .. "TimeLimit", timeLimit, 1,
		function()
			if (IsValid(player) and IsValid(ball) and ball:GetStart() == start) then
				hook.Call("Minigolf.TimeLimitReached", Minigolf.GM(), player, ball, start)

				Minigolf.Holes.End(player, ball, start)
			end
		end)
end

function Minigolf.Holes.End(player, ball, start, goal)
	local strokes = ball:GetStrokes()
	local customMessage = false

	-- The player may have disconnected, so be sure they're still here
	if (IsValid(player)) then
		-- Goal can be nil when we end because of a time limit
		if (goal) then
			customMessage = hook.Call("Minigolf.GetGoalMessage", Minigolf.GM(), player, goal, strokes, start)
		end

		player:SetHoleScore(start, goal ~= nil and strokes or Minigolf.HOLE_DISQUALIFIED)

		local currentRetries = player:GetAllowedRetries(start)
		local retries

		if (currentRetries == nil) then
			retries = start:GetMaxRetries(
				(strokes >= start:GetMaxStrokes() and Minigolf.RETRY_RULE_AFTER_MAX_STROKES)
				or (goal == nil and Minigolf.RETRY_RULE_AFTER_TIME_LIMIT)
				or Minigolf.RETRY_RULE_AFTER_COMPLETING
			)
		elseif (currentRetries > 0) then
			retries = currentRetries - 1
		end

		player:SetAllowedRetries(start, retries)

		player:SetPlayerBall(nil)
		player:SetActiveHole(nil)
		Minigolf.Holes.NetworkIDCache[player:SteamID()] = nil

		if (customMessage ~= false) then
			Minigolf.Messages.Send(player,
				player:Nick() ..
				" made it to the hole '" ..
				start:GetHoleName() .. "' with " .. strokes .. " " .. Minigolf.Text.Pluralize("stroke", strokes), "Ã")
		end
	else
		print("A player disconnected at hole '" .. start:GetHoleName() .. "!")
	end

	if (IsValid(start)) then
		start:OnBallHit(ball)
	end

	net.Start("Minigolf.PlayerHasFinished")
	net.WriteEntity(player)
	net.WriteEntity(start)
	net.WriteUInt(strokes, 32)
	net.Broadcast()

	hook.Call("Minigolf.PlayerFinishedHole", Minigolf.GM(), player, ball, start, strokes)

	if (IsValid(ball)) then
		ball._MinigolfRemoving = true
		ball:Remove()
	end
end

--- Force the player to leave the hole. Useful if the ball or start aren't valid anymore
function Minigolf.Holes.ForceEnd(player)
	local ball = player:GetMinigolfBall()
	local start = player:GetActiveHole()

	if (IsValid(ball) and IsValid(start)) then
		Minigolf.Holes.End(player, ball, start)
	else
		if (IsValid(start)) then
			player:SetHoleScore(start, Minigolf.HOLE_DISQUALIFIED)
		end

		if (IsValid(ball)) then
			ball:Remove()
		end

		player:SetPlayerBall(nil)
		player:SetActiveHole(nil)
		Minigolf.Holes.NetworkIDCache[player:SteamID()] = nil
	end
end

concommand.Add("minigolf_time_limit_multiplier", function(player, command, args)
	if (not IsValid(player) or not player:IsAdmin()) then
		return
	end

	local multiplier = tonumber(args[1])

	if (not multiplier or multiplier <= 0) then
		player:ChatPrint("Usage: minigolf_time_limit_multiplier <multiplier> [player]")
		return
	end

	local targetPlayer = player

	if (args[2]) then
		local foundPlayer = Minigolf.Player.FindByName(args[2])

		if (not foundPlayer) then
			player:ChatPrint("Player not found!")
			return
		end

		targetPlayer = foundPlayer
	end

	targetPlayer._MinigolfTimeMultiplier = multiplier
end)
