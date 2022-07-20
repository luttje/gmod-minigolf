ITEM.Name = 'Watermelon Ball'
ITEM.Price = 1000
ITEM.Model = 'models/props_junk/watermelon01.mdl'
ITEM.ModelScale = 0.2

Guildhall.SetItemRarity(ITEM, Guildhall.RARITY_2)

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

function ITEM:MinigolfDrawPlayerBall(ply, modifiers, player, ball, overrideTable)
	CATEGORY:MinigolfDrawPlayerBall(self, ply, modifiers, player, ball, overrideTable)
end