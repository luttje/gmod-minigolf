gameevent.Listen( "player_disconnect" )
hook.Add("player_disconnect", "Minigolf.ActivePlayerLeavesResetHole", function(data)
	local start, ball = Minigolf.Holes.GetStartByNetworkID(data.networkid)

	if(IsValid(start))then
		Minigolf.Holes.End(nil, ball, start)
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

hook.Add("Minigolf.PlayerFinishedHole", "Minigolf.ClearTimeLimit", function(player, ball, start, strokes)
	local holeName = start:GetUniqueHoleName()

	-- The player may have left our team waiting
	if(IsValid(player))then
		-- Remove the play timelimit timer
		timer.Remove((player:AccountID() or player:UserID()) .. holeName .. "TimeLimit")
	end
end)

hook.Add("Minigolf.PlayerFinishedHole", "Minigolf.ResetHolesForFinishedPlayers", function(player, ball, start, strokes)
	local holeCount = 0

	for holeName, holeScore in pairs(player:GetAllHoleScores()) do
		if(holeScore ~= Minigolf.HOLE_NOT_PLAYED)then
			holeCount = holeCount + 1
		end
	end

  if(holeCount == Minigolf.Holes.TotalCount)then
	  hook.Call("Minigolf.PlayerFinishedAllHoles", Minigolf.GM(), player, start)
	end
end)

hook.Add("Minigolf.PlayerFinishedAllHoles", "Minigolf.ResetWhenPlayerFinishedAllHoles", function(player, lastHole)
	Minigolf.Holes.ResetForPlayer(player)
	Minigolf.Messages.Send(nil, player:Nick() .. " has finished all the holes!")
end)