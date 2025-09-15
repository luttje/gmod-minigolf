hook.Add("PlayerSay", "Minigolf.ProcessCommands", function(player, text)
	text = string.Trim(text)

	local prefix = Minigolf.Convars.CommandPrefix:GetString()
	local prefixLength = string.len(prefix)

	if (string.sub(text, 1, prefixLength) ~= prefix) then
		return
	end

	local firstSpace = string.find(text, " ", prefixLength + 1, true)
	local command = string.Trim(string.sub(text, prefixLength + 1, firstSpace))
	local callback = Minigolf.Commands.GetCallback(command)

	if (not callback) then
		-- If command doesn't exist, do nothing instead of blocking potential other addons with the same prefix
		return
	end

	local arguments = {}

	if (firstSpace) then
		local argumentsStart = string.Trim(string.sub(text, firstSpace))

		arguments = string.Explode(" ", argumentsStart)
	end

	callback(player, unpack(arguments))

	return ""
end)
