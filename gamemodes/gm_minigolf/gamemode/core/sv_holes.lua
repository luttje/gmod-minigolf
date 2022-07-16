util.AddNetworkString("Minigolf.SetSwapTimeLimit")
util.AddNetworkString("Minigolf.EndSwapTimeLimit")
util.AddNetworkString("Minigolf.PlayerShowScoreboard")

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

hook.Add("Minigolf.PlayerStarted", "Minigolf.ShowMessageOnHoleStart", function(player, start, ball)
	local parMsg = start._HolePar and (" (Par: " .. start._HolePar .. ")") or ""
	local teamPlayers = team.GetPlayers(player:Team())
	
	start:SetNWInt("MiniGolf.ActiveTeam", player:Team())

	Minigolf.Holes.EndSwapTimer(teamPlayers, start)
	Minigolf.Messages.Send(teamPlayers, player:Nick() .. " has started at '" .. start:GetHoleName() .. "'" .. parMsg, "£")
end)

-- When a minigolf player is done, set a time limit for the next player to take their turn
function Minigolf.Holes.CreateTimeLimitSwap(timeLimit, player, teamID, start, strokes)
	local teamPlayers = team.GetPlayers(teamID)
	local holeName = start:GetUniqueHoleName()
	local isLastPlayer = true

	for _, otherPly in pairs(teamPlayers) do
		if(otherPly ~= player 
		and otherPly:GetHoleScore(start) == Minigolf.HOLE_NOT_PLAYED)then
			isLastPlayer = false
			break
		end
	end

	if(not isLastPlayer)then
		net.Start("Minigolf.SetSwapTimeLimit")
			net.WriteEntity(start)
			net.WriteUInt(timeLimit, 32)
		net.Send(teamPlayers)

		Minigolf.Messages.Send(teamPlayers, "Alright switch to the next player within " .. timeLimit .. " seconds!", "M", Minigolf.TEXT_EFFECT_ATTENTION)

		-- The player may have left our team waiting
		if(IsValid(player))then
			-- Indicate we are waiting for someone to take their turn
			player:SetHoleWaitingForSwap(start)
		end

		-- Start the timelimit for switching hole
		timer.Create(holeName .. "SwapTimeLimit", timeLimit, 1, function()
			local disqualifiedPlayer = nil
			
			-- Refresh the players on this team (some may have left)
			teamPlayers = team.GetPlayers(teamID)

			Minigolf.Holes.EndSwapTimer(teamPlayers, start)

			-- Penalize the players by disqualifying them
			for _, otherPly in pairs(teamPlayers) do
				if(IsValid(otherPly) and otherPly ~= player)then
					if(otherPly:GetHoleScore(start) == Minigolf.HOLE_NOT_PLAYED)then
						Minigolf.Messages.Send(otherPly, "You have been disqualified for taking too long to take your turn on '".. start:GetHoleName() .."'!", Minigolf.TEXT_EFFECT_ATTENTION)
				
						otherPly:SetHoleScore(start, Minigolf.HOLE_DISQUALIFIED)

						disqualifiedPlayer = otherPly
						break
					end
				end
			end

			if(disqualifiedPlayer ~= nil)then
				print(disqualifiedPlayer:Nick() .. " took too long to take their turn and got disqualified")
				Minigolf.Messages.Send(Minigolf.Teams.GetOtherPlayersOnTeam(disqualifiedPlayer), disqualifiedPlayer:Nick() .. " took too long to take their turn and got disqualified")
			end

			Minigolf.Holes.ProcessTeamEnd(teamID, start)
		end)
	end
end

function Minigolf.Holes.ProcessTeamEnd(teamID, start)
	local teamPlayers = team.GetPlayers(teamID)
	local teamName = team.GetName(teamID)

	start:SetNWInt("MiniGolf.ActiveTeam", Minigolf.NO_TEAM_PLAYING)

  hook.Call("Minigolf.TeamFinishedHole", Minigolf.GM(), teamID, teamPlayers, start)

	Minigolf.Messages.Send(nil, "Team '" .. teamName .. "' is done playing at '" .. start:GetHoleName() .. "'")
end

hook.Remove("Minigolf.PlayerFinishedAllHoles", "Minigolf.ResetWhenPlayerFinishedAllHoles")
hook.Add("Minigolf.PlayerFinishedAllHoles", "Minigolf.ResetTeamWhenPlayerFinishedAllHoles", function(player, lastHole) 
	local teamID = player:Team()
	local teamPlayers = team.GetPlayers(teamID)
	local teamName = team.GetName(teamID)

	Minigolf.Messages.Send(nil, "Team '" .. teamName .. "' has finished all the holes!")

	for _,teamPlayer in pairs(teamPlayers) do
		net.Start("Minigolf.PlayerShowScoreboard")
		net.WriteEntity(lastHole)
		net.WriteTable(teamPlayer:GetAllHoleScores())
		net.WriteBool(true) -- Clear the local scores (so flag checkmarks reset)
		net.Send(teamPlayer)

		teamPlayer:PlaySound("plats/elevbell1.wav")
	end

	for _, teamMember in pairs(teamPlayers) do
		Minigolf.Holes.ResetForPlayer(teamMember)
	end
end)

hook.Add("Minigolf.PlayerFinishedHole", "Minigolf.SwapTeamMemberOnFinishHole", function(player, ball, start, strokes)
	local teamID = start:GetNWInt("MiniGolf.ActiveTeam", Minigolf.NO_TEAM_PLAYING)
	local teamPlayers = team.GetPlayers(teamID)

	if(IsValid(ball))then
		ball:Remove()
	end

	for _, otherPly in pairs(teamPlayers) do
		if(otherPly ~= player and otherPly:GetHoleScore(start) == Minigolf.HOLE_NOT_PLAYED)then
			Minigolf.Holes.CreateTimeLimitSwap(30, player, teamID, start, strokes)

			-- Not everyone has played yet, so let someone swap in.
			return
		end
	end

	-- End this teams play here
	Minigolf.Holes.ProcessTeamEnd(teamID, start)
end)
