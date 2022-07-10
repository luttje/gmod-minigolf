local playerMeta = FindMetaTable("Player")

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

--- Returns the hole this player is playing at
---@param player Player
---@return Entity|nil
function Minigolf.GetActiveHole(player)
  return player:GetNWEntity("Minigolf.ActiveHole")
end

playerMeta.GetActiveHole = Minigolf.GetActiveHole