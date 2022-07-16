local finishSounds = {
	"physics/cardboard/cardboard_cup_impact_hard3.wav",
	"physics/cardboard/cardboard_cup_impact_hard2.wav",
	"physics/cardboard/cardboard_cup_impact_hard1.wav"
}

hook.Add("Minigolf.PlayerFinished", "Minigolf.PlayerFinished", function(player, start, strokes)
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

-- Called to inform swapping has occurred
net.Receive("Minigolf.EndSwapTimeLimit", function()
	local start = net.ReadEntity() -- Note: could be null for players far away
	
	LocalPlayer()._LimitTimeLeftForSwap = false
	LocalPlayer()._LimitTimeLeft = nil
end)

hook.Add("Minigolf.PlayerTimeLimit", "Minigolf.ClearTimeLimitForSwapOnTimeLimit", function(owner, timeLimit)
	LocalPlayer()._LimitTimeLeftForSwap = false
end)