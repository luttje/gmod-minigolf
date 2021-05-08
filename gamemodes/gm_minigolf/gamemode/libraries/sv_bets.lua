-- util.AddNetworkString("Minigolf.SendBetsToPlayers")

-- Minigolf.Bets = {}
-- Minigolf.Bets.All = {}

-- function Minigolf.Bets.GetIndex(player, hole)
--   return (player:AccountID() or player:UserID()) .. hole:GetHoleName() -- use GetUniqueHoleName instead
-- end

-- -- Refund all the bets regarding a target player
-- function Minigolf.Bets.RefundOnPlayer(player)
--   for betIndex,bets in pairs(Minigolf.Bets.All) do
--     local toRemove = {}

--     for i,bet in pairs(bets) do
--       if(IsValid(bet.Player) and bet.Player == player)then
--         if(IsValid(bet.Bettor))then
--           bet.Bettor:PS_GivePoints(bet.BetAmount)
--           table.insert(toRemove, i)
--         end
--       end
--     end

--     for _,index in pairs(toRemove) do
--       table.remove(Minigolf.Bets.All[betIndex], index)
--     end
--   end
-- end

-- -- Refund all the bets a bettor made
-- function Minigolf.Bets.Refund(bettor)
--   for betIndex,bets in pairs(Minigolf.Bets.All) do
--     local toRemove = {}

--     for i,bet in pairs(bets) do
--       if(IsValid(bet.Bettor) and bettor == bet.Bettor)then
--         bettor:PS_GivePoints(bet.BetAmount)
--         table.insert(toRemove, i)
--       end
--     end

--     for _,index in pairs(toRemove) do
--       table.remove(Minigolf.Bets.All[betIndex], index)
--     end

