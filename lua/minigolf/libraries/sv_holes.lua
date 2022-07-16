util.AddNetworkString("Minigolf.SetPlayerTimeLimit")
util.AddNetworkString("Minigolf.PlayerHasFinished")

Minigolf.Holes = Minigolf.Holes or {}
Minigolf.Holes.NetworkIDCache = Minigolf.Holes.NetworkIDCache or {}
Minigolf.Holes.Cache = Minigolf.Holes.Cache or {}

function Minigolf.Holes.GetByName(findHoleName)
	if(Minigolf.Holes.Cache[findHoleName])then
		return Minigolf.Holes.Cache[findHoleName]
	end

	for _, hole in pairs(ents.FindByClass("minigolf_hole_start")) do
		local holeName = hole:GetUniqueHoleName()

		Minigolf.Holes.Cache[holeName] = hole
		
		if(holeName == findHoleName)then
			return hole
		end
	end

	return nil
end

function Minigolf.Holes.GetStartByNetworkID(networkID)
	local hole = Minigolf.Holes.NetworkIDCache[networkID]

	return hole, IsValid(hole) and hole:GetBall() or nil
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

	if(not player:HasWeapon("golf_club"))then
		player:Give("golf_club")
	end

	player:SelectWeapon("golf_club")

  player:SetActiveHole(start)

	net.Start("Minigolf.SetPlayerTimeLimit")
		net.WriteEntity(player)
		net.WriteUInt(timeLimit, 32)
	net.Broadcast()

	Minigolf.Holes.NetworkIDCache[player:SteamID()] = start
	hook.Call("Minigolf.PlayerStarted", Minigolf.GM(), player, start, ball)

  Minigolf.Holes.CreateTimeLimit(timeLimit, player, ball, start)
end

function Minigolf.Holes.CreateTimeLimit(timeLimit, player, ball, start)
	local ball = player:GetPlayerBall()

	timer.Create((player:AccountID() or player:UserID()) .. start:GetUniqueHoleName() .. "TimeLimit", timeLimit, 1, function()
		if(IsValid(player) and IsValid(ball) and ball:GetStart() == start)then
      hook.Call("Minigolf.TimeLimitReached", Minigolf.GM(), player, ball, start)

      Minigolf.Holes.End(player, ball, start)
		end
	end)
end

function Minigolf.Holes.End(player, ball, start, goal)
	local strokes = ball:GetStrokes()
	local customMessage = false

	-- They may have disconnected
	if(IsValid(player))then
		-- Goal can be nil when we end because of strike or time limit
		if(goal)then
			customMessage = hook.Call("Minigolf.GetGoalMessage", Minigolf.GM(), player, goal, strokes, start)
		else
			strokes = Minigolf.HOLE_DISQUALIFIED
		end

		player:SetHoleScore(start, strokes)

		player:SetPlayerBall(nil)
		player:SetActiveHole(nil)
		Minigolf.Holes.NetworkIDCache[player:SteamID()] = nil

		if(customMessage ~= false)then
			Minigolf.Messages.Send(player, player:Nick() .. " made it to the hole '" .. goal:GetHoleName() .. "' with " .. strokes .. " " .. Minigolf.Text.Pluralize("stroke", strokes), "Ã")
		end
	else
		--Minigolf.Messages.Send(player.GetAll(), "A player disconnected at hole '" .. start:GetHoleName() .. "!", "¡")
		print("A player disconnected at hole '" .. start:GetHoleName() .. "!")
	end

	if(IsValid(start))then
		start:OnBallHit(ball)
	end

	net.Start("Minigolf.PlayerHasFinished")
		net.WriteEntity(player)
		net.WriteEntity(start)
		net.WriteUInt(strokes, 32)
	net.Broadcast()

	hook.Call("Minigolf.PlayerFinishedHole", Minigolf.GM(), player, ball, start, strokes)

  if(IsValid(ball))then
    ball:Remove()
  end
end
