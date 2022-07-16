hook.Add("ShouldCollide", "Minigolf.StopPlayerCollisionWithBalls", function(ent1, ent2)
	if(not IsValid(ent1) or not IsValid(ent2))then
		return
	end

	local isEnt1Ball = ent1:GetClass() == "minigolf_ball"
	local isEnt2Ball = ent2:GetClass() == "minigolf_ball"

	local mayEnt1CollideBalls = ent1._MinigolfCollide == "only_balls" or ent1._MinigolfCollide == "balls_and_others"
	local mayEnt2CollideBalls = ent2._MinigolfCollide == "only_balls" or ent2._MinigolfCollide == "balls_and_others"
	local mayEnt1CollideOthers = ent1._MinigolfCollide == "only_others" or ent1._MinigolfCollide == "balls_and_others"
	local mayEnt2CollideOthers = ent2._MinigolfCollide == "only_others" or ent2._MinigolfCollide == "balls_and_others"

	if((mayEnt1CollideBalls and not isEnt2Ball)
	or mayEnt2CollideBalls and not isEnt1Ball)then
		-- Collide only with minigolf balls
		return false
	end

	if((mayEnt1CollideOthers or mayEnt2CollideOthers) 
	and (mayEnt1CollideOthers ~= mayEnt2CollideOthers))then
		-- Collide only with other entities that have `only_others` or `balls_and_others`
		return false
	end

	-- After this we only check if a player is one of the colliders
	if(not (ent1:IsPlayer() or ent2:IsPlayer()))then
		return
	end

	if(isEnt1Ball or isEnt2Ball) then 
		-- Don't let players interfere with balls
		return false
	end

	-- Ensure players don't interact with objects part of a minigolf course
	if(ent1._MinigolfCollide == "except_players" 
	or ent2._MinigolfCollide == "except_players") then 
		return false
	end
end)

hook.Add("EntityKeyValue", "Minigolf.MarkEntitiesWithCollideRules", function(ent, key, value)
	if(key == "minigolf_collide")then
		ent._MinigolfCollide = value:lower()
	end
end)