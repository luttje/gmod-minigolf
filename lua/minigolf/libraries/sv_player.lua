util.AddNetworkString("Minigolf.PlaySound")

Minigolf.Player = Minigolf.Player or {}

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

--- Sets the ball entity that the player deployed on a hole
--- Set ball to nil when it's removed
---@param player Player
---@param ball Entity
function Minigolf.Player.SetBall(player, ball)
  player._Ball = ball
  player:SetNWEntity("PlayerBall", ball)

  return ball
end

--- Gets the ball entity that the player deployed on a hole
---@param player Player
function Minigolf.Player.GetBall(player)
  return player._Ball
end

playerMeta.SetPlayerBall = Minigolf.Player.SetBall
playerMeta.GetMinigolfBall = Minigolf.Player.GetBall

--[[
  Getter and setter for the active hole this player is playing on
--]]
-- Set hole to nil when the player is done
function Minigolf.Player.SetActiveHole(player, hole)
  player._ActiveHole = hole
  player:SetNWEntity("Minigolf.ActiveHole", hole ~= nil and hole or NULL)

  return hole
end

function Minigolf.Player.GetActiveHole(player)
  return player._ActiveHole
end

playerMeta.SetActiveHole = Minigolf.Player.SetActiveHole
playerMeta.GetActiveHole = Minigolf.Player.GetActiveHole

--[[
  Getter and setters for the scores on holes
--]]
function Minigolf.Player.ResetHoleScores(player)
  player._Holes = {}
  player._AllowedRetries = {}

  return player._Holes
end

function Minigolf.Player.GetAllHoleScores(player)
  return player._Holes
end

---@param player Player The player to set the score for
---@param start Entity|string The hole entity or name of the hole to get the score for
---@param strokes number The amount of strokes to set for this hole
function Minigolf.Player.SetHoleScore(player, start, strokes)
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
function Minigolf.Player.GetHoleScore(player, start)
  local holeName = start

  if(type(start) ~= "string")then
    holeName = start:GetUniqueHoleName()
  end

  return player._Holes[holeName]
end

playerMeta.ResetHoleScores = Minigolf.Player.ResetHoleScores
playerMeta.GetAllHoleScores = Minigolf.Player.GetAllHoleScores
playerMeta.SetHoleScore = Minigolf.Player.SetHoleScore
playerMeta.GetHoleScore = Minigolf.Player.GetHoleScore

--- Set whether the player is inputting force for the ball
---@param player Player
---@param ball Entity
function Minigolf.Player.SetBallGivingForce(player, ball)
  player._BallGettingForce = ball

  return ball
end

--- Get whether the player is inputting force for the ball
---@param player Player
function Minigolf.Player.GetBallGivingForce(player)
  return player._BallGettingForce
end

playerMeta.SetBallGivingForce = Minigolf.Player.SetBallGivingForce
playerMeta.GetBallGivingForce = Minigolf.Player.GetBallGivingForce

--- Set the amount of retries a player has left on this hole
---@param player Player
---@param start Entity|string The hole entity or name of the hole to get the score for
---@param retries number The amount of retries to set for this hole
function Minigolf.Player.SetAllowedRetries(player, start, retries)
  local holeName = start

  if(type(start) ~= "string")then
    holeName = start:GetUniqueHoleName()
  end

  player._AllowedRetries[holeName] = retries

  return retries
end

--- Get the amount of retries a player has left on this hole
---@param player Player
---@param start Entity|string The hole entity or name of the hole to get the score for
---@return number The amount of retries left for this hole
function Minigolf.Player.GetAllowedRetries(player, start)
  local holeName = start

  if(type(start) ~= "string")then
    holeName = start:GetUniqueHoleName()
  end

  return player._AllowedRetries[holeName]
end

playerMeta.SetAllowedRetries = Minigolf.Player.SetAllowedRetries
playerMeta.GetAllowedRetries = Minigolf.Player.GetAllowedRetries