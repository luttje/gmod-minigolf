include("sh_init.lua")

--[[
	Commands
--]]
Minigolf.Commands.Register("team", function(player)
	net.Start("Minigolf.ShowGolfTeamMenu")
	net.WriteBool(false)
	net.Send(player)
end, "Show information about your Minigolf team, to change it, leave it and/or join another team")

Minigolf.Commands.Register("bet", function(player)
	player:ConCommand("menu_betting")
end, "Bet on upcoming players' performance")
