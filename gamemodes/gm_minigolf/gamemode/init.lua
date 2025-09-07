include("sh_init.lua")

--[[
	Commands
--]]

Minigolf.Commands.Register("team", function(player)
	net.Start("Minigolf.ShowGolfTeamMenu")
	net.WriteBool(false)
	net.Send(player)
end, "Show information about your Minigolf team, to change it, leave it and/or join another team")
