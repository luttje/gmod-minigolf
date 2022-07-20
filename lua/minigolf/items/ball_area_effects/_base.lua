local ITEM = ITEM

ITEM.Name = "Unnamed Ball Area Effect"
ITEM.Icon = "color_wheel"

local function drawAreaEffect(player, item, ball)
  local width, height = item.Material:Width(), item.Material:Height()
		
  cam.IgnoreZ(true)
  cam.Start3D2D(ball:GetPos(), Vector(0,1,0):Angle(), .03)
    surface.SetDrawColor(item.Color or Color(255, 255, 255, 255))
    surface.SetMaterial(item.Material)
    surface.DrawTexturedRect(-width * .5, -height * .5, width, height)
  cam.End3D2D()
  cam.IgnoreZ(false)
end

hook.Add("Minigolf.PreDrawPlayerBall", "Minigolf.DrawAreaEffectPrePlayerBall", function(player, ball)
  Minigolf.Items.RunCallbackForEquipedItems(player, ITEM, drawAreaEffect, ball)
end)