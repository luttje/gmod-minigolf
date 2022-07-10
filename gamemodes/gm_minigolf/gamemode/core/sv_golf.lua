hook.Add("Minigolf.CanStartPlaying", "Minigolf.PreventSpectatorsToPlay", function(player, start)
	-- Don't allow players to play in the spectators team
	if(player:Team() == TEAM_MINIGOLF_SPECTATORS)then
		Minigolf.Messages.Send(player, "Spectators can't play, press 'T' to create or join a team!", nil, Minigolf.TEXT_EFFECT_DANGER)

		return false
	end
end)

hook.Add("Minigolf.CanStartPlaying", "Minigolf.RestrictWhenTeamsPlaying", function(player, start)
	for _, otherPly in pairs(team.GetPlayers(player:Team())) do
		local activeHole = otherPly:GetActiveHole()

		-- Don't allow team members to play when a team member is playing
		if(activeHole)then
			if(activeHole == start)then
				Minigolf.Messages.Send(player, "Wait for your team member to finish!", nil, Minigolf.TEXT_EFFECT_DANGER)
			else
				Minigolf.Messages.Send(player, string.format("Another one of your team members is already playing on hole '%s'", activeHole:GetHoleName()), nil, Minigolf.TEXT_EFFECT_DANGER)
			end

			return false
		end
		
		local swappingHole = otherPly:GetHoleWaitingForSwap()

		-- Don't allow team members to play when a team member is waiting for someone to swap in on a hole
		if(IsValid(swappingHole) and swappingHole ~= start)then
			Minigolf.Messages.Send(player, string.format("Your team member is waiting for someone to swap in on hole '%s'", swappingHole:GetHoleName()), nil, Minigolf.TEXT_EFFECT_DANGER)

			return false
		end
	end

	-- Don't allow other teams to play until the active team is done
	local activeTeam = start:GetNWInt("MiniGolf.ActiveTeam", Minigolf.NO_TEAM_PLAYING)
	if(activeTeam and player:Team() ~= activeTeam)then
		Minigolf.Messages.Send(player, "Another team is already playing this hole", nil, Minigolf.TEXT_EFFECT_DANGER)

		return false
	end
end)
