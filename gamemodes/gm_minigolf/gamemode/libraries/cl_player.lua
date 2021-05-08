local playerMeta = FindMetaTable("Player")

--- Gets wether this player is the leader of their team
---@param player Player
function Minigolf.GetTeamLeader(player)
  return player:GetNWBool("GolfTeamLeader", false) == true
end

playerMeta.GetTeamLeader = Minigolf.GetTeamLeader

--- Gets the ball entity that the player deployed on a hole
function Minigolf.GetPlayerBall(player)
  return player:GetNWEntity("PlayerBall")
end

playerMeta.GetPlayerBall = Minigolf.GetPlayerBall

--- Sets the ball the player is inputting force for
---@param player Player
---@param ball Entity
function Minigolf.SetBallGivingForce(player, ball)
  player._IsGettingForce = ball
end

--- Gets the ball the player is inputting force for
---@param player Player
---@return Entity|nil
function Minigolf.GetBallGivingForce(player)
  return player._IsGettingForce
end

playerMeta.SetBallGivingForce = Minigolf.SetBallGivingForce
playerMeta.GetBallGivingForce = Minigolf.GetBallGivingForce