ITEM.Name = 'Phoenix Ball'
ITEM.Price = 1000
ITEM.Model = 'models/props_phx/ball.mdl'
ITEM.ModelScale = 0.05

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

function ITEM:MiniGolfDrawPlayerBall(ply, modifiers, player, ball, overrideTable)
	CATEGORY:MiniGolfDrawPlayerBall(self, ply, modifiers, player, ball, overrideTable)
end

function ITEM:ModifyClientsideModel(ply, model, pos, ang)
	model:SetModelScale(.3, 0)

	return model, pos, ang
end

ITEM.ModifyClientsideItemModel = ITEM.ModifyClientsideModel