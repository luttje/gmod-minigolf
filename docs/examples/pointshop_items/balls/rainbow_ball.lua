ITEM.Name = 'Rainbow Ball'
ITEM.Price = 350
ITEM.Model = 'models/billiards/ball.mdl'
ITEM.StartColor = Color(255, 255, 255)

Guildhall.SetItemRarity(ITEM, Guildhall.RARITY_3)

local CATEGORY = CATEGORY

function ITEM:CanPlayerEquip(ply)
	return CATEGORY:CanPlayerEquip(self, ply)
end

function ITEM:OnEquip(ply, modifications)
	local ball = ply:GetMinigolfBall()

	CATEGORY:OnEquip(self, ply, modifications)
	
	if(IsValid(ball))then
		ball:SetColor(self.StartColor)
	end
end

function ITEM:OnHolster(ply, modifiers)
	CATEGORY:OnHolster(self, ply, modifiers)
end

function ITEM:MinigolfDrawPlayerBall(ply, modifiers, player, ball, overrideTable)
	if(IsValid(ball) and ply == player)then
		local halfOfSpectrum = 360 * .5
		local hue = (math.sin(CurTime()) * halfOfSpectrum) + halfOfSpectrum
		local newColor = HSVToColor(hue, 1, 1)

		ball:SetColor(newColor)
	end
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
	local halfOfSpectrum = 360 * .5
	local hue = (math.sin(CurTime()) * halfOfSpectrum) + halfOfSpectrum
	local newColor = HSVToColor(hue, 1, 1)

	model:SetColor(newColor)
	model:SetRenderMode(RENDERMODE_TRANSCOLOR)
	model:SetModelScale(5, 0)

	return model, pos, ang
end

ITEM.ModifyClientsideItemModel = ITEM.ModifyClientsideModel