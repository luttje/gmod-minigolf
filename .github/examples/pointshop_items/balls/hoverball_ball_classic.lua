ITEM.Name = 'Hoverball "Classic" Ball'
ITEM.Price = 1000
ITEM.Model = 'models/maxofs2d/hover_classic.mdl'
ITEM.ModelScale = 0.2

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