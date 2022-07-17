ITEM.Name = 'Helicopter Bomb Ball'
ITEM.Price = 1000
ITEM.Model = 'models/combine_helicopter/helicopter_bomb01.mdl'
ITEM.ModelScale = 0.1

Guildhall.SetItemRarity(ITEM, Guildhall.RARITY_3)

local CATEGORY = CATEGORY

function ITEM:CanPlayerEquip(ply)
	return CATEGORY:CanPlayerEquip(self, ply)
end

function ITEM:OnEquip(ply, modifications)
	CATEGORY:OnEquip(self, ply, modifications)
end

function ITEM:OnHolster(ply, modifiers)
	CATEGORY:OnHolster(self, ply, modifiers)
end

function ITEM:MiniGolfDrawPlayerBall(ply, modifiers, player, ball, overrideTable)
	CATEGORY:MiniGolfDrawPlayerBall(self, ply, modifiers, player, ball, overrideTable)
end