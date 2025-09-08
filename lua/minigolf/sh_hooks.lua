hook.Add("ShouldCollide", "Minigolf.StopPlayerCollisionWithBalls", function(ent1, ent2)
	if (not IsValid(ent1) or not IsValid(ent2)) then
		return
	end

	local isEnt1Ball = ent1:GetClass() == "minigolf_ball"
	local isEnt2Ball = ent2:GetClass() == "minigolf_ball"

	local mayEnt1CollideBallsExclusive = ent1:GetMinigolfData("CollideRule") == "only_balls"
	local mayEnt2CollideBallsExclusive = ent2:GetMinigolfData("CollideRule") == "only_balls"
	local mayEnt1CollideOthersExclusive = ent1:GetMinigolfData("CollideRule") == "only_others"
	local mayEnt2CollideOthersExclusive = ent2:GetMinigolfData("CollideRule") == "only_others"
	local mayEnt1CollideOthers = mayEnt1CollideOthersExclusive or
		ent1:GetMinigolfData("CollideRule") == "balls_and_others"
	local mayEnt2CollideOthers = mayEnt2CollideOthersExclusive or
		ent2:GetMinigolfData("CollideRule") == "balls_and_others"

	if ((mayEnt1CollideOthersExclusive and not mayEnt2CollideOthers)
			or (mayEnt2CollideOthersExclusive and not mayEnt1CollideOthers)) then
		-- Collide with other entities only
		return false
	end

	if ((mayEnt1CollideBallsExclusive or mayEnt2CollideBallsExclusive)
			and not ((mayEnt1CollideBallsExclusive and isEnt2Ball)
				or (mayEnt2CollideBallsExclusive and isEnt1Ball))) then
		-- Collide only with minigolf balls
		return false
	end

	if ((mayEnt1CollideOthers or mayEnt2CollideOthers)
			and not ((mayEnt1CollideOthers and (isEnt2Ball or mayEnt2CollideOthers))
				or (mayEnt2CollideOthers and (isEnt1Ball or mayEnt1CollideOthers)))) then
		-- Collide with other entities and balls only
		return false
	end

	if (isEnt1Ball or isEnt2Ball) then
		-- If they're both balls, let them collide if they're both in collide mode
		if (isEnt1Ball and isEnt2Ball) then
			local ball1Collide = ent1:GetNWBool("MinigolfBallsCollide", false)
			local ball2Collide = ent2:GetNWBool("MinigolfBallsCollide", false)

			return ball1Collide and ball2Collide
		end

		-- Don't let players interfere with balls, also not through props or their own bodies
		return false
	end

	-- After this we only check if a player is one of the colliders
	if (not (ent1:IsPlayer() or ent2:IsPlayer())) then
		return
	end

	-- Ensure players don't interact with objects part of a minigolf course
	if (ent1:GetMinigolfData("CollideRule") == "except_players"
			or ent2:GetMinigolfData("CollideRule") == "except_players") then
		return false
	end

	print("No special collide rules, allow collision")
end)

hook.Add("EntityKeyValue", "Minigolf.MarkEntitiesWithCollideRules", function(ent, key, value)
	if (key:lower() == "minigolfcollide") then
		ent:SetMinigolfData("CollideRule", value:lower())
	end
end)