--     if(#bets == 0)then
--       Minigolf.Bets.All[betIndex] = nil
--     end
--   end

--   Minigolf.Bets.NetworkAll()
-- end

-- function Minigolf.Bets.Place(bettor, player, hole, score, betAmount)
--   local betIndex = Minigolf.Bets.GetIndex(player, hole)
--   Minigolf.Bets.All[betIndex] = Minigolf.Bets.All[betIndex] or {}
  
--   table.insert(Minigolf.Bets.All[betIndex], {
--     Bettor = bettor,
--     Player = player,
--     Hole = hole,
--     Score = score,
--     BetAmount = betAmount
--   })
  
--   bettor:PS_TakePoints(betAmount)

-- 	Minigolf.Messages.Send(nil, bettor:Nick() .. " bet " .. betAmount .. " " .. Minigolf.Text.Pluralize(PS.Config.PointsNameSingular, betAmount) .. " on " .. player:Nick() .. "", "N")

-- 	Minigolf.Bets.NetworkAll()
-- end

-- function Minigolf.Bets.Payout(player, hole, score)
--   local completedBets = {}
--   local payoutSum = 0
--   local winningBettors = {}
--   local losingBettors = {}
--   local bestBettors = {}
--   local bestScore = 99999999 -- In golf the best scores are the lowest scores (least strikes)

--   for betIndex, bets in pairs(Minigolf.Bets.All) do
--     for _,bet in pairs(bets) do
--       if(bet.Player == player
--       and bet.Hole == hole)then
--         completedBets[betIndex] = true
  
--         if(bet.Score == score)then
--           table.insert(winningBettors, bet.Bettor)
--         else
--           local isBestOfTheWorst = false
          
--           if(bet.Score < bestScore)then
--             bestScore = bet.Score

--             -- Move the previous best over to the losers
--             table.Merge(losingBettors, bestBettors)

--             -- This player guessed the best score, put them as the best bettor
--             bestBettors = {}
--             table.insert(bestBettors, bet.Bettor)

--             isBestOfTheWorst = true
--           elseif(bet.Score == bestScore)then
--             -- A tie, better than losing!
--             table.insert(bestBettors, bet.Bettor)

--             isBestOfTheWorst = true
--           end

--           if(not isBestOfTheWorst)then
--             table.insert(losingBettors, bet.Bettor)
--           end
--         end
  
--         payoutSum = payoutSum + bet.BetAmount
--       end
--     end
--   end

--   if(payoutSum == 0)then
--     return
--   end

--   for completedBetIndex, _ in pairs(completedBets) do
--     Minigolf.Bets.All[completedBetIndex] = nil
--   end

--   Minigolf.Bets.NetworkAll()

--   local numWinners = #winningBettors

--   if(numWinners == 0)then
--     numWinners = #bestBettors

--     if(numWinners > 0)then
--       local payout = math.floor(payoutSum / numWinners)

--       for _, bestBettor in pairs(bestBettors) do
--         Minigolf.Messages.Send(nil, bestBettor:Nick() .. " guessed nearest the final score and won " .. tostring(payout) .. " " .. Minigolf.Text.Pluralize(PS.Config.PointsNameSingular, payout) .. "!", "@", TEXT_EFFECT_CASH)

--         bestBettor:PS_GivePoints(payout)
--       end
--     end

--     for _, losingBettor in pairs(losingBettors) do
--       -- Check if this player didn't also had winning bets
--       if(not table.HasValue(winningBettors, losingBettor))then
--         Minigolf.Messages.Send(nil, losingBettor:Nick() .. " lost all their tokens in a bet!", "¢", TEXT_EFFECT_DANGER)
--       end
--     end

--     return
--   end

--   local payout = math.floor(payoutSum / numWinners)

--   for _, winningBettor in pairs(winningBettors) do
--     Minigolf.Messages.Send(nil, winningBettor:Nick() .. " won " .. tostring(payout) .. " " .. Minigolf.Text.Pluralize(PS.Config.PointsNameSingular, payout) .. " in a bet!", "@", TEXT_EFFECT_SPARKLE)
  
--     winningBettor:PS_GivePoints(payout)
--   end
-- end

-- function Minigolf.Bets.GetCompactInfo()
--   local betsInfo = {}

--   -- Create the compact info, summing the score
--   for betIndex, bets in pairs(Minigolf.Bets.All) do
--     betsInfo[betIndex] = {}
    
--     for _,bet in pairs(bets) do
--       betsInfo[betIndex].g = betsInfo[betIndex].g or bet.Player:Nick()
--       betsInfo[betIndex].h = betsInfo[betIndex].h or bet.Hole:GetUniqueHoleName()
--       betsInfo[betIndex].b = (betsInfo[betIndex].b or 0) + bet.BetAmount
--     end
--   end

--   return betsInfo
-- end

-- function Minigolf.Bets.NetworkAll()
--   net.Start("Minigolf.SendBetsToPlayers")
--   net.WriteTable(Minigolf.Bets.GetCompactInfo())
--   net.Broadcast()
-- end

-- --- Gets how many strokes a player has bet on another player for a certain hole
-- ---@param player Player The player who's placed a bet
-- ---@param targetPlayer Player The player who's being bet on
-- ---@param targetHole Entity|string The hole this bet is on
-- ---@return number|nil
-- function Minigolf.Bets.GetStrokesOf(player, targetPlayer, targetHole)
--   local betIndex = Minigolf.Bets.GetIndex(player, targetHole)
  
--   for _, bet in pairs(Minigolf.Bets.All[betIndex]) do
--     if(bet.Bettor == player and bet.Player == targetPlayer and bet.Hole == targetHole)then
--       return bet.Score
--     end
--   end

--   return nil
-- end

-- --- Gets the lowest amount of strokes someone's bet on the given player
-- ---@param targetPlayer Player The player who's being bet on
-- ---@param targetHole Entity|string The hole this bet is on
-- ---@return number|nil
-- function Minigolf.Bets.GetLowestStrokesOn(targetPlayer, targetHole)
--   local lowestStrokes = 999999

--   for betIndex, bets in pairs(Minigolf.Bets.All) do
--     for _,bet in pairs(bets) do
--       if(bet.Score < lowestStrokes)then
--         lowestStrokes = bet.Score
--       end
--     end
--   end

--   return lowestStrokes
-- end