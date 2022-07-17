ITEM.Name = 'Facepunch Ball'
ITEM.Price = 350
ITEM.Model = 'models/billiards/ball.mdl'
ITEM.Material = 'minigolf/balls/communities/facepunch'

if SERVER then
	resource.AddFile("materials/minigolf/balls/communities/facepunch.vmt")
	resource.AddFile("materials/minigolf/balls/communities/facepunch_normal.vtf")	
end

local CATEGORY = CATEGORY

function ITEM:CanPlayerEquip(ply)
	return CATEGORY:CanPlayerEquip(self, ply)
end

function ITEM:OnEquipSkin(ply, modifications)
	CATEGORY:OnEquip(self, ply, modifications)
end

function ITEM:OnHolsterSkin(ply, modifiers)
	CATEGORY:OnHolster(self, ply, modifiers)
end

function ITEM:MiniGolfBallInit(ply, modifiers, player, ball)
	CATEGORY:MiniGolfBallInit(self, ply, modifiers, player, ball)	
end

function ITEM:ModifyClientsideModel(ply, model, pos, ang)
	model:SetMaterial(self.Material)
	model:SetModelScale(5, 0)

	return model, pos, ang
end

ITEM.ModifyClientsideItemModel = ITEM.ModifyClientsideModel