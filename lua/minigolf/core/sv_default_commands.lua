Minigolf.Commands.Register("unstuck", function(player)
  player:Kill()
end, "Kill your character to respawn and get unstuck")

Minigolf.Commands.Register("gmcredits", function(player)
	local creators = {
		"Luttje (Lead Dev & Mapper)", 
		"Elkinda (Mapper)", 
		"Tori (Idea Guy & Petite Dev)", 
		"Syff (Graphics & Web Dev)"
	}

	player:ChatPrint("This minigolf addon is open-source under the MIT License @ https://github.com/luttje/gmod-minigolf and was created by:")

  for _, creator in pairs(creators) do
		player:ChatPrint(string.format("   %s", creator))
	end
end, "Show information on this minigolf addon and who made it happen")

Minigolf.Commands.Register("help", function(player)
  Minigolf.Commands.ShowHelp(player)
end, "Lists all available commands")