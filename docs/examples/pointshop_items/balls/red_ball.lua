ITEM.Name = 'Red Ball'
ITEM.Price = 350
ITEM.Model = 'models/billiards/ball.mdl'
ITEM.ModulateColor = Color(255, 10, 10)

local CATEGORY = CATEGORY

function ITEM:CanPlayerEquip(ply)
	return CATEGORY:CanPlayerEquip(self, ply)
end

function ITEM:OnEquip(ply, modifications)
	local ball = ply:GetMinigolfBall()

	CATEGORY:OnEquip(self, ply, modifications)
	
	if(IsValid(ball))then
		ball:SetColor(self.ModulateColor)
	end
end

function ITEM:OnHolster(ply, modifiers)
	CATEGORY:OnHolster(self, ply, modifiers)
end

function ITEM:MinigolfDrawPlayerBall(ply, modifiers, player, ball, overrideTable)
	CATEGORY:MinigolfDrawPlayerBall(self, ply, modifiers, player, ball, overrideTable)
end

function ITEM:MinigolfBallInit(ply, modifiers, player, ball)
	if(ply == player)then
		self:OnEquip(ply)
	end
end

function ITEM:MinigolfBallRemove(ply, modifiers, player, ball)
	if(ply == player)then
		self:OnHolster(ply)
	end
end

function ITEM:ModifyClientsideModel(ply, model, pos, ang)
	model:SetColor(self.ModulateColor)
	model:SetRenderMode(RENDERMODE_TRANSCOLOR)
	model:SetModelScale(5, 0)

	render.SetColorModulation( self.ModulateColor.r/255, self.ModulateColor.g/255, self.ModulateColor.b/255 )

	return model, pos, ang
end

ITEM.ModifyClientsideItemModel = ITEM.ModifyClientsideModel