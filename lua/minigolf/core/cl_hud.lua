local hudPanel

hook.Add("HUDPaint", "Minigolf.DrawHUD", function()
	if(not hudPanel and IsValid(LocalPlayer()))then
		hudPanel = vgui.Create("Minigolf.HUD")
		hudPanel:SetPaintedManually(true)
	end

	if(IsValid(hudPanel))then
		hudPanel:PaintManual()
	end
end)

hook.Add("HUDPaint", "Minigolf.DrawHoleStarts", function()
	if(not IsValid(LocalPlayer()))then
		return
	end

	for _, ent in pairs(ents.FindInSphere(LocalPlayer():GetPos(), 1024)) do
		if(ent:GetClass() == "minigolf_hole_start")then
			local screenPos = ent:GetPos():ToScreen()
			
			if(screenPos.visible and not LocalPlayer()._LimitTimeLeft)then
				if(not ent._HolePanel)then
					ent._HolePanel = vgui.Create("Minigolf.HolePanel")
					ent._HolePanel:SetPaintedManually(true)
					ent._HolePanel:SetHole(ent)
					ent._HolePanel:SetAlpha(0)
					ent._HolePanel._Alphad = false
				end
				
				local shouldDrawHolePanel = hook.Call("Minigolf.ShouldDrawHolePanel", Minigolf.GM(), ent)
				
				if(shouldDrawHolePanel ~= nil and shouldDrawHolePanel == false)then
					ent._HolePanel:SetAlpha(0)
					return
				end

				local isInDistance = ent:IsInDistanceOf(LocalPlayer(), 50)

				if(isInDistance)then
					if(not ent._HolePanel._Alphad)then
						ent._HolePanel._Alphad = true
						ent._HolePanel:AlphaTo(255, .3)
					end
				else
					if(ent._HolePanel._Alphad)then
						ent._HolePanel._Alphad = false
						ent._HolePanel:AlphaTo(0, .3)
					end
				end

				ent._HolePanel:SetPos(screenPos.x - ent._HolePanel:GetWide() *.5, screenPos.y - ent._HolePanel:GetTall())

				local x, y = ent._HolePanel:GetPos()

				if(x ~= 0 and y ~= 0)then
					ent._HolePanel:PaintManual()
				end
			end
		end
	end
end)