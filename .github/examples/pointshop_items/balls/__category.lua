CATEGORY.Name = 'Golf Balls'
CATEGORY.Icon = 'sport_golf'
CATEGORY.AllowedEquipped = 1
CATEGORY.Watermark = Guildhall.GamemodeSpecific.Minigolf

if(SERVER)then
	resource.AddFile("models/billiards/ball.mdl")
	resource.AddFile("materials/models/billiards/white.vmt")
end

function CATEGORY:CanPlayerEquip(item, ply)
	return engine.ActiveGamemode() == "gm_minigolf", "This item can only be equiped in the MiniGolf gamemode."
end

function CATEGORY:OnEquip(item, ply, modifications)
end

function CATEGORY:OnHolster(item, ply, modifiers)
end

function CATEGORY:OnEquipSkin(item, ply, modifications)
	local ball = ply:GetPlayerBall()

	ply._OldBallSkin = IsValid(ball) and ball:GetMaterial() or nil
	ply._OldBallColor = IsValid(ball) and ball:GetColor() or nil
end

function CATEGORY:OnHolsterSkin(item, ply, modifiers)
	local ball = ply:GetPlayerBall()

	if(IsValid(ball))then
		ball:SetMaterial(ply._OldBallSkin)
		ball:SetColor(ply._OldBallColor) 
		ball:SetRenderMode(RENDERMODE_TRANSCOLOR)
	end
end

function CATEGORY:MiniGolfBallInit(item, ply, modifiers, player, ball)
	if(IsValid(ball) and ply == player)then
		ply._OldBallSkin = ball:GetMaterial()
    ply._OldBallColor = ball:GetColor()
    
    ball:SetMaterial(item.Material)
    
    if(item.ModulateColor)then
      ball:SetColor(item.ModulateColor) 
    end

		ball:SetRenderMode(RENDERMODE_TRANSCOLOR)
	end
end

if(CLIENT)then
	local clientsideModelParents = {}

	-- Remove model overrides of disappeared balls
	hook.Add("Think", "MiniGolf.RemoveStaleBallOverrides", function()
			for model,parent in pairs(clientsideModelParents) do
				if(not IsValid(parent))then
					clientsideModelParents[model] = nil
					model:Remove()
				end
			end
	end)

	function CATEGORY:MiniGolfDrawPlayerBall(item, ply, modifiers, player, ball, overrideTable)
		if(IsValid(ball) and ply == player)then
			if(not IsValid(ball.golfModelOverride))then
				ball.golfModelOverride = ClientsideModel(item.Model)
				ball.golfModelOverride:SetModelScale(item.ModelScale or 1)
	
				clientsideModelParents[ball.golfModelOverride] = ball
			end
	
			ball.golfModelOverride:SetColor(ball:GetColor())
			ball.golfModelOverride:SetRenderMode(ball:GetRenderMode())
			ball.golfModelOverride:SetPos(ball:GetPos())
			ball.golfModelOverride:SetAngles(ball:GetAngles())
			ball.golfModelOverride:DrawModel()
			
			overrideTable.hasHandled = true
		end
	end
end
