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
