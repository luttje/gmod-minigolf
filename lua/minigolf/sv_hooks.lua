local playerLibrary = player

---@param player Player
hook.Add("PlayerInitialSpawn", "Minigolf.SetupHoleRegistration", function(player)
	Minigolf.Commands.ShowHelpConsole(player)

	-- Start with a Minigolf.HOLE_NOT_PLAYED on all holes
	Minigolf.Holes.ResetForPlayer(player)

	player:SetNWBool("Minigolf.AutoPowerMode", Minigolf.Convars.DefaultAutoPowerMode:GetBool())
end)

-- When time runs out
hook.Add("Minigolf.TimeLimitReached", "Minigolf.OutOfTimeMessage", function(player, ball, start)
	Minigolf.Messages.Send(player, "Disqualified! You ran out of time on '" .. start:GetHoleName() .. "'", nil,
		Minigolf.TEXT_EFFECT_ATTENTION)

	player:PlaySound("vo/k_lab/kl_fiddlesticks.wav")
end)

hook.Add("Minigolf.StrokeLimitReached", "Minigolf.StrokeLimitMessage", function(player, ball, start)
	Minigolf.Messages.Send(player,
		"Disqualified! You have " .. start:GetMaxStrokes() .. " strokes on '" .. start:GetHoleName() .. "'", "¢",
		Minigolf.TEXT_EFFECT_ATTENTION)

	player:PlaySound("vo/k_lab/kl_fiddlesticks.wav")
end)

-- When a player hits a ball
hook.Add("Minigolf.PlayerHitBall", "Minigolf.PlayerHitBallRecordPosition", function(player, ball)
	ball._LastHitPosition = ball:GetPos()
end)

-- When a minigolf ball goes out of bounds
hook.Add("Minigolf.BallOutOfBounds", "Minigolf.OutOfBounds", function(player, ball, bound)
	local start = ball:GetStart()
	local trailTexture = "cable/redlaser"

	if (ball._IsGoingOOB) then
		return
	end

	ball._IsGoingOOB = true
	ball:SetRenderMode(RENDERMODE_TRANSALPHA)
	ball._OldColor = ball:GetColor()
	ball:SetColor(Color(255, 0, 0, 150))
	ball:SetUseable(false)

	-- Remove old trails
	local oldTrail

	for _, child in pairs(ball:GetChildren()) do
		if (child:GetClass() == "env_spritetrail") then
			oldTrail = child
			oldTrail:SetRenderMode(RENDERMODE_NONE)
			break
		end
	end

	-- Use equipped trail
	if IsValid(oldTrail) then
		trailTexture = oldTrail:GetModel()
	end

	local trail = util.SpriteTrail(ball, 0, Color(255, 0, 0), false, 15, 20, 1, 0.5, trailTexture)

	timer.Simple(1.5, function()
		if (IsValid(trail)) then
			SafeRemoveEntity(trail)
		end

		if (IsValid(ball)) then
			ball:MoveToPos(ball._LastHitPosition or ball:GetStart():GetPos())
			ball:SetColor(ball._OldColor or Color(255, 255, 255, 255))
			ball:SetUseable(true)
			ball._IsGoingOOB = false

			if (IsValid(oldTrail)) then
				oldTrail:SetRenderMode(RENDERMODE_NORMAL)
			end
		end
	end)

	Minigolf.Messages.Send(player, "You went out of bounds at '" .. start:GetHoleName() .. "'", "Ò")
end)

hook.Add("KeyPress", "Minigolf.AllowUseBall", function(player, key)
	if (key == IN_USE) then
		local tr = player:GetEyeTraceNoCursor()

		for _, ent in ipairs(ents.FindInSphere(tr.HitPos, 64)) do
			if (IsValid(ent) and ent:GetClass() == "minigolf_ball") then
				ent:OnUse(player)
			end
		end
	end
end)

hook.Add("Minigolf.BallStartedGivingForce", "Minigolf.ShowBallForceToTeam", function(player, ball)
	for _, teamPlayer in pairs(team.GetPlayers(player:Team())) do
		-- Delay this until we know for sure the ball has been created clientside
		teamPlayer:OnEntityExists(ball, function(teamPlayer, entity)
			net.Start("Minigolf.GetBallForce")
			net.WriteEntity(player)
			net.WriteEntity(entity)
			net.Send(teamPlayer)
		end)
	end
end)

hook.Add("Minigolf.BallStoppedGivingForce", "Minigolf.HideBallForceToTeam", function(player, ball)
	net.Start("Minigolf.GetBallForceCancel")
	net.WriteEntity(player)
	net.Send(team.GetPlayers(player:Team()))
end)
