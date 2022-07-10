hook.Add("PlayerDisconnected", "Minigolf.ActivePlayerLeavesResetHole", function(player)
	local ball = player:GetPlayerBall()

	if(IsValid(player) and IsValid(ball))then
		local start = ball:GetStart()
		Minigolf.Holes.End(player, ball, start)
	end
end)

hook.Add("Minigolf.BallRolledStationary", "Minigolf.BallRolledStationaryCheckStrokes", function(ball)
	local start = ball:GetStart()
  local maxStrokes = start:GetMaxStrokes()
  local strokes = ball:GetStrokes()

	if(strokes < maxStrokes)then
		return
	end
	
	if(ball._IsMarkedForRemoval)then
		return
	end

	local player = ball:GetPlayer()

	ball._IsMarkedForRemoval = true
	ball:SetRenderMode(RENDERMODE_TRANSALPHA)
	ball:SetColor(Color(255, 0, 0, 150))
	ball:SetUseable(false)

	timer.Simple(1.5, function()      
		hook.Call("Minigolf.StrokeLimitReached", Minigolf.GM(), player, ball, start)
		
		Minigolf.Holes.End(player, ball, start)

		ball:Remove()
	end)
end)

-- Ensures the players' ball decides what they can see
hook.Add("SetupPlayerVisibility", "Minigolf.SyncPlayerPVSWithBall", function(player, viewEntity)
	local ball = player:GetPlayerBall()

	if (IsValid(ball)) then
		AddOriginToPVS(ball:GetPos())
	end
end)

hook.Add("Minigolf.CanStartPlaying", "Minigolf.DontAllowAlreadyPlayed", function(player, start)
	-- Don't allow replays of a hole
	-- TODO: Make configurable by admin to allow replays
	local holeStrokes = player:GetHoleScore(start)

	if(holeStrokes == Minigolf.HOLE_DISQUALIFIED)then
		Minigolf.Messages.Send(player, "You already played this hole and got disqualified on it")

		return false
	elseif(holeStrokes > Minigolf.HOLE_NOT_PLAYED)then
		Minigolf.Messages.Send(player, "You already played this hole and got " .. holeStrokes .. " " .. Minigolf.Text.Pluralize("stroke", holeStrokes) .. " on it")

		return false
	end
end)
