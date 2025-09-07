local playerMeta = FindMetaTable("Player")

--- Gets wether this player is the leader of their team
---@param player Player
function Minigolf.GetTeamLeader(player)
	return player:GetNWBool("GolfTeamLeader", false) == true
end

playerMeta.GetTeamLeader = Minigolf.GetTeamLeader
