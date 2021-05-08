util.AddNetworkString("Minigolf.ConfigMenu")

local playerLibrary = player

---@param player Player
hook.Add("PlayerInitialSpawn", "Minigolf.SetupHoleRegistration", function(player)
  -- Start with a HOLE_NOT_PLAYED on all holes
  Minigolf.Holes.ResetForPlayer(player)

  -- Network all teams with the late joiners (calls team.SetUp on the client)
  for teamID, team in pairs(Minigolf.Teams.All)do
    Minigolf.Teams.NetworkForGame(teamID, team.Name, team.Color)
  end

	-- Send the team info to the player joining for the first time
  Minigolf.Teams.NetworkAll(player)
end)

-- Let the RocketDodger Pointshop set the model
-- ---@param player Player
-- hook.Add("PlayerSetModel", "Minigolf.SetModelToOdessa", function(player)
-- 	player:SetModel("models/player/odessa.mdl")
-- end)

---@param player Player
---@param spawnpoint Entity
---@param makeSuitable boolean
hook.Add("IsSpawnpointSuitable", "Minigolf.AllowSpawningAnySpawnpoint", function(player, spawnpoint, makeSuitable)
	-- Any spawnpoint will do in this gamemode
	return true
end)

---@param listener Player
---@param talker Player
hook.Add("PlayerCanHearPlayersVoice", "Minigolf.LocalVoice", function(listener, talker)
	if(not listener:IsInDistanceOf(talker, 500))then
		-- Only hear nearby players
		return false, true
	end
end)

local deathSounds = {
	"vo/npc/male01/ow01.wav",
	"vo/npc/male01/ow02.wav",
	"vo/npc/male01/pain01.wav",
	"vo/npc/male01/pain02.wav",
	"vo/npc/male01/pain03.wav",
	"vo/npc/male01/pain04.wav",
	"vo/npc/male01/pain05.wav",
	"vo/npc/male01/pain06.wav",
	"vo/npc/male01/pain07.wav",
	"vo/npc/male01/pain08.wav",
	"vo/npc/male01/pain09.wav"
}

hook.Add("PlayerDeath", "Minigolf.PlayDeathSounds", function(victim, inflictor, attacker)
	if(not IsValid(victim))then
		return
	end

	victim:EmitSound(table.Random(deathSounds), nil, nil, nil, CHAN_VOICE)
end)

hook.Add("PlayerLoadout", "Minigolf.StripWeaponsOnSpawn", function(player)
	-- Give the only weapon that matters
	player:Give("golf_club")

	-- true: Prevents further default Loadout (also from addons)
	return true
end)

-- Always allow use of flashlight
hook.Add("PlayerSwitchFlashlight", "Minigolf.PlayerAllowSwitchFlashlight", function(player, enabled)
	return true
end)

-- Special hole messages, like hole in one
hook.Add("MinigolfGetGoalMessage", "Minigolf.CustomGoalMessagesForCertainStrokes", function(player, goal, strokes, start)
	local receivers = team.GetPlayers(player:Team())
	local par = start:GetPar()

	if(strokes == 0)then
		Minigolf.Messages.Send(receivers, player:Nick() .. " got an impossible run(0 strokes) at '" .. goal:GetHoleName() .. "'", "¡", TEXT_EFFECT_SPARKLE)
		player:PlaySound("vo/ravenholm/madlaugh04.wav")
		return false
	elseif(strokes == 1)then
		Minigolf.Messages.Send(playerLibrary.GetAll(), player:Nick() .. " got a HOLE IN ONE on '" .. goal:GetHoleName() .. "'", "@", TEXT_EFFECT_SPARKLE)
		player:PlaySound("vo/k_lab/kl_excellent.wav")
		return false
	elseif(strokes >= start:GetMaxStrokes())then
		Minigolf.Messages.Send(receivers, player:Nick() .. " struggled to get to the end of '" .. goal:GetHoleName() .. "' with " .. strokes .. " " .. Minigolf.Text.Pluralize("stroke", strokes) .."!", "~")
		player:PlaySound(string.format("vo/ravenholm/madlaugh0%d.wav", math.random(1,4)))
		return false
	end

	local underPar = par - strokes

	if(underPar == 0)then
		Minigolf.Messages.Send(receivers, "Par! ".. player:Nick() .. " got to '" .. goal:GetHoleName() .. "'")
		return false
	elseif(underPar == 1)then
		Minigolf.Messages.Send(receivers, "Birdie! ".. player:Nick() .. " got to '" .. goal:GetHoleName() .. "'")
		return false
	elseif(underPar == 2)then
		Minigolf.Messages.Send(receivers, "Eagle! ".. player:Nick() .. " got to '" .. goal:GetHoleName() .. "'")
		return false
	elseif(underPar == 2)then
		Minigolf.Messages.Send(receivers, "Eagle! ".. player:Nick() .. " got to '" .. goal:GetHoleName() .. "'")
		return false
	elseif(underPar == 2)then
		Minigolf.Messages.Send(receivers, "Condor! ".. player:Nick() .. " got to '" .. goal:GetHoleName() .. "'")
		return false
	end
end)

-- When time runs out
hook.Add("MinigolfTimeLimitReached", "Minigolf.OutOfTimeMessage", function(player, ball, start)
	Minigolf.Messages.Send(team.GetPlayers(player:Team()), "Disqualified! " .. player:Nick() .. " ran out of time on '" .. start:GetHoleName() .. "'", nil, TEXT_EFFECT_ATTENTION)
	
	player:PlaySound("vo/k_lab/kl_fiddlesticks.wav")
end)

hook.Add("MinigolfStrokeLimitReached", "Minigolf.StrokeLimitMessage", function(player, ball, start)
	Minigolf.Messages.Send(team.GetPlayers(player:Team()), "Disqualified! " .. player:Nick() .. " has ".. start:GetMaxStrokes() .." strokes on '" .. start:GetHoleName() .. "'", "¢", TEXT_EFFECT_ATTENTION)

	player:PlaySound("vo/k_lab/kl_fiddlesticks.wav")
end)

-- When a player hits a ball
hook.Add("MinigolfPlayerHitBall", "Minigolf.PlayerHitBallRecordPosition", function(player, ball)
	ball._LastHitPosition = ball:GetPos()
end)

-- When a minigolf ball goes out of bounds
hook.Add("MinigolfBallOutOfBounds", "Minigolf.OutOfBounds", function(player, ball, bound)
	local start = ball:GetStart()
	local trailTexture = "cable/redlaser"

	if(ball._IsGoingOOB)then
		return
	end

	ball._IsGoingOOB = true
	ball:SetRenderMode(RENDERMODE_TRANSALPHA)
	ball._OldColor = ball:GetColor()
	ball:SetColor(Color(255, 0, 0, 150))
	ball:SetUseable(false)

	-- Remove old trails
	local oldTrail;

	for _, child in pairs(ball:GetChildren()) do
		if(child:GetClass() == "env_spritetrail")then
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
		if(IsValid(trail))then
			SafeRemoveEntity(trail)
		end

		if(IsValid(ball))then
			ball:MoveToPos(ball._LastHitPosition or ball:GetStart():GetPos())
			ball:SetColor(ball._OldColor or Color(255,255,255, 255))
			ball:SetUseable(true)
			ball._IsGoingOOB = false

			if(IsValid(oldTrail))then
				oldTrail:SetRenderMode(RENDERMODE_NORMAL)
			end
		end
	end)

	Minigolf.Messages.Send(team.GetPlayers(player:Team()), player:Nick() .. " went out of bounds at '" .. start:GetHoleName() .. "'", "Ò")
end)

hook.Add("KeyPress", "Minigolf.AllowUseBall", function( player, key )
	if( key == IN_USE )then
		local tr = player:GetEyeTraceNoCursor()

		for _, ent in ipairs(ents.FindInSphere(tr.HitPos, 64))do
			if(IsValid(ent) and ent:GetClass() == "minigolf_ball")then
				ent:OnUse(player)
			end
		end
	end
end)

-- Set comfortable speeds & no collision between players
hook.Add("PlayerSpawn", "Minigolf.SetupSpeeds", function(player)
	player:SetWalkSpeed(120)
	player:SetRunSpeed(255)

	player:SetCollisionGroup(COLLISION_GROUP_PASSABLE_DOOR)
end)

hook.Add("PlayerShouldTakeDamage", "Minigolf.DontTakeDamage", function(player, attacker)
	return false
end)

hook.Add("PlayerSpawnObject", "Minigolf.DontSpawnAnything", function(player, model, skin)
	return false
end)

hook.Add("PlayerSpray", "Minigolf.DisablePlayerSpray", function(player)
	-- Return false to allow spraying, return true to prevent spraying.
	return true
end)

hook.Add("PlayerDeathSound", "Minigolf.MuteDeathSound", function(player)
	-- Return true to mute the death sound
	return true
end)

-- hook.Add("ShowHelp", "Minigolf.ShowConfigMenuOnF1", function(player)
-- 	net.Start("Minigolf.ConfigMenu")
-- 	net.Send(player)
-- end)