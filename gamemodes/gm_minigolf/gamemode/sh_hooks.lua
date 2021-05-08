-- Ensure that players don't collide with balls
hook.Add("ShouldCollide", "Minigolf.StopPlayerCollisionWithBalls", function(ent1, ent2)
	if(not IsValid(ent1) or not IsValid(ent2))then
		return
	end

	if(not (ent1:IsPlayer() or ent2:IsPlayer()))then
		return
	end

	if(ent1:GetClass() == "minigolf_ball" or ent2:GetClass() == "minigolf_ball") then 
		return false
	end

	if(ent1:GetClass() == "func_physbox" or ent2:GetClass() == "func_physbox") then 
		return false
	end
end)

hook.Add("CanProperty", "Minigolf.DisablePropertyEditting", function(player, property, ent)
	return false
end)

hook.Add("CanTool", "Minigolf.DisableTool", function(player, tr, tool)
	return false
end)

hook.Add("PlayerFootstep", "Minigolf.DisableFootsteps", function(player, pos, foot, soundName, volume, rf)
	player:EmitSound(soundName, 40, 100, volume * .3, CHAN_BODY) -- TODO: Tori, Elkinda will want this configurable through the config menu :)
	return true
end)