Minigolf.Player = Minigolf.Player or {}

local playerMeta = FindMetaTable("Player")

--- Gets the ball entity that the player deployed on a hole
function Minigolf.Player.GetBall(player)
  return player:GetNWEntity("PlayerBall")
end

playerMeta.GetMinigolfBall = Minigolf.Player.GetBall

--- Sets the ball the player is inputting force for
---@param player Player
---@param ball Entity
function Minigolf.Player.SetBallGivingForce(player, ball)
  player._IsGettingForce = ball
end

--- Gets the ball the player is inputting force for
---@param player Player
---@return Entity|nil
function Minigolf.Player.GetBallGivingForce(player)
  return player._IsGettingForce
end

playerMeta.SetBallGivingForce = Minigolf.Player.SetBallGivingForce
playerMeta.GetBallGivingForce = Minigolf.Player.GetBallGivingForce

--- Returns the hole this player is playing at
---@param player Player
---@return Entity|nil
function Minigolf.Player.GetActiveHole(player)
  return player:GetNWEntity("Minigolf.ActiveHole")
end

playerMeta.GetActiveHole = Minigolf.Player.GetActiveHole