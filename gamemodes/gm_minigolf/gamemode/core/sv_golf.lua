
hook.Add("PlayerDisconnected", "Minigolf.ActiveTeamPlayerLeavesReset", function(player)
	local ball = player:GetPlayerBall()

	if(IsValid(player) and IsValid(ball))then
		local start = ball:GetStart()
		Minigolf.Holes.End(player, ball, start)
	end
end)

hook.Add("MinigolfBallRolledStationary", "Minigolf.BallRolledStationaryCheckStrokes", function(ball)
	local start = ball:GetStart()
  local maxStrokes = start:GetMaxStrokes()
  local strokes = ball:GetStrokes()

	if(strokes >= maxStrokes and not ball._IsMarkedForRemoval)then
		local player = ball:GetPlayer()

		ball._IsMarkedForRemoval = true
		ball:SetRenderMode(RENDERMODE_TRANSALPHA)
		ball:SetColor(Color(255, 0, 0, 150))
		ball:SetUseable(false)

		timer.Simple(1.5, function()      
      hook.Call("MinigolfStrokeLimitReached", gm(), player, ball, start)
      
      Minigolf.Holes.End(player, ball, start)

			ball:Remove()
		end)
	end
end)

-- Don't allow players to play in the spectators team
hook.Add("MinigolfCanStartPlaying", "Minigolf.SpectatorsCantPlay", function(player, start)
	if(player:Team() == TEAM_MINIGOLF_SPECTATORS)then
		Minigolf.Messages.Send(player, "Spectators can't play, press 'T' to create or join a team!", nil, TEXT_EFFECT_DANGER)

		return false
	end

	for _, otherPly in pairs(team.GetPlayers(player:Team())) do
		local activeHole = otherPly:GetActiveHole()

		-- Don't allow team members to play when a team member is playing
		if(activeHole)then
			if(activeHole == start)then
				Minigolf.Messages.Send(player, "Wait for your team member to finish!", nil, TEXT_EFFECT_DANGER)
			else
				Minigolf.Messages.Send(player, string.format("Another one of your team members is already playing on hole '%s'", activeHole:GetHoleName()), nil, TEXT_EFFECT_DANGER)
			end

			return false
		end
		
		local swappingHole = otherPly:GetHoleWaitingForSwap()

		-- Don't allow team members to play when a team member is waiting for someone to swap in on a hole
		if(IsValid(swappingHole) and swappingHole ~= start)then
			Minigolf.Messages.Send(player, string.format("Your team member is waiting for someone to swap in on hole '%s'", swappingHole:GetHoleName()), nil, TEXT_EFFECT_DANGER)

			return false
		end
	end

	-- Don't allow other teams to play until the active team is done
	if(start:GetActiveTeam() and player:Team() ~= start:GetActiveTeam())then
		Minigolf.Messages.Send(player, "Another team is already playing this hole", nil, TEXT_EFFECT_DANGER)

		return false
	end

	-- Don't allow re-runs of a hole
	local holeStrokes = player:GetHoleScore(start)

	if(holeStrokes == HOLE_DISQUALIFIED)then
		Minigolf.Messages.Send(player, "You already played this hole and got disqualified on it")

		return false
	elseif(holeStrokes > HOLE_NOT_PLAYED)then
		Minigolf.Messages.Send(player, "You already played this hole and got " .. holeStrokes .. " " .. Minigolf.Text.Pluralize("stroke", holeStrokes) .. " on it")

		return false
	end
end)

-- Ensures the players' ball decides their visibility
hook.Add("SetupPlayerVisibility", "AddRTCamera", function(player, viewEntity)
	local ball = player:GetPlayerBall()

	if (IsValid(ball)) then
		AddOriginToPVS(ball:GetPos())
	end
end)