include("shared.lua")

function ENT:GetFlagSway()
	return self:GetNWInt("FlagSwayAngle", 1), self:GetNWInt("FlagSwaySpeed", 5)
end

function ENT:GetStart()
	return self:GetNWEntity("HoleStart")
end

local flagMaterial = Material("minigolf/flag.png")
local flagDoneMaterial = Material("minigolf/flag_done.png")
hook.Add("PostDrawTranslucentRenderables", "Minigolf.EntityFlag.DrawFlags", function(isDrawingDepth, isDrawingSkybox)
	if(isDrawingSkybox or isDrawingDepth)then return end

  local flagEntities = ents.FindByClass("minigolf_hole_flag");

	for _, flags in pairs(flagEntities) do
		local hole = flags:GetStart()
	
		if(IsValid(hole))then	
			local teamID = hole:GetActiveTeam()
			local color = Color(255, 255, 255, 100)
			local material = flagMaterial
			
			local originalAngles = flags:GetAngles()
			local correctedAngles = flags:GetAngles()
		
			correctedAngles:RotateAroundAxis(originalAngles:Right(), -90)
			correctedAngles:RotateAroundAxis(originalAngles:Up(), 90)
			correctedAngles:RotateAroundAxis(originalAngles:Right(), -90)
			correctedAngles:RotateAroundAxis(originalAngles:Up(), 180)
	
			local swayAngle, swaySpeed = flags:GetFlagSway()
			correctedAngles:RotateAroundAxis(originalAngles:Up(), math.sin(CurTime() * swaySpeed) * swayAngle)

			if(hole._Strokes and hole._Strokes[LocalPlayer()] ~= nil)then
				material = flagDoneMaterial
			end
			
			if(teamID > 0)then
				color = team.GetColor(teamID)
			end

			local modelBoundsMin, modelBoundsMax = flags:GetModelBounds()
			local flagOrigin = flags:GetPos() - Angle(0,1,0):Forward() + (Angle(0,1,0):Right() * 1.5) + modelBoundsMax
			
			cam.Start3D2D(flagOrigin, correctedAngles, .03)
				surface.SetDrawColor(color)
				surface.SetMaterial(material)
				surface.DrawTexturedRect(0, 0, 1013, 791)
			cam.End3D2D()
			
			correctedAngles:RotateAroundAxis(originalAngles:Up(), 180)

			cam.Start3D2D(flagOrigin, correctedAngles, .03)
				surface.SetDrawColor(color)
				surface.SetMaterial(material)
				surface.DrawTexturedRectUV(-material:Width(), 0, material:Width(), material:Height(), 1, 0, 0, 1)
			cam.End3D2D()
		end	
	end
end)