Minigolf.Player = Minigolf.Player or {}

local playerMeta = FindMetaTable("Player")
local playerLibrary = player

--- Sets wether this player is the leader of their team
---@param player Player
---@param isTeamLeader boolean
function Minigolf.SetTeamLeader(player, isTeamLeader)
	local teamID = player:Team()

	if (teamID <= TEAM_MINIGOLF_SPECTATORS) then
		print(player, isTeamLeader)
		error("Setting team leader status of player without team!")
	end

	player.GolfTeamLeader = isTeamLeader
	player:SetNWBool("GolfTeamLeader", isTeamLeader)
end

--- Gets wether this player is the leader of their team
---@param player Player
---@return boolean
function Minigolf.GetTeamLeader(player)
	return player.GolfTeamLeader or false
end

playerMeta.SetTeamLeader = Minigolf.SetTeamLeader
playerMeta.GetTeamLeader = Minigolf.GetTeamLeader

--[[
  Getter and setter to see if the player is waiting for a team member to take their turn
--]]
-- Set to nil to indicate the player is not waiting anymore
function Minigolf.SetHoleWaitingForSwap(player, start)
	player._IsWaitingForSwapAtHole = start

	return start
end

function Minigolf.GetHoleWaitingForSwap(player)
	return player._IsWaitingForSwapAtHole
end

playerMeta.SetHoleWaitingForSwap = Minigolf.SetHoleWaitingForSwap
playerMeta.GetHoleWaitingForSwap = Minigolf.GetHoleWaitingForSwap
