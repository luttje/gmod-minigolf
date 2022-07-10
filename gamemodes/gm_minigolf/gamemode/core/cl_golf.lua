local finishSounds = {
	"physics/cardboard/cardboard_cup_impact_hard3.wav",
	"physics/cardboard/cardboard_cup_impact_hard2.wav",
	"physics/cardboard/cardboard_cup_impact_hard1.wav"
}

hook.Add("Minigolf.PlayerFinished", "Minigolf.PlayerFinished", function(player, start, strokes)
	player._LimitTimeLeft = nil

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

