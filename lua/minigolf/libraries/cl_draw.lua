Minigolf.Draw = Minigolf.Draw or {}

-- Source: https://wiki.facepunch.com/gmod/surface.DrawPoly
function Minigolf.Draw.Circle(x, y, radius, seg)
	local cir = {}

	table.insert(cir, { x = x, y = y, u = 0.5, v = 0.5 })
	for i = 0, seg do
		local a = math.rad((i / seg) * -360)
		table.insert(cir,
			{
				x = x + math.sin(a) * radius,
				y = y + math.cos(a) * radius,
				u = math.sin(a) / 2 + 0.5,
				v = math.cos(a) / 2 +
					0.5
			})
	end

	local a = math.rad(0) -- This is needed for non absolute segment counts
	table.insert(cir,
		{
			x = x + math.sin(a) * radius,
			y = y + math.cos(a) * radius,
			u = math.sin(a) / 2 + 0.5,
			v = math.cos(a) / 2 +
				0.5
		})

	surface.DrawPoly(cir)
end

local shadowDrawFunc = GWEN.CreateTextureBorder(448, 0, 31, 31, 8, 8, 8, 8, Material("gwenskin/GModDefault.png"))
--- Draws a shadow at the specified location
function Minigolf.Draw.Shadow(x, y, width, height)
	shadowDrawFunc(x, y, width, height)
	-- We draw this twice to make the shadow more noticable
	shadowDrawFunc(x, y, width, height)
end
