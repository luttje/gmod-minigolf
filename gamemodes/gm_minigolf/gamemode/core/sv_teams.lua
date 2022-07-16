util.AddNetworkString("Minigolf.SetupTeamForMinigolf")
util.AddNetworkString("Minigolf.PlayerJoinedTeam")

util.AddNetworkString("Minigolf.UpdateGolfTeamMenu")
util.AddNetworkString("Minigolf.ShowGolfTeamMenu")

util.AddNetworkString("Minigolf.TryCreateTeam")
util.AddNetworkString("Minigolf.TryUpdateTeam")
	
concommand.Add("team_join", function(player, cmd, args)
	local teamID = tonumber(args[1])
	local teamPassword = args[2]
	local targetTeam = Minigolf.Teams.FindByID(teamID)

	if(teamID == player:Team())then
		Minigolf.Messages.Send(player, "You are already in this team!")
		return
	end

	if(not targetTeam)then
		Minigolf.Messages.Send(player, "Can not join team. Team with id ".. teamID .." doesn't exist")
		return
	end

	if(not Minigolf.Teams.Join(player, targetTeam.Index, teamPassword))then
		Minigolf.Messages.Send(player, "Can not join team: Invalid password")
		return
	end

	Minigolf.Messages.Send(team.GetPlayers(player:Team()), player:Nick() .. " joined team '" .. targetTeam.Name .. "'", "N")
end)

