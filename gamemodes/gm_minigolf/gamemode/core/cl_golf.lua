local finishSounds = {
	"physics/cardboard/cardboard_cup_impact_hard3.wav",
	"physics/cardboard/cardboard_cup_impact_hard2.wav",
	"physics/cardboard/cardboard_cup_impact_hard1.wav"
}

-- Called to inform the player has stopped playing a hole
net.Receive("Minigolf.PlayerHasFinished", function()
	local player = net.ReadEntity()
	local start = net.ReadEntity()
	local strokes = net.ReadUInt(32)

	if(not IsValid(start) or not IsValid(player))then
		-- Ignore data about players or holes we can't see
		-- TODO: Check if we even need to Broadcast this to everyone, or just team players.
		return
	end

	player._LimitTimeLeft = nil

	if(not start._Strokes)then
		start._Strokes = {}
	end

	start._Strokes[player] = strokes

	-- If it's a teammate, then player the end sound
	if(player:Team() == LocalPlayer():Team())then
		surface.PlaySound(table.Random(finishSounds))
	end
end)

-- Called to inform a team to swap players
net.Receive("Minigolf.SetSwapTimeLimit", function()
	local start = net.ReadEntity() -- Note: could be null for players far away
	local timeLimit = net.ReadUInt(32)

	LocalPlayer()._LimitTimeLeftForSwap = true
	LocalPlayer()._LimitTimeLeft = UnPredictedCurTime() + timeLimit
end)

-- Called to inform of the owner of a ball
net.Receive("Minigolf.SetPlayerTimeLimit", function()
	local owner = net.ReadEntity()
	local timeLimit = net.ReadUInt(32)

	LocalPlayer()._LimitTimeLeftForSwap = false

	if(not IsValid(owner))then
		-- Ignore data about players we can't see
		return
	end

	owner._LimitTimeLeft = UnPredictedCurTime() + timeLimit
end)

-- Called to inform swapping has occurred
net.Receive("Minigolf.EndSwapTimeLimit", function()
	local start = net.ReadEntity() -- Note: could be null for players far away
	
	LocalPlayer()._LimitTimeLeftForSwap = false
	LocalPlayer()._LimitTimeLeft = nil
end)

