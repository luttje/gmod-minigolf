local teamLibrary = team

Minigolf.Teams = Minigolf.Teams or {}
Minigolf.Teams.All = Minigolf.Teams.All or {}
Minigolf.Teams.MenuKey = KEY_T

function Minigolf.Teams.GetOtherPlayersOnTeam(player)
	local teamPlayers = team.GetPlayers(player:Team())
	local otherPlayers = {}

	for _, teamPlayer in ipairs(teamPlayers) do
		if (teamPlayer ~= player) then
			table.insert(otherPlayers, teamPlayer)
		end
	end

	return otherPlayers
end

function Minigolf.Teams.GetNextTeamID()
	local highestID = 100

	for i, team in ipairs(Minigolf.Teams.All) do
		local teamID = team.ID

		if (teamID > highestID) then
			highestID = teamID
		end
	end

	return highestID + 1
end

function Minigolf.Teams.Update(owner, name, color, password, updateID)
	color = color or ColorRand()
	password = password ~= "" and password or nil

	local teamID = updateID or Minigolf.Teams.GetNextTeamID()
	local team = Minigolf.Teams.FindByID(teamID)

	if (team) then
		team.Name = name
		team.Color = color
		team.Password = password or false
		team.TeamOwner = owner or false
	else
		Minigolf.Teams.All[#Minigolf.Teams.All + 1] = {
			ID = teamID,
			Name = name,
			Password = password or false,
			TeamOwner = owner or false,
			MemberNetworkIds = {},
			Index = teamID,
			Color = color,
		}
	end

	teamLibrary.SetUp(teamID, name, color)

	if (SERVER) then
		Minigolf.Teams.NetworkAll()
	end

	return teamID
end

function Minigolf.Teams.Remove(teamID)
	for i, team in ipairs(Minigolf.Teams.All) do
		if (team.ID == teamID) then
			table.remove(Minigolf.Teams.All, i)
			break
		end
	end

	Minigolf.Teams.NetworkAll()
end

function Minigolf.Teams.FindByID(teamID)
	for i, team in ipairs(Minigolf.Teams.All) do
		if (team.ID == teamID) then
			return team
		end
	end

	return nil
end

function Minigolf.Teams.FindByName(name)
	for i, team in ipairs(Minigolf.Teams.All) do
		if (team.Name == name) then
			return team
		end
	end

	return false
end
