local ITEM = ITEM

ITEM.Name = "Rainbow Ball"
ITEM.Model = "models/billiards/ball.mdl"
ITEM.StartColor = Color(255, 255, 255)
ITEM.UniqueID = "ball_rainbow"

local function drawRainbowBall(player, item, ball)
  local halfOfSpectrum = 360 * .5
  local hue = (math.sin(CurTime()) * halfOfSpectrum) + halfOfSpectrum
  local newColor = HSVToColor(hue, 1, 1)

  ball:SetColor(newColor)
end

hook.Add("Minigolf.DrawPlayerBall", "Minigolf.DrawPlayerBallOverrideRainbow", function(player, ball, overrideTable)
  if(not IsValid(ball))then
    return
  end
  
  Minigolf.Items.RunCallbackForEquipedItems(player, ITEM, drawRainbowBall, ball, overrideTable)
end)
