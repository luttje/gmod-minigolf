util.AddNetworkString("Minigolf.SetSwapTimeLimit")
util.AddNetworkString("Minigolf.EndSwapTimeLimit")
util.AddNetworkString("Minigolf.SetPlayerTimeLimit")
util.AddNetworkString("Minigolf.PlayerHasFinished")
util.AddNetworkString("Minigolf.PlayerShowScoreboard")

Minigolf.Holes = Minigolf.Holes or {}
Minigolf.Holes.Cache = {}

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

	return Minigolf.Holes.Cache[hole]
end

function Minigolf.Holes.ResetForPlayer(player)
	player:ResetHoleScores()

	for _, hole in pairs(ents.FindByClass("minigolf_hole_start")) do
    player:SetHoleScore(hole, HOLE_NOT_PLAYED)
	end
end

function Minigolf.Holes.EndSwapTimer(teamPlayers, start)
	local holeName = start:GetUniqueHoleName()

	local timerName = holeName .. "SwapTimeLimit"

	-- Check if we were swapping team members on this hole
	if(timer.Exists(timerName))then
		timer.Remove(timerName)
		
		for _, teamPlayer in pairs(teamPlayers) do
			teamPlayer:SetHoleWaitingForSwap(nil)
		end

		net.Start("Minigolf.EndSwapTimeLimit")
		net.WriteEntity(start)
		net.Send(teamPlayers)
	end
end

function Minigolf.Holes.Start(player, ball, start)
	local holeName = start:GetUniqueHoleName()
	local timeLimit = start:GetLimit()
	local teamPlayers = team.GetPlayers(player:Team())
	
	Minigolf.Holes.EndSwapTimer(teamPlayers, start)

  player:SetActiveHole(start)

	net.Start("Minigolf.SetPlayerTimeLimit")
		net.WriteEntity(player)
		net.WriteUInt(timeLimit, 32)
	net.Broadcast()

	start:SetActiveTeam(player:Team())

	local parMsg = start._HolePar and (" (Par: " .. start._HolePar .. ")") or ""

	Minigolf.Messages.Send(teamPlayers, player:Nick() .. " has started at '" .. start:GetHoleName() .. "'" .. parMsg, "£")

	hook.Call("MinigolfPlayerStarted", gm(), player, start, ball)

  Minigolf.Holes.CreateTimeLimit(timeLimit, player, ball, start)
end

-- When a minigolf player is done, set a time limit for the next player to take their turn
function Minigolf.Holes.CreateTimeLimitSwap(timeLimit, player, teamID, start, strokes)
	local teamPlayers = team.GetPlayers(teamID)
	local holeName = start:GetUniqueHoleName()
	local isLastPlayer = true

	for _, otherPly in pairs(teamPlayers) do
		if(otherPly:GetHoleScore(start) == HOLE_NOT_PLAYED)then
			isLastPlayer = false
			break
		end
	end

	if(not isLastPlayer)then
		net.Start("Minigolf.SetSwapTimeLimit")
			net.WriteEntity(start)
			net.WriteUInt(timeLimit, 32)
		net.Send(teamPlayers)

		Minigolf.Messages.Send(teamPlayers, "Alright switch to the next player within " .. timeLimit .. " seconds!", "M", TEXT_EFFECT_ATTENTION)

		-- The player may have left our team waiting
		if(IsValid(player))then
			-- Indicate we are waiting for someone to take their turn
			player:SetHoleWaitingForSwap(start)

			-- Remove the play timelimit timer
			timer.Remove((player:AccountID() or player:UserID()) .. holeName .. "TimeLimit")
		end

		-- Start the timelimit for switching hole
		timer.Create(holeName .. "SwapTimeLimit", timeLimit, 1, function()
			local wereDisqualified = false

			Minigolf.Holes.EndSwapTimer(teamPlayers, start)

			-- Penalize the players by disqualifying them
			for _, otherPly in pairs(teamPlayers) do
				if(IsValid(otherPly))then
					if(otherPly:GetHoleScore(start) == HOLE_NOT_PLAYED)then
						Minigolf.Messages.Send(otherPly, "You have been disqualified for taking too long to take your turn on '".. start:GetHoleName() .."'!", TEXT_EFFECT_ATTENTION)
				
						otherPly:SetHoleScore(start, HOLE_DISQUALIFIED)

						wereDisqualified = true
					end
				end
			end

			if(wereDisqualified)then
				Minigolf.Messages.Send(teamPlayers, "Some players took too long to take their turn and got disqualified")
			end

			Minigolf.Holes.ProcessTeamEnd(teamID, start)
		end)
	end
