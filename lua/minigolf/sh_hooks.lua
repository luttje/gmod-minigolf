hook.Add("ShouldCollide", "Minigolf.StopPlayerCollisionWithBalls", function(ent1, ent2)
	if(not IsValid(ent1) or not IsValid(ent2))then
		return
	end

	if(not (ent1:IsPlayer() or ent2:IsPlayer()))then
		return
	end

	-- Ensure that players don't collide with balls
	if(ent1:GetClass() == "minigolf_ball" or ent2:GetClass() == "minigolf_ball") then 
		return false
	end

	-- Ensure players don't interact with physics objects on the minigolf course
	-- TODO: Make configurable for server admin or more precicely check if a func_physbox is part of the track (perhaps with a KeyValue)
	if(ent1:GetClass() == "func_physbox" or ent2:GetClass() == "func_physbox") then 
		return false
	end
end)
