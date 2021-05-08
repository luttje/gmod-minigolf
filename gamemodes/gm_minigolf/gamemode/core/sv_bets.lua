-- concommand.Add("bet_place", function(player, cmd, args)
-- 	local targetPlayer = player.GetByAccountID(args[1])
-- 	local betAmount = tonumber(args[2])
-- 	local expectedScore = tonumber(args[3])
-- 	local targetHole = Minigolf.Holes.All[args[4]] -- Wont work since now contains course name as well
-- 	local activeHole = player:GetActiveHole()

-- 	if(not targetPlayer)then
-- 		Minigolf.Messages.Send(player, "You have not selected a valid player!", nil, TEXT_EFFECT_DANGER)
-- 		return
-- 	end

-- 	if(not betAmount)then
-- 		Minigolf.Messages.Send(player, "You have not given a valid amount!", nil, TEXT_EFFECT_DANGER)
-- 		return
-- 	end

-- 	if(not player:PS_HasPoints(betAmount))then
-- 		Minigolf.Messages.Send(player, "You do not have this many points!", nil, TEXT_EFFECT_DANGER)
-- 		return
-- 	end

-- 	if(not targetHole)then
-- 		Minigolf.Messages.Send(player, "You have not selected a valid hole!", nil, TEXT_EFFECT_DANGER)
-- 		return
-- 	end

-- 	if(activeHole == targetHole)then
-- 		Minigolf.Messages.Send(player, "You can not place a bet when the player is already playing the hole!", nil, TEXT_EFFECT_DANGER)
-- 		return
-- 	end

-- 	if(player == targetPlayer)then
-- 		local lowestStrokes = Minigolf.Bets.GetLowestStrokesOn(targetPlayer, targetHole)

-- 		-- Check if someone has bet on a higher stroke score than the player themselves don't allow to bet a higher score than that (or the player could just stall)
-- 		if(expectedScore >= lowestStrokes)then
-- 			Minigolf.Messages.Send(player, string.format("Someone has already bet you'd do better than %d strokes! To bet on yourself you must bet on winning in fewer strokes.", lowestStrokes), nil, TEXT_EFFECT_DANGER)
-- 			return
-- 		end
-- 	else
-- 		-- Check if the targetPlayer has already placed a higher bet than what's given
-- 		local betOfTargetPlayer = Minigolf.Bets.GetStrokesOf(targetPlayer, targetPlayer, targetHole)

-- 		if(betOfTargetPlayer and betOfTargetPlayer >= expectedScore)then
-- 			Minigolf.Messages.Send(player, string.format("The player themselves have already bet they'll do this in %d strokes! Only betting they'll do it in more strokes makes sense.", betOfTargetPlayer), nil, TEXT_EFFECT_DANGER)
-- 			return
-- 		end
-- 	end

-- 	Minigolf.Bets.Place(player, targetPlayer, targetHole, expectedScore, betAmount)
-- end)

-- hook.Add("MinigolfPlayerFinishedHole", "Minigolf.CallPayoutBetsOnHoleFinish", function(player, ball, start, strokes)
-- 	-- E.g: 5 strokes on a par 3 would be +2 (two over par)
-- 	local score = strokes - start:GetPar()
	
-- 	Minigolf.Bets.Payout(player, start, score)
-- end)

-- hook.Add("PlayerDisconnected", "Minigolf.RemoveBetsOnDisconnect", function(player)
-- 	-- Refund all the bets regarding this player
-- 	Minigolf.Bets.RefundOnPlayer(player)

-- 	-- Refund all the bets this player made themselves
-- 	Minigolf.Bets.Refund(player)
-- end)