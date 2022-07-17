ITEM.Name = 'Electric Ball Trail'
ITEM.Price = 350
ITEM.Material = 'trails/electric.vmt'
ITEM.NeedsDarkBackground = true

local CATEGORY = CATEGORY

function ITEM:CanPlayerEquip(ply)
	return CATEGORY:CanPlayerEquip(self, ply)
end

function ITEM:OnEquip(ply)
	local ball = ply:GetPlayerBall()

	SafeRemoveEntity(ply.ElectricBallTrail)
	
	if(IsValid(ball))then
		ply.ElectricBallTrail = util.SpriteTrail(ball, 0, Color(255, 255, 255), false, 15, 1, 4, 0.125, self.Material)
	end
end

function ITEM:OnHolster(ply)
	SafeRemoveEntity(ply.ElectricBallTrail)
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