-- Minigolf.Bets = Minigolf.Bets or {}

-- -- When the server sends all bets
-- net.Receive("Minigolf.SendBetsToPlayers", function(length)
--   local compactInfo = net.ReadTable()

--   Minigolf.Bets.All = {}

--   for betIndex, betData in pairs(compactInfo) do
--     Minigolf.Bets.All[betIndex] = {
--       PlayerName = betData.g,
--       HoleName = betData.h,
--       BetSum = betData.b,
--     }
--   end
-- end)