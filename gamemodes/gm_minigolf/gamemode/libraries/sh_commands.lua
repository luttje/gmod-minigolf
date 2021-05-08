Minigolf.Commands = {}
Minigolf.Commands.Prefix = "/"

local commands = {}
local commandsCache = {}

--- Add a command that the player can execute in the game chat.
---@param command string The command that the player types to execute a sequence of events
---@param callback fun(ply:Player, ...) The callback to be called when the player enters the command
---@param description string A description to inform the player what this command does (shown on /help)
---@return nil
function Minigolf.Commands.Register(command, callback, description)
  commands[#commands + 1] = { 
    command = command,
    description = description,
    callback = callback
  }
  commandsCache[command] = callback
end

--- Returns all the commands and their information.
---@return table A table with each value being all information about a command. The key is decided based on order of registration with `Minigolf.Commands.Register`.
function Minigolf.Commands.GetAll()
  return commands
end

--- Rapidly searches the cache for the callback belonging to a command
---@return fun(ply:Player, ...) The callback belonging with this command. It needs to be given a player object and optional parameters.
function Minigolf.Commands.GetCallback(command)
  local callback = commandsCache[command]

  return callback
end