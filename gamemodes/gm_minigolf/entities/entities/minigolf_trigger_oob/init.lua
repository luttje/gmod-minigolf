ENT.Base = "base_brush"
ENT.Type = "brush"

function ENT:Initialize()

end

function ENT:StartTouch(ent)
	if ent and ent:IsValid()then
		if(ent:GetClass() == "minigolf_ball")then
			hook.Call("MinigolfBallOutOfBounds", gm(), ent:GetPlayer(), ent, self)
		end
	end
end

function ENT:KeyValue(key, value)
	key = string.lower(key)
	
end

function ENT:EndTouch(ent) end
function ENT:Touch(ent) end
function ENT:Think() end
function ENT:OnRemove() end

function ENT:UpdateTransmitState()	
	return TRANSMIT_ALWAYS 
end