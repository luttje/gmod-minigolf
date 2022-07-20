local ITEM = ITEM

ITEM.Name = "Unnamed Ball Style"
ITEM.Icon = "sport_golf"

function ITEM:OnUnequip(player)
	local ball = player:GetMinigolfBall()

	if(not IsValid(ball))then
    return
  end

  local oldMaterial = player:GetMinigolfData("OldBallMaterial")
  local oldColor = player:GetMinigolfData("OldBallColor")
  local modelOverride = ball:GetMinigolfData("ModelOverride")

  if(oldMaterial)then
		ball:SetMaterial(oldMaterial)
  end

  if(oldColor)then
		ball:SetColor(oldColor) 
  end

  if(modelOverride)then
    SafeRemoveEntity(modelOverride)
  end

  ball:SetRenderMode(RENDERMODE_TRANSCOLOR)
end

local function changeBall(player, item, ball)
  if(item.Material)then
    player:SetMinigolfData("OldBallMaterial", ball:GetMaterial())
    ball:SetMaterial(item.Material)
  end
  
  if(item.ModulateColor)then
    player:SetMinigolfData("OldBallColor", ball:GetColor())
    ball:SetColor(item.ModulateColor) 
  end

  ball:SetRenderMode(RENDERMODE_TRANSCOLOR)
end

hook.Add("Minigolf.BallInit", "Minigolf.InitBallDecoration", function(player, ball)
  Minigolf.Items.RunCallbackForEquipedItems(player, ITEM, changeBall, ball)
end)

if(CLIENT)then
	local clientsideModelParents = {}

  local function overrideBall(player, item, ball, overrideTable)
    local modelOverride = ball:GetMinigolfData("ModelOverride")

    if(not item.Model)then
      return
    end

    if(not IsValid(modelOverride))then
      modelOverride = ball:SetMinigolfData("ModelOverride", ClientsideModel(item.Model))
      modelOverride:SetModelScale(item.ModelScale or 1)

      clientsideModelParents[modelOverride] = ball
    end

    modelOverride:SetColor(ball:GetColor())
    modelOverride:SetPos(ball:GetPos())
    modelOverride:SetAngles(ball:GetAngles())
    modelOverride:SetRenderMode(ball:GetRenderMode())
    modelOverride:DrawModel()
    
    overrideTable.hasHandled = true
  end

  local function thinkForOverrideBall(player, item, ball)
    local modelOverride = ball:GetMinigolfData("ModelOverride")

    if(not IsValid(modelOverride))then
      return
    end

    modelOverride:SetColor(ball:GetColor())
    modelOverride:SetPos(ball:GetPos())
    modelOverride:SetAngles(ball:GetAngles())
  end

	-- Remove model overrides of disappeared balls
	hook.Add("Think", "Minigolf.RemoveStaleBallOverrides", function()
    for model, parent in pairs(clientsideModelParents) do
      if(not IsValid(parent))then
        clientsideModelParents[model] = nil
        model:Remove()
      end
    end
	end)

	hook.Add("Minigolf.DrawPlayerBall", "Minigolf.DrawPlayerBallOverride", function(player, ball, overrideTable)
		if(not IsValid(ball))then
      return
    end
    
    Minigolf.Items.RunCallbackForEquipedItems(player, ITEM, overrideBall, ball, overrideTable)
	end)

	hook.Add("Minigolf.ThinkPlayerBall", "Minigolf.ThinkUpdatePlayerBallOverride", function(player, ball)
		if(not IsValid(ball))then
      return
    end
    
    Minigolf.Items.RunCallbackForEquipedItems(player, ITEM, thinkForOverrideBall, ball)
	end)
end
