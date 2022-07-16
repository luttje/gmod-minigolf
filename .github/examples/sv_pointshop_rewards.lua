local gamemode = engine.ActiveGamemode()

if(gamemode == "gm_minigolf")then
  -- When a minigolf ball hits the goal give tokens
  hook.Add("Minigolf.PlayerFinishedHole", "MyAddon.RewardTokensToPlayer", function(player, ball, start, strokes)
    if(strokes == Minigolf.HOLE_DISQUALIFIED)then
      return
    end

    local start = ball:GetStart()
    local par = start:GetPar()
    local named = "score"
    local reward = 0
    local overPar = strokes - par -- negative would be under-par

    -- double-bogey (+2), triple-bogey (+3), and so on. However, it is more common to hear scores higher than a triple bogey referred to simply by the number of strokes rather than by name, ex: five-over-par
    -- if(overPar > 3)then
    --   tokens = 0
    --   named = strokes .. " over par"
    -- end
    -- if(overPar == 3)then
    --   tokens = 0
    --   named = "triple-bogey (+3)"
    -- end
    if(overPar == 2)then
      reward = 1
      named = "double-bogey (+2)"
    end

    -- Bogey means one shot more than par (+1). 
    if(overPar == 1)then
      reward = 2
      named = "bogey (+1)"
    end

    -- Par means scoring even (E). 
    if(overPar == 0)then
      reward = 3
      named = "par (E)"
    end
    
    -- Birdie means scoring one under par (−1)
    if(overPar == -1)then
      reward = 4
      named = "birdie (-1)"
    end

    -- Eagle means scoring two under par (−2). 
    if(overPar == -2)then
      reward = 5
      named = "eagle (-2)"
    end

    -- Albatross means three shots under par (−3) 
    if(overPar <= -3)then
      reward = 6
      named = string.format("albatross or better (%d)", overPar)
    end

    -- Hole in one
    if(strokes == 1)then
      reward = 8
      named = "hole in one!"
    end

    if(reward > 0 and IsValid(player))then
      Minigolf.Messages.Send(player, string.format("You got rewarded %d %s for your %s", reward, PS.Config.PointsName, named), nil, Minigolf.TEXT_EFFECT_CASH)
      player:PS_GivePoints(reward)
    end
  end)
end