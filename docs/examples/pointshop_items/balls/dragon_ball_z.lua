ITEM.Name = 'Dragon Ball Z Ball'
ITEM.Price = 350
ITEM.Model = 'models/billiards/ball.mdl'
ITEM.Material = 'minigolf/balls/dragon_ball_z/dragon_ball_1'
ITEM.ModulateColor = Color(255, 255, 255, 150)

if SERVER then
	resource.AddFile("materials/minigolf/balls/dragon_ball_z/dragon_ball_1.vmt")
	resource.AddFile("materials/minigolf/balls/dragon_ball_z/dragon_ball_1_normal.vtf")
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

	render.SetColorModulation( self.ModulateColor.r/255, self.ModulateColor.g/255, self.ModulateColor.b/255 )

	return model, pos, ang
end

ITEM.ModifyClientsideItemModel = ITEM.ModifyClientsideModel