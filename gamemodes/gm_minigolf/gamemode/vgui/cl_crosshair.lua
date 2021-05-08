--region Local Fields

-- Coloring
local lineColor   = Color(255, 255, 255, 255)
local borderColor = Color(0, 0, 0, 255)

-- Positioning | Note iD = Inner Diameter
local oD = 20
local iD = 7
local borderThick = 1
local dotThick = 1

-- Confusing Math
local height = oD - iD + borderThick * 2 + 1
local width = borderThick * 2 + 1
local dotMath = dotThick * 2 + 1

--endregion Local Fields

--region Crosshair Painting

hook.Add("HUDPaint", "Minigolf.DrawCrosshair", function()
	local center = Vector(ScrW() / 2, ScrH() / 2, 0)

	-- Border Drawing
	surface.SetDrawColor(borderColor)
	surface.DrawRect(center.x - borderThick, center.y - oD - borderThick, width, height) -- Top
	surface.DrawRect(center.x - borderThick, center.y + iD - borderThick, width, height) -- Bottom
	surface.DrawRect(center.x - oD - borderThick, center.y - borderThick, height, width) -- Left
	surface.DrawRect(center.x + iD - borderThick, center.y - borderThick, height, width) -- Right
	surface.DrawRect(center.x - (dotThick), center.y - (dotThick), dotMath, dotMath) -- Middle

	-- Middle Line Drawing
	surface.SetDrawColor(lineColor)
	surface.DrawLine(center.x, center.y - oD, center.x, center.y - iD) -- Top
	surface.DrawLine(center.x, center.y + oD, center.x, center.y + iD) -- Bottom
	surface.DrawLine(center.x - oD, center.y, center.x - iD, center.y) -- Right
	surface.DrawLine(center.x + oD, center.y, center.x + iD, center.y) -- Left
	surface.DrawRect(center.x, center.y, 1, 1) -- Middle
end)

--endregion Crosshair Painting