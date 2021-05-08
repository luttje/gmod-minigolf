Minigolf.Player = Minigolf.Player or {}

util.AddNetworkString("Minigolf.PlaySound")

local playerMeta = FindMetaTable("Player")
local playerLibrary = player

--- Sets that the given entity exists in the client realm
--- This should only be called from a net message received from the client.
---@param sharedEntity Entity The Entity that now exists in both the server _and_ the client realms
function playerMeta:SetEntityExists(sharedEntity)
  self._existingEntities = self._existingEntities or {}

  self._existingEntities[sharedEntity] = true

  self:CallEntityExists(sharedEntity)
end

--- Returns whether an entity already exists on the client
---@param serverEntity Entity The Entity that now maybe only exists in the server realm
---@return boolean
function playerMeta:GetEntityExists(serverEntity)
  self._existingEntities = self._existingEntities or {}
  
  return self._existingEntities[serverEntity] == true
end

--- Delays a function until we're sure this entity exists in the client realm
--- This is neccessary because the server inherently knows about the existance of things well before the clients
--- Use this function to ensure a client isn't informed about an entity a few milliseconds before they know about it.
---@param serverEntity Entity The Entity that now maybe only exists in the server realm
---@param callback fun(ply:Player, entity:Entity) The callback which receives the player in question, as well as the entity that at the time of calling this callback exists in both realms
function playerMeta:OnEntityExists(serverEntity, callback)
  self._existingEntities = self._existingEntities or {}
  
  -- If the entity already exists callback rightaway
  if(self:GetEntityExists(serverEntity))then
    callback(self, serverEntity)
    return
  end

  self._entityExistanceCallbacks = self._entityExistanceCallbacks or {}

  -- Otherwise store it in the callback list
  self._entityExistanceCallbacks[serverEntity] = self._entityExistanceCallbacks[serverEntity] or {}

  table.insert(self._entityExistanceCallbacks[serverEntity], callback)
end

--- Calls all callbacks for an entity, informing that the entity now exists in both the client and server realms.
function playerMeta:CallEntityExists(sharedEntity)
  self._entityExistanceCallbacks = self._entityExistanceCallbacks or {}
  self._entityExistanceCallbacks[sharedEntity] = self._entityExistanceCallbacks[sharedEntity] or {}

  local calledCallbacks = {}

  for i, callback in pairs(self._entityExistanceCallbacks[sharedEntity]) do
    callback(self, sharedEntity)

    calledCallbacks[i] = true
  end

  -- Remove all these callbacks in reverse (so we don't pull the indices away from under our feet while looping)
  for i = #calledCallbacks, 1, -1 do
    table.remove(self._entityExistanceCallbacks[sharedEntity], i)
  end
end

--- Find a player by a (part of) their name
function Minigolf.Player.FindByName(playerName)
  local longestMatch

  playerName = string.lower(playerName)

  for _, player in ipairs(playerLibrary.GetAll()) do
    local name = string.lower(player:Nick())

    if(name == playerName)then
      return player
    end

    if(string.find(name, playerName, 1, true) ~= nil and (not IsValid(longestMatch) or utf8.len(longestMatch:Nick()) < utf8.len(name)))then
      longestMatch = player
    end
  end

  return longestMatch
end

--- Play a sound for the player using surface.PlaySound
function Minigolf.Player.PlaySound(player, soundFile)
  net.Start("Minigolf.PlaySound")
  net.WriteString(soundFile)
  net.Send(player)
end

playerMeta.PlaySound = Minigolf.Player.PlaySound

--- Sets wether this player is the leader of their team
---@param player Player
---@param isTeamLeader boolean
function Minigolf.SetTeamLeader(player, isTeamLeader)
  local teamID = player:Team()

  if(teamID <= TEAM_MINIGOLF_SPECTATORS)then
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

--- Sets the ball entity that the player deployed on a hole
--- Set ball to nil when it's removed
---@param player Player
---@param ball Entity
function Minigolf.SetPlayerBall(player, ball)
  player._Ball = ball
  player:SetNWEntity("PlayerBall", ball)

  return ball
end

--- Gets the ball entity that the player deployed on a hole
---@param player Player
function Minigolf.GetPlayerBall(player)
  return player._Ball
end

playerMeta.SetPlayerBall = Minigolf.SetPlayerBall
playerMeta.GetPlayerBall = Minigolf.GetPlayerBall

--[[
  Getter and setter for the active hole this player is playing on
--]]
-- Set hole to nil when the player is done
function Minigolf.SetActiveHole(player, hole)
  player._ActiveHole = hole

  return hole
end

function Minigolf.GetActiveHole(player)
  return player._ActiveHole
end

playerMeta.SetActiveHole = Minigolf.SetActiveHole
playerMeta.GetActiveHole = Minigolf.GetActiveHole

--[[
  Getter and setters for the scores on holes
--]]
function Minigolf.ResetHoleScores(player)
  player._Holes = {}

  return player._Holes
end

function Minigolf.GetAllHoleScores(player)
  return player._Holes
end

---@param player Player The player to set the score for
---@param start Entity|string The hole entity or name of the hole to get the score for
---@param strokes number The amount of strokes to set for this hole
function Minigolf.SetHoleScore(player, start, strokes)
  local holeName = start

  if(type(start) ~= "string")then
    holeName = start:GetUniqueHoleName()
  end

  player._Holes[holeName] = strokes
  player:SetNWInt(holeName .. "Strokes", strokes)

  return strokes
end

---@param player Player The player to get the score for
---@param start Entity|string The hole entity or name of the hole to get the score for
function Minigolf.GetHoleScore(player, start)
  local holeName = start

  if(type(start) ~= "string")then
    holeName = start:GetUniqueHoleName()
  end

  return player._Holes[holeName]
end

playerMeta.ResetHoleScores = Minigolf.ResetHoleScores
playerMeta.GetAllHoleScores = Minigolf.GetAllHoleScores
playerMeta.SetHoleScore = Minigolf.SetHoleScore
playerMeta.GetHoleScore = Minigolf.GetHoleScore

--- Set whether the player is inputting force for the ball
---@param player Player
---@param ball Entity
function Minigolf.SetBallGivingForce(player, ball)
  player._BallGettingForce = ball

  return ball
end

--- Get whether the player is inputting force for the ball
---@param player Player
function Minigolf.GetBallGivingForce(player)
  return player._BallGettingForce
end

playerMeta.SetBallGivingForce = Minigolf.SetBallGivingForce
playerMeta.GetBallGivingForce = Minigolf.GetBallGivingForce

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
