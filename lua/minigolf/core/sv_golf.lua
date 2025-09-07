gameevent.Listen("player_disconnect")
hook.Add("player_disconnect", "Minigolf.ActivePlayerLeavesResetHole", function(data)
  local start, ball = Minigolf.Holes.GetStartByNetworkID(data.networkid)

  if (IsValid(start)) then
    Minigolf.Holes.End(nil, ball, start)
  end
end)

hook.Add("Minigolf.BallRolledStationary", "Minigolf.BallRolledStationaryCheckStrokes", function(ball)
  local start = ball:GetStart()

  if (not IsValid(start)) then
    -- Can happen if the track was dynamic and the start was removed
    ball:Remove()
    return
  end

  local maxStrokes = start:GetMaxStrokes()
  local strokes = ball:GetStrokes()

  if (strokes < maxStrokes) then
    return
  end

  if (ball._IsMarkedForRemoval) then
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
  local ball = player:GetMinigolfBall()

  if (IsValid(ball)) then
    AddOriginToPVS(ball:GetPos())
  end
end)

hook.Add("Minigolf.CanStartPlaying", "Minigolf.DontAllowAlreadyPlayed", function(player, start)
  local retriesLeft = player:GetAllowedRetries(start)

  if (retriesLeft == nil or retriesLeft == -1) then
    return
  end

  if (retriesLeft <= 0) then
    Minigolf.Messages.Send(player, "You can not retry this hole!", "Ã")

    return false
  end
end)

hook.Add("Minigolf.PlayerFinishedHole", "Minigolf.ClearTimeLimit", function(player, ball, start, strokes)
  if (not IsValid(player)) then
    -- The player finished because they disconnected
    return
  end

  local holeName = start:GetUniqueHoleName()

  -- Remove the play timelimit timer
  timer.Remove((player:AccountID() or player:UserID()) .. holeName .. "TimeLimit")
end)

hook.Add("Minigolf.PlayerFinishedHole", "Minigolf.ResetHolesForFinishedPlayers", function(player, ball, start, strokes)
  if (not IsValid(player)) then
    -- The player finished because they disconnected
    return
  end

  local holeCount = 0

  for holeName, holeScore in pairs(player:GetAllHoleScores()) do
    if (holeScore ~= Minigolf.HOLE_NOT_PLAYED) then
      holeCount = holeCount + 1
    end
  end

  if (holeCount == Minigolf.Holes.TotalCount) then
    hook.Call("Minigolf.PlayerFinishedAllHoles", Minigolf.GM(), player, start)
  end
end)

hook.Add("Minigolf.PlayerFinishedAllHoles", "Minigolf.ResetWhenPlayerFinishedAllHoles", function(player, lastHole)
  Minigolf.Holes.ResetForPlayer(player)
  Minigolf.Messages.Send(nil, player:Nick() .. " has finished all the holes!")
end)
