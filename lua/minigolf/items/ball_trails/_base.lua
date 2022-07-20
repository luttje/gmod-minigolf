local ITEM = ITEM

ITEM.Name = "Unnamed Ball Trail"
ITEM.Icon = "rainbow"

local function attachTrail(player, item, ball)
  ball.Trails = ball.Trails or {}
  ball.Trails[item] = util.SpriteTrail(ball, 0, Color(255, 255, 255), false, 15, 1, 4, 0.125, item.TrailPath)
end

--- +equipitem Electric Ball Trail
function ITEM:OnEquip(player)
  if(not SERVER)then
    return
  end

  local ball = player:GetPlayerBall()

  if(not IsValid(ball))then
    return
  end

  equip(self, ball)
end

--- +unequipitem Electric Ball Trail
function ITEM:OnUnequip(player)
  if(not SERVER)then
    return
  end

  local ball = player:GetPlayerBall()

  if(not IsValid(ball))then
    return
  end

  if(not ball.Trails or not ball.Trails[self])then
    return
  end

  SafeRemoveEntity(ball.Trails[self])
end

hook.Add("Minigolf.BallInit", "Minigolf.InitTrailOnBall", function(player, ball)
  Minigolf.Items.RunCallbackForEquipedSubItems(player, ITEM, attachTrail, ball)
end)