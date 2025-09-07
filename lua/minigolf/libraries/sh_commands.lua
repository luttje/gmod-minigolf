Minigolf.Commands = Minigolf.Commands or {}
Minigolf.Commands.All = Minigolf.Commands.All or {}
Minigolf.Commands.Cache = Minigolf.Commands.Cache or {}

--- Add a command that the player can execute in the game chat.
---@param command string The command that the player types to execute a sequence of events
---@param callback fun(ply:Player, ...) The callback to be called when the player enters the command
---@param description string A description to inform the player what this command does (shown on /help)
---@return nil
function Minigolf.Commands.Register(command, callback, description)
	Minigolf.Commands.All[#Minigolf.Commands.All + 1] = {
		command = command,
		description = description,
		callback = callback
	}
	Minigolf.Commands.Cache[command] = callback
end

--- Returns all the commands and their information.
---@return table A table with each value being all information about a command. The key is decided based on order of registration with `Minigolf.Commands.Register`.
function Minigolf.Commands.GetAll()
	return Minigolf.Commands.All
end

--- Rapidly searches the cache for the callback belonging to a command
---@return fun(ply:Player, ...) The callback belonging with this command. It needs to be given a player object and optional parameters.
function Minigolf.Commands.GetCallback(command)
	local callback = Minigolf.Commands.Cache[command]

	return callback
end

--- Shows helpful information to a player in chat
---@param player Player|nil The player to show the help to (not needed client side)
function Minigolf.Commands.ShowHelp(player)
	local prefix = Minigolf.Convars.CommandPrefix:GetString()

	if (player == nil and CLIENT) then
		player = LocalPlayer()
	end

	player:ChatPrint("All Minigolf Commands:")

	for _, commandData in pairs(Minigolf.Commands.GetAll()) do
		player:ChatPrint(string.format("   %s%s: %s", prefix, commandData.command, commandData.description))
	end
end

--- Shows helpful information to a player in console
---@param player Player|nil The player to show the help to (not needed client side)
function Minigolf.Commands.ShowHelpConsole(player)
	local prefix = Minigolf.Convars.CommandPrefix:GetString()

	if (player == nil and CLIENT) then
		player = LocalPlayer()
	end

	player:PrintMessage(HUD_PRINTCONSOLE, "All Minigolf Commands:")

	for _, commandData in pairs(Minigolf.Commands.GetAll()) do
		player:PrintMessage(HUD_PRINTCONSOLE,
			string.format("   %s%s: %s", prefix, commandData.command, commandData.description))
	end
end
