CATEGORY.Name = 'Ball Area Effect'
CATEGORY.Icon = 'color_wheel'
CATEGORY.Watermark = Guildhall.GamemodeSpecific.Minigolf

function CATEGORY:CanPlayerEquip(item, ply)
	return engine.ActiveGamemode() == "gm_minigolf", "This item can only be equiped in the MiniGolf gamemode."
end

function CATEGORY:MiniGolfPreDrawPlayerBall(item, ply, modifiers, player, ball)
  if(ply == player)then
		local width, height = item.BallEffectMaterial:Width(), item.BallEffectMaterial:Height()
		
		cam.IgnoreZ(true)
		cam.Start3D2D(ball:GetPos(), Vector(0,1,0):Angle(), .03)
			surface.SetDrawColor(item.BallEffectColor or Color(255, 255, 255, 255))
			surface.SetMaterial(item.BallEffectMaterial)
			surface.DrawTexturedRect(-width * .5, -height * .5, width, height)
		cam.End3D2D()
		cam.IgnoreZ(false)
	end
end