concommand.Add("team_leave", function(player, cmd, args)
	local teamID = player:Team()

	if(IsValid(player:GetActiveHole()))then
		Minigolf.Messages.Send(player, "Can not leave the team whilst your playing a hole!", nil, Minigolf.TEXT_EFFECT_ATTENTION)
		return
	end

	-- Check if they're team leader
	if(player:GetTeamLeader())then
		local teamMembers = team.GetPlayers(teamID)

		if(#teamMembers > 1)then
			local otherLeaders = Minigolf.Teams.GetTeamLeaders(teamID, player)

			if(#otherLeaders == 0)then
				for _, teamMember in pairs(teamMembers) do
					if(teamMember ~= player)then
						teamMember:SetTeamLeader(true)
						break
					end
				end
			end
		end

		-- Before leaving, take their rank
		player:SetTeamLeader(false)
	end
	
	if(not Minigolf.Teams.Leave(player))then
		Minigolf.Messages.Send(player, "Can not leave team, are you in a team?", nil, Minigolf.TEXT_EFFECT_ATTENTION)
		return
	end

	Minigolf.Holes.ResetForPlayer(player)

	Minigolf.Messages.Send(player, "You left the team")
	Minigolf.Messages.Send(team.GetPlayers(teamID), player:Nick() .. " left the team", "Ë")
end)

concommand.Add("team_kick", function(player, cmd, args)
	local teamID = player:Team()
	local target = player.GetBySteamID(args[1])

	if(not IsValid(target))then
		Minigolf.Messages.Send(player, "This player isn't in the server!", nil, Minigolf.TEXT_EFFECT_ATTENTION)
		return
	end

	if(target:Team() ~= teamID)then
		Minigolf.Messages.Send(player, "This player isn't on your team!", nil, Minigolf.TEXT_EFFECT_ATTENTION)
		return
	end

	if(not player:GetTeamLeader())then
		Minigolf.Messages.Send(player, "You are not a team leader so can't kick!", nil, Minigolf.TEXT_EFFECT_ATTENTION)
		return
	end

	if(IsValid(target:GetActiveHole()))then
		Minigolf.Messages.Send(player, "You cannot kick this player whilst they're playing a hole!", nil, Minigolf.TEXT_EFFECT_ATTENTION)
		return
	end
	
	-- Before leaving, take their rank
	target:SetTeamLeader(false)
	
	if(not Minigolf.Teams.Leave(target))then
		ErrorNoHalt("Error kicking " .. tostring(target) .. " from team " .. teamID)
		return
	end

	Minigolf.Holes.ResetForPlayer(target)

	Minigolf.Messages.Send(target, "You were kicked from the team")
	Minigolf.Messages.Send(team.GetPlayers(teamID), player:Nick() .. " was kicked from the team", "Y")
end)

concommand.Add("team_set_rank", function(player, cmd, args)
	local teamID = player:Team()
	local target = player.GetBySteamID(args[1])
	local isNowTeamLeader = args[2] == "leader" and true or false

	if(not player:GetTeamLeader())then
		Minigolf.Messages.Send(player, "You aren't team leader, so can't demote or promote players!", nil, Minigolf.TEXT_EFFECT_ATTENTION)
		return
	end

	if(not IsValid(target))then
		Minigolf.Messages.Send(player, "This player isn't in the server!", nil, Minigolf.TEXT_EFFECT_ATTENTION)
		return
	end

	if(target:Team() ~= teamID)then
		Minigolf.Messages.Send(player, "This player isn't on your team!", nil, Minigolf.TEXT_EFFECT_ATTENTION)
		return
	end

	if(not isNowTeamLeader)then
		-- Don't let players demote themselves if they are the only team leader
		local otherLeaders = Minigolf.Teams.GetTeamLeaders(teamID, target)

		if(#otherLeaders == 0)then
			Minigolf.Messages.Send(player, "You can't demote the only team leader!", nil, Minigolf.TEXT_EFFECT_ATTENTION)
			return
		end
	end

	target:SetTeamLeader(isNowTeamLeader)
	
	if(isNowTeamLeader)then
		Minigolf.Messages.Send(target, "You were promoted to team leader", Minigolf.TEXT_EFFECT_SPARKLE)
		Minigolf.Messages.Send(team.GetPlayers(teamID), player:Nick() .. " was promoted to team leader", "\\", Minigolf.TEXT_EFFECT_SPARKLE)
	else
		Minigolf.Messages.Send(target, "You were demoted to regular team member", Minigolf.TEXT_EFFECT_ATTENTION)
		Minigolf.Messages.Send(team.GetPlayers(teamID), player:Nick() .. " was demoted to regular team member", "\\", Minigolf.TEXT_EFFECT_ATTENTION)
	end
end)

net.Receive("Minigolf.TryUpdateTeam", function(len, player)
	local teamName = net.ReadString()
	local teamColor = net.ReadColor()
	local teamPassword = net.ReadString()
	local targetTeam = Minigolf.Teams.All[player:Team()]

	if(utf8.len(teamName) == 0)then
		Minigolf.Messages.Send(player, "Can not change a team to have an empty name")
		return
	end
  
  local isBad, badWord = Minigolf.Text.ContainsBadWords(teamName)

  if(isBad)then
    Minigolf.Messages.Send(player, string.format(Minigolf.TEAM_NAME_PROFANITY_MESSAGE, badWord))
    return
  end

  if(utf8.len(teamName) > Minigolf.TEAM_NAME_LENGTH_MAX)then
    Minigolf.Messages.Print(player, Minigolf.TEAM_NAME_LENGTH_MAX, nil, Minigolf.TEXT_EFFECT_DANGER)
    return
  end
  
  if(utf8.len(teamName) < Minigolf.TEAM_NAME_LENGTH_MIN)then
    Minigolf.Messages.Print(player, Minigolf.TEAM_NAME_LENGTH_MIN, nil, Minigolf.TEXT_EFFECT_DANGER)
    return
  end

	if(teamName:find("\"", 1, true))then
		Minigolf.Messages.Send(player, "Can not change the team name because of the invalid character: \"")
		return
	end

	if(not targetTeam)then
		Minigolf.Messages.Send(player, "Can not update because team stopped existing")
		return
	end

	local oldName = targetTeam.Name
	local index = Minigolf.Teams.Update(player, teamName, teamColor, teamPassword, targetTeam.Index)
	Minigolf.Teams.Join(player, index, teamPassword)

	hook.Call("Minigolf.Minigolf.TryUpdateTeamd", Minigolf.GM(), index, teamName, teamColor, teamPassword)

	if(oldName ~= teamName)then
		Minigolf.Messages.Send(team.GetPlayers(player:Team()), player:Nick() .. " updated team '" .. oldName .. "' to become '" .. teamName .. "'", "N")
	else
		Minigolf.Messages.Send(team.GetPlayers(player:Team()), player:Nick() .. " updated team '" .. oldName .. "'", "N")
	end
end)

net.Receive("Minigolf.TryCreateTeam", function(len, player)
	local teamName = net.ReadString()
	local teamColor = net.ReadColor()
	local teamPassword = net.ReadString()
	local targetTeam = Minigolf.Teams.FindByName(teamName)

	if(utf8.len(teamName) == 0)then
		Minigolf.Messages.Send(player, "Can not create a team to have an empty name")
		return
  end
  
  local isBad, badWord = Minigolf.Text.ContainsBadWords(teamName)

  if(isBad)then
    Minigolf.Messages.Send(player, string.format(Minigolf.TEAM_NAME_PROFANITY_MESSAGE, badWord))
    return
  end
  
  if(utf8.len(teamName) > Minigolf.TEAM_NAME_LENGTH_MAX)then
    Minigolf.Messages.Print(player, Minigolf.TEAM_NAME_LENGTH_MAX_MESSAGE, nil, Minigolf.TEXT_EFFECT_DANGER)
    return
  end
  
  if(utf8.len(teamName) < Minigolf.TEAM_NAME_LENGTH_MIN)then
    Minigolf.Messages.Print(player, Minigolf.TEAM_NAME_LENGTH_MIN_MESSAGE, nil, Minigolf.TEXT_EFFECT_DANGER)
    return
  end

	if(teamName:find("\"", 1, true))then
		Minigolf.Messages.Send(player, "Can not create team because of invalid character: \"")
		return
	end

	if(targetTeam)then
		Minigolf.Messages.Send(player, "Can not create team because it already exists")
		return
	end

	local index = Minigolf.Teams.Update(player, teamName, teamColor, teamPassword)
	Minigolf.Teams.Join(player, index, teamPassword)

	-- Make them team leader of their own team
	player:SetTeamLeader(true)
	
	hook.Call("Minigolf.TeamMade", Minigolf.GM(), index, teamName, teamColor, teamPassword)

	Minigolf.Messages.Send(team.GetPlayers(player:Team()), player:Nick() .. " created team '" .. teamName .. "'", "N")
end)

-- Set the team of the player to the spectator team
hook.Add("PlayerSpawn", "Minigolf.SetInitialTeam", function(player)
  -- Don't let players be in a team that is not created in this gamemode.
  if(not Minigolf.Teams.All[player:Team()])then
		player:SetTeam(TEAM_MINIGOLF_SPECTATORS)
		
			-- Create and join a team on spawn automatically
		if(not player._HasInitializedInOwnTeam)then
			player._HasInitializedInOwnTeam = true

			local teamName = string.format("%s's Team", player:Nick())
			local randomPassword = math.random(1000, 9999)

			-- Create and join the team
			local index = Minigolf.Teams.Update(player, teamName, ColorRand(), randomPassword)
			Minigolf.Teams.Join(player, index, randomPassword)

			-- Make them team leader of their own team
			player:SetTeamLeader(true)

			Minigolf.Messages.Send(player, string.format("A team named '%s' has been created for you. It's password is '%s'", teamName, randomPassword), "N")
		end
  end
end)

gameevent.Listen( "player_disconnect" )
hook.Add("player_disconnect", "Minigolf.ActiveTeamPlayerLeavesReset", function(data)
	Minigolf.Teams.LeaveByNetworkID(data.networkid)
end)