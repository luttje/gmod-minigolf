Minigolf.Teams = Minigolf.Teams or {}
Minigolf.Teams.All = Minigolf.Teams.All or {}
Minigolf.Teams.MenuKey = KEY_T

function Minigolf.Teams.GetOtherPlayers(player)
	local teamPlayers = team.GetPlayers(player:Team())
	local otherPlayers = {}

	for _, teamPlayer in pairs(teamPlayers) do
		if(teamPlayer ~= player)then
			table.insert(otherPlayers, teamPlayer)
		end
	end

	return otherPlayers
end

function Minigolf.Teams.Update(owner, name, color, password, updateID)
	color = color or ColorRand()
	password = password ~= "" and password or nil
  
  local teamID = updateID or #Minigolf.Teams.All + 1

	Minigolf.Teams.All[teamID] = {
		Name = name,
		Password = password or false,
		TeamOwner = owner or false,
		Index = teamID,
		Color = color,
	}

	team.SetUp(teamID, name, color)

	if(SERVER)then
		Minigolf.Teams.NetworkForGame(teamID, name, color)

		Minigolf.Teams.NetworkAll()
  end

	return teamID
end

function Minigolf.Teams.Remove(teamID)
	Minigolf.Teams.All[teamID] = nil
	
	Minigolf.Teams.NetworkAll()
end

function Minigolf.Teams.FindByID(teamID)
	return Minigolf.Teams.All[teamID]
end

function Minigolf.Teams.FindByName(name)
	for teamID, team in pairs(Minigolf.Teams.All) do
		if(team.Name == name)then
			return team
		end
	end

	return false
end
