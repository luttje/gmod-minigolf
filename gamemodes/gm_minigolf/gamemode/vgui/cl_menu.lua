--region Fields

POS = {}
center = Vector(0, 0, 0)

--endregion Fields

--region Panel Maths

---@return number The X axis center of the clients screen
function POS.MainW()
	return center.x - center.x / 2
end

---@return number The Y axis center of the clients screen
function POS.MainH()
	return center.y - center.y / 2
end

--endregion Panel Maths

--region ENUMS and TABLES

-- Buttons to be allowed for closing menu, case sensetive
CLOSE = {
	"F1",
	"TAB",
	"ESCAPE"
}

--endregion ENUMS and TABLES

--region Panel Creation Functions

---Main frame (just like the matrix)
---@param title string The title of the derma panel
---@param width number Size of the panel in the X AXIS
---@param height number Size of the panel in the Y AXIS
---@return PANEL_DFrame
function createFrame(title, posX, posY, width, height)
	local menu = vgui.Create("DFrame")
	UpdateCenter()

	-- Second place of Minus is getting the middle of the screen for the derma
	local x, y, w, h =
		posX or POS.MainW() - POS.MainW() / POS.MainW(),
		posY or POS.MainH() - POS.MainH() / POS.MainH(),
		width or POS.MainW(),
		height or POS.MainH()

	--menu:SetPos(w, h - h / 2)
	menu:SetPos(x, y)
	menu:SetSize(w * 2, h * 2)
	menu:SetTitle(title or "")
	menu:SetDraggable(false)

	-- Quality Of Life functionality
	function menu:OnKeyCodeReleased(key)
		if IsValid(menu) and table.HasValue(CLOSE, input.GetKeyName(key)) then
			RememberCursorPosition()
			menu:Remove()
		end
	end

	return menu
end

--endregion Panel Creation Functions

function UpdateCenter()
	center = Vector(ScrW() / 2, ScrH() / 2, 0)
end