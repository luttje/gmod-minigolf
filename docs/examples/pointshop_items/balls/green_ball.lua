ITEM.Name = 'Green Ball'
ITEM.Price = 350
ITEM.Model = 'models/billiards/ball.mdl'
ITEM.ModulateColor = Color(10, 255, 10)

local CATEGORY = CATEGORY

function ITEM:CanPlayerEquip(ply)
	return CATEGORY:CanPlayerEquip(self, ply)
end

function ITEM:OnEquip(ply, modifications)
	local ball = ply:GetPlayerBall()

	CATEGORY:OnEquip(self, ply, modifications)
	
	if(IsValid(ball))then
		ball:SetColor(self.ModulateColor)
	end
end

function ITEM:OnHolster(ply, modifiers)
	CATEGORY:OnHolster(self, ply, modifiers)
end

function ITEM:MiniGolfDrawPlayerBall(ply, modifiers, player, ball, overrideTable)
	CATEGORY:MiniGolfDrawPlayerBall(self, ply, modifiers, player, ball, overrideTable)
end

function ITEM:MiniGolfBallInit(ply, modifiers, player, ball)
	if(ply == player)then
		self:OnEquip(ply)
	end
end

function ITEM:MiniGolfBallRemove(ply, modifiers, player, ball)
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