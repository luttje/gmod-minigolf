ITEM.Name = 'Target Area Effect'
ITEM.Price = 150
ITEM.Material = "minigolf/ball_decals/target.png"
ITEM.BallEffectMaterial = Material(ITEM.Material)

Guildhall.SetItemRarity(ITEM, Guildhall.RARITY_3)

if SERVER then
	resource.AddFile("materials/minigolf/ball_decals/target.png")
end

local CATEGORY = CATEGORY

function ITEM:CanPlayerEquip(ply)
	return CATEGORY:CanPlayerEquip(self, ply)
end

ITEM["Minigolf.PreDrawPlayerBall"] = function(self, ply, modifiers, player, ball)
	CATEGORY["Minigolf.PreDrawPlayerBall"](self, ply, modifiers, player, ball)
end