end

function Minigolf.Holes.CreateTimeLimit(timeLimit, player, ball, start)
	local ball = player:GetPlayerBall()

	timer.Create((player:AccountID() or player:UserID()) .. start:GetUniqueHoleName() .. "TimeLimit", timeLimit, 1, function()
		if(IsValid(player) and IsValid(ball) and ball:GetStart() == start)then
      hook.Call("MinigolfTimeLimitReached", gm(), player, ball, start)

      Minigolf.Holes.End(player, ball, start)
		end
	end)
end

function Minigolf.Holes.End(player, ball, start, goal)
	local strokes = ball:GetStrokes()
	local teamID = start:GetActiveTeam()
	local teamPlayers = team.GetPlayers(teamID)
	local teamName = team.GetName(teamID)
	local holeName = start:GetUniqueHoleName()
	local customMessage = false

	-- They may have disconnected
	if(IsValid(player))then
		-- Goal can be nil when we end because of strike or time limit
		if(goal)then
			customMessage = hook.Call("MinigolfGetGoalMessage", gm(), player, goal, strokes, start)
		else
			strokes = HOLE_DISQUALIFIED
		end

		player:SetHoleScore(start, strokes)

		player:SetPlayerBall(nil)
		player:SetActiveHole(nil)

		if(customMessage ~= false)then
			Minigolf.Messages.Send(teamPlayers, player:Nick() .. " made it to the hole '" .. goal:GetHoleName() .. "' with " .. strokes .. " " .. Minigolf.Text.Pluralize("stroke", strokes), "Ã")
		end
	else
		Minigolf.Messages.Send(teamPlayers, "A player disconnect at hole '" .. start:GetHoleName() .. "!", "¡")
	end

	if(IsValid(start))then
		start:OnBallHit(ball)
	end

	net.Start("Minigolf.PlayerHasFinished")
		net.WriteEntity(player)
		net.WriteEntity(start)
		net.WriteUInt(strokes, 32)
	net.Broadcast()

	hook.Call("MinigolfPlayerFinishedHole", gm(), player, ball, start, strokes)

	for _, otherPly in pairs(teamPlayers) do
		if(otherPly:GetHoleScore(start) == HOLE_NOT_PLAYED)then
			Minigolf.Holes.CreateTimeLimitSwap(30, player, teamID, start, strokes)

			if(IsValid(ball))then
				ball:Remove()
			end

			return
		end
	end

  if(IsValid(ball))then
    ball:Remove()
  end

	Minigolf.Holes.ProcessTeamEnd(teamID, start)
end

function Minigolf.Holes.ProcessTeamEnd(teamID, start)
  local minHolesPlayed = 9999999 -- To find which player played the least holes
	local teamPlayers = team.GetPlayers(teamID)
	local teamName = team.GetName(teamID)
	local holeName = start:GetUniqueHoleName()

	for _, otherPly in pairs(teamPlayers) do
		local plyHoleCount = 0
		for holeName, holeScore in pairs(otherPly:GetAllHoleScores()) do
			if(holeScore ~= HOLE_NOT_PLAYED)then
				plyHoleCount = plyHoleCount + 1
			end
		end

		if(plyHoleCount < minHolesPlayed)then
			minHolesPlayed = plyHoleCount
		end
	end

	start:SetActiveTeam(nil)

	-- Check if the player with the least holes played has actually played all holes (thus the team is finished)
  local allHolesPlayed = minHolesPlayed == NUM_HOLES

  hook.Call("MinigolfTeamFinishedHole", gm(), teamID, teamPlayers, start, allHolesPlayed)

	-- Check if all holes have been played
	if(allHolesPlayed)then
		Minigolf.Messages.Send(nil, "Team '" .. teamName .. "' has finished all the holes! They can restart.")

		for _,teamPlayer in pairs(teamPlayers) do
			net.Start("Minigolf.PlayerShowScoreboard")
			net.WriteEntity(start)
			net.WriteTable(teamPlayer:GetAllHoleScores())
			net.WriteBool(true) -- Clear the local scores (so flag checkmarks reset)
			net.Send(teamPlayer)

			teamPlayer:PlaySound("plats/elevbell1.wav")
		end

		for _, teamMember in pairs(teamPlayers) do
			Minigolf.Holes.ResetForPlayer(teamMember)
		end
	else
		Minigolf.Messages.Send(nil, "Team '" .. teamName .. "' is done playing at '" .. start:GetHoleName() .. "'")
	end
end