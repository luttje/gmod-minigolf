local playerLibrary = player

---@param player Player
hook.Add("PlayerInitialSpawn", "Minigolf.NetworkTeams", function(player)
  -- Network all teams with the late joiners (calls team.SetUp on the client)
  for teamID, team in pairs(Minigolf.Teams.All)do
    Minigolf.Teams.NetworkForGame(teamID, team.Name, team.Color)
  end

	-- Send the team info to the player joining for the first time
  Minigolf.Teams.NetworkAll(player)
end)

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
hook.Add("Minigolf.GetGoalMessage", "Minigolf.CustomGoalMessagesForCertainStrokes", function(player, goal, strokes, start)
	local receivers = Minigolf.Teams.GetOtherPlayersOnTeam(player)
	local par = start:GetPar()

	if(strokes == 0)then
		Minigolf.Messages.Send(receivers, player:Nick() .. " got an impossible run(0 strokes) at '" .. goal:GetHoleName() .. "'", "¡", Minigolf.TEXT_EFFECT_SPARKLE)
		player:PlaySound("vo/ravenholm/madlaugh04.wav")
		return
	elseif(strokes == 1)then
		Minigolf.Messages.Send(playerLibrary.GetAll(), player:Nick() .. " got a HOLE IN ONE on '" .. goal:GetHoleName() .. "'", "@", Minigolf.TEXT_EFFECT_SPARKLE)
		player:PlaySound("vo/k_lab/kl_excellent.wav")
		return
	elseif(strokes >= start:GetMaxStrokes())then
		Minigolf.Messages.Send(receivers, player:Nick() .. " struggled to get to the end of '" .. goal:GetHoleName() .. "' with " .. strokes .. " " .. Minigolf.Text.Pluralize("stroke", strokes) .."!", "~")
		player:PlaySound(string.format("vo/ravenholm/madlaugh0%d.wav", math.random(1,4)))
		return
	end

	local underPar = par - strokes

	if(underPar == 0)then
		Minigolf.Messages.Send(receivers, "Par! ".. player:Nick() .. " got to '" .. goal:GetHoleName() .. "'")
		return
	elseif(underPar == 1)then
		Minigolf.Messages.Send(receivers, "Birdie! ".. player:Nick() .. " got to '" .. goal:GetHoleName() .. "'")
		return
	elseif(underPar == 2)then
		Minigolf.Messages.Send(receivers, "Eagle! ".. player:Nick() .. " got to '" .. goal:GetHoleName() .. "'")
		return
	elseif(underPar == 2)then
		Minigolf.Messages.Send(receivers, "Eagle! ".. player:Nick() .. " got to '" .. goal:GetHoleName() .. "'")
		return
	elseif(underPar == 2)then
		Minigolf.Messages.Send(receivers, "Condor! ".. player:Nick() .. " got to '" .. goal:GetHoleName() .. "'")
		return
	end
end)

-- When time runs out
hook.Add("Minigolf.TimeLimitReached", "Minigolf.OutOfTimeMessage", function(player, ball, start)
	Minigolf.Messages.Send(Minigolf.Teams.GetOtherPlayersOnTeam(player), "Disqualified! " .. player:Nick() .. " ran out of time on '" .. start:GetHoleName() .. "'", nil, Minigolf.TEXT_EFFECT_ATTENTION)
end)

hook.Add("Minigolf.StrokeLimitReached", "Minigolf.StrokeLimitMessage", function(player, ball, start)
	Minigolf.Messages.Send(Minigolf.Teams.GetOtherPlayersOnTeam(player), "Disqualified! " .. player:Nick() .. " has ".. start:GetMaxStrokes() .." strokes on '" .. start:GetHoleName() .. "'", "¢", Minigolf.TEXT_EFFECT_ATTENTION)
end)

-- When a player hits a ball
hook.Add("Minigolf.PlayerHitBall", "Minigolf.PlayerHitBallRecordPosition", function(player, ball)
	ball._LastHitPosition = ball:GetPos()
end)

-- When a minigolf ball goes out of bounds
hook.Add("Minigolf.BallOutOfBounds", "Minigolf.OutOfBoundsMessage", function(player, ball, bound)
	if(ball._IsGettingOOBMessage)then
		return
	end

	ball._IsGettingOOBMessage = true
	local start = ball:GetStart()

	Minigolf.Messages.Send(Minigolf.Teams.GetOtherPlayersOnTeam(player), player:Nick() .. " went out of bounds at '" .. start:GetHoleName() .. "'", "Ò")
end)

hook.Add("Minigolf.PlayerGivesUp", "Minigolf.PlayerGivesUpMessage", function(player, start)
	Minigolf.Messages.Send(Minigolf.Teams.GetOtherPlayersOnTeam(player), player:Nick() .. " gave up!", nil, Minigolf.TEXT_EFFECT_DANGER)
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
