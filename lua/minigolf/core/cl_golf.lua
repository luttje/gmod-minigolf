-- Called to inform the player has stopped playing a hole
net.Receive("Minigolf.PlayerHasFinished", function()
	local player = net.ReadEntity()
	local start = net.ReadEntity()
	local strokes = net.ReadUInt(32)

	if(not IsValid(start) or not IsValid(player))then
		-- Ignore data about players or holes we can't see
		return
	end

	if(not start._Strokes)then
		start._Strokes = {}
	end

	start._Strokes[player] = strokes

	hook.Call("Minigolf.PlayerFinished", Minigolf.GM(), player, start, strokes)
end)
