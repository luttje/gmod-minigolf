hook.Add("CanProperty", "Minigolf.DisablePropertyEditting", function(player, property, ent)
	return false
end)

hook.Add("CanTool", "Minigolf.DisableTool", function(player, tr, tool)
	return false
end)

hook.Add("PlayerFootstep", "Minigolf.DisableFootsteps", function(player, pos, foot, soundName, volume, rf)
	player:EmitSound(soundName, 40, 100, volume * .3, CHAN_BODY) -- TODO: We will want this configurable through the config menu
	return true
end)

hook.Add("CreateTeams", "Minigolf.CreateTeams", function()
	-- Create the no-team team
	TEAM_MINIGOLF_SPECTATORS = TEAM_MINIGOLF_SPECTATORS or Minigolf.Teams.Update(nil, "Spectators", Color(193, 180, 180))
end)
