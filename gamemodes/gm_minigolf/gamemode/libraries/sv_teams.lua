Minigolf.Teams = Minigolf.Teams or {}

local playerLibrary = player

function Minigolf.Teams.GetCompactInfo()
	local info = {}

	for teamID, team in pairs(Minigolf.Teams.All) do
		info[teamID] = {
			n = team.Name,
			p = team.Password or false
		}
	end

	return info
end

function Minigolf.Teams.NetworkForGame(teamID, name, color, receiver)
	net.Start("Minigolf.SetupTeamForMinigolf")
	net.WriteUInt(teamID, 8)
	net.WriteString(name)
	net.WriteColor(color)

	if(not receiver)then
		net.Broadcast()
	else
		net.Send(receiver)
	end
end

-- Send all teams to someone or everyone
function Minigolf.Teams.NetworkAll(player)
	local players = player or playerLibrary.GetAll()

	net.Start("Minigolf.UpdateGolfTeamMenu")
		net.WriteTable(Minigolf.Teams.GetCompactInfo())
	net.Send(players)
end

function Minigolf.Teams.Join(player, teamID, password)
	local targetTeam = Minigolf.Teams.All[teamID]

	if(targetTeam.Password)then
		if(targetTeam.Password ~= password)then
			return false
		end
	end

	player:SetTeam(teamID)
	targetTeam.MemberNetworkIds[player:SteamID()] = true
	
	local teamMembers = team.GetPlayers(teamID)

	for _, teamMember in pairs(teamMembers) do
		if(teamMember ~= player)then
			for holeName, holeScore in pairs(teamMember:GetAllHoleScores()) do
				if(holeScore ~= Minigolf.HOLE_NOT_PLAYED)then
					player:SetHoleScore(holeName, Minigolf.HOLE_SKIPPED)
				end
			end

			-- We only need to check for one other player to know what has been played (since all players joining a team go through this process)
			break
		end
	end

	net.Start("Minigolf.PlayerJoinedTeam")
		net.WriteEntity(player)
	net.Broadcast()

	return true
end

function Minigolf.Teams.Leave(player)
	local teamID = player:Team()
	local targetTeam = Minigolf.Teams.All[teamID]

	if(not targetTeam or teamID == TEAM_MINIGOLF_SPECTATORS)then
		return false
	end

	Minigolf.Holes.ResetForPlayer(player)

	player:SetTeam(TEAM_MINIGOLF_SPECTATORS)
	targetTeam.MemberNetworkIds[player:SteamID()] = nil

	net.Start("Minigolf.ShowGolfTeamMenu")
	net.WriteBool(true)
	net.Send(player)

	hook.Call("Minigolf.PlayerLeftTeam", Minigolf.GM(), player, teamID)

	if(#team.GetPlayers(teamID) == 0)then
		Minigolf.Teams.Remove(teamID)
	end

	return true
end

function Minigolf.Teams.LeaveByNetworkID(networkId)
	local targetTeam
	
	for teamID, team in pairs(Minigolf.Teams.All) do
		if(team.MemberNetworkIds[networkId] == true)then
			targetTeam = team
			break
		end
	end

	if(targetTeam == nil)then
		return
	end

	targetTeam.MemberNetworkIds[networkId] = nil

	if(table.Count(targetTeam.MemberNetworkIds) == 0)then
		Minigolf.Teams.Remove(targetTeam.ID)
	end

	return true
end

function Minigolf.Teams.GetTeamLeaders(teamID, excludePlayer)
	local leaders = {}

	for _, teamMember in pairs(team.GetPlayers(teamID)) do
		if(teamMember:GetTeamLeader() and (not excludePlayer or teamMember ~= excludePlayer))then
			table.insert(leaders, teamMember)
		end
	end

	return leaders
end