local BAR_HEIGHT = Minigolf.PADDING * 2
local LOGO_WIDTH = 256
local LOGO_HEIGHT = 128
local HOLE_WIDTH = 125
local BORDER_WIDTH = 4 -- Must be even to avoid half pixels
local CLOSE_BUTTON_SIZE = 32
local playerLibrary = player

local logoMaterial = Material("minigolf/logo_compact.png")

---@class Minigolf.ScoreCardColumn : Panel
local PANEL = {}

AccessorFunc(PANEL, "text", "Text")
AccessorFunc(PANEL, "heading", "Heading", FORCE_BOOL)
AccessorFunc(PANEL, "backgroundColor", "BackgroundColor")
AccessorFunc(PANEL, "textColor", "TextColor")
AccessorFunc(PANEL, "highlight", "Highlight", FORCE_BOOL)

function PANEL:Init()
	self:SetHeading(false)
end

function PANEL:PerformLayout(w, h)
end

function PANEL:Paint(w, h)
	local color = Minigolf.COLOR_PRIMARY_LIGHT
	local borderColor = Minigolf.COLOR_PRIMARY
	local textColor = Color(255, 255, 255, 255)

	if (self:GetHeading()) then
		color = Minigolf.COLOR_SECONDARY_LIGHT
		borderColor = Minigolf.COLOR_SECONDARY
	end

	if (self:GetHighlight()) then
		color = Color(255, 216, 0)
		borderColor = Color(127, 106, 0)
		textColor = borderColor
	end

	if (self:GetBackgroundColor()) then
		color = self:GetBackgroundColor()
	end

	if (self:GetTextColor()) then
		textColor = self:GetTextColor()
	else
		-- Ensure we have enough contrast with the background color
		local h, s, lightness = ColorToHSV(color)

		if (lightness > 0.6) then
			textColor = Color(0, 0, 0, 255)
		end
	end

	surface.SetDrawColor(color)
	surface.DrawRect(0, 0, w, h)

	draw.SimpleText(self:GetText(), "MinigolfMainBold", w * .5, h * .5, textColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

	local halfBorder = BORDER_WIDTH * .5

	surface.SetDrawColor(borderColor)
	surface.DrawRect(0, 0, halfBorder, h)
	surface.DrawRect(w - halfBorder, 0, halfBorder, h)
	surface.DrawRect(0, 0, w, halfBorder)
	surface.DrawRect(0, h - halfBorder, w, halfBorder)
end

vgui.Register("Minigolf.ScoreCardColumn", PANEL, "Panel")

---@class Minigolf.ScoreCard : EditablePanel
local PANEL = {}

function PANEL:Init()
	self.startTime = UnPredictedCurTime()

	self:NoClipping(true)

	-- local mapLogo = vgui.Create("DImage", self)
	-- mapLogo:SetImage("minigolf/maps/golf_test_course20.png") -- TODO: Insert map image here

	-- self.mapLogo = mapLogo

	-- Create close button
	local closeButton = vgui.Create("DButton", self)
	closeButton:SetSize(CLOSE_BUTTON_SIZE, CLOSE_BUTTON_SIZE)
	closeButton:SetText("")
	closeButton:SetTooltip("Close Score Card")
	closeButton.DoClick = function()
		self:Close()
	end
	closeButton.Paint = function(btn, w, h)
		local color = Color(220, 50, 50, 255)
		local hoverColor = Color(255, 70, 70, 255)
		local textColor = Color(255, 255, 255, 255)

		if btn:IsHovered() then
			color = hoverColor
		end

		draw.RoundedBox(8, 0, 0, w, h, color)

		draw.SimpleText("×", "DermaDefaultBold", w * 0.5, h * 0.5, textColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	self.closeButton = closeButton

	local holeScroller = vgui.Create("DHorizontalScroller", self)
	holeScroller:SetOverlap(0)
	holeScroller.Paint = function(s, w, h)
		--  surface.SetDrawColor(255,0,0) surface.DrawRect(0,0,w,h)
	end
	self.holeScroller = holeScroller

	local labelPanel = vgui.Create("DPanel", self)
	self.labelPanel = labelPanel

	self:CalculateSize()
	Minigolf.WaitOneTick(function() -- TODO: Make this not so hacky
		if (not IsValid(self)) then
			return
		end

		self:LoadHoles(self:GetWide(), self:GetTall())
	end, self)
end

function PANEL:Restore()
	RestoreCursorPosition()
end

function PANEL:Close()
	RememberCursorPosition()
	self:Remove()
end

function PANEL:GetNumRows()
	return #playerLibrary.GetAll()
end

function PANEL:CalculateSize()
	local minHeight = Minigolf.PADDING + LOGO_HEIGHT + Minigolf.PADDING + BAR_HEIGHT + Minigolf.PADDING +
		BAR_HEIGHT + Minigolf.PADDING
	local maxHeight = ScrH() * .8

	-- TODO: without this * 2 we get a scrollbar, we're not calculating the size correctly, but this is a workaround for now
	local numRows = self:GetNumRows() * 2

	local height = minHeight + (numRows * BAR_HEIGHT)

	if (height < minHeight) then
		print("capped scoreboard at min, height was: ", height)
		height = minHeight
	elseif (height > maxHeight) then
		print("capped scoreboard at max, height was: ", height)
		height = maxHeight
	end

	self:SetSize(ScrW() * .6, height)
	self:SetPos(ScrW() * .2, ScrH() * .5 - (minHeight * .5))
end

function PANEL:GetOrderedHoles()
	if (self._CachedOrderedHoles) then
		return self._CachedOrderedHoles
	end

	local holes = ents.FindByClass("minigolf_hole_start")
	local courses = {}

	-- Place the holes into a course
	for _, hole in pairs(holes) do
		local course = hole:GetCourse()
		courses[course] = courses[course] or {}

		table.insert(courses[course], hole)
	end

	-- Sort all holes in a course
	holes = {}
	for _, course in pairs(courses) do
		table.sort(course, function(holeA, holeB)
			return holeA:GetOrder() < holeB:GetOrder()
		end)

		-- Move these holes back into the holes table (now sorted)
		for __, hole in pairs(course) do
			table.insert(holes, hole)
		end
	end

	self._CachedOrderedHoles = holes

	return holes
end

function PANEL:LayoutBaseHoles(w, h)
	local holes = self:GetOrderedHoles()
	local currentY = 0

	local horizontalPanel = vgui.Create("DPanel", self.holeScroller)
	horizontalPanel:SetWide(#holes * HOLE_WIDTH)

	self.horizontalPanel = horizontalPanel

	-- Create hole name headers
	local headingPanel = vgui.Create("Panel", horizontalPanel)
	headingPanel:SetSize(#holes * HOLE_WIDTH,
		Minigolf.PADDING + LOGO_HEIGHT + Minigolf.PADDING - BAR_HEIGHT - Minigolf.PADDING)

	for i, hole in pairs(holes) do
		local column = vgui.Create("Minigolf.ScoreCardColumn", headingPanel)
		column:SetHeading(true)
		column:SetSize(HOLE_WIDTH, headingPanel:GetTall())
		column:SetText(hole:GetHoleName())
		column:SetPos((i - 1) * HOLE_WIDTH, 0)
	end

	currentY = currentY + headingPanel:GetTall()

	-- Create PAR label and values
	local parLabel = vgui.Create("Minigolf.ScoreCardColumn", self.labelPanel)
	parLabel:SetHeading(true)
	parLabel:Dock(TOP)
	parLabel:SetTall(BAR_HEIGHT)
	parLabel:SetText("PAR")
	parLabel:SetPos(0, 0)

	local parPanel = vgui.Create("Panel", horizontalPanel)
	parPanel:SetSize(#holes * HOLE_WIDTH, BAR_HEIGHT)
	parPanel:SetPos(0, currentY)

	for i, hole in pairs(holes) do
		local column = vgui.Create("Minigolf.ScoreCardColumn", parPanel)
		column:SetHeading(true)
		column:SetSize(HOLE_WIDTH, parPanel:GetTall())
		column:SetText(hole:GetPar())
		column:SetPos((i - 1) * HOLE_WIDTH, 0)
	end

	currentY = currentY + parPanel:GetTall()

	-- Layout the main score area
	self:LayoutScorePanel(w, h, currentY, self:GetNumRows())

	return horizontalPanel, currentY
end

function PANEL:LoadHoles(w, h)
	local horizontalPanel, currentY = self:LayoutBaseHoles(w, h)

	-- Add all players to the scoreboard
	self:LayoutPlayerInfo(w, h)

	self.holeScroller:AddPanel(horizontalPanel)
end

function PANEL:LayoutScorePanel(w, h, currentY, numRows)
	local holes = self:GetOrderedHoles()

	local nameScrollPanel = vgui.Create("DScrollPanel", self.labelPanel)
	nameScrollPanel:Dock(FILL)

	local scoreScrollPanel = vgui.Create("DScrollPanel", self.horizontalPanel)
	scoreScrollPanel:SetSize(#holes * HOLE_WIDTH, h - Minigolf.PADDING - Minigolf.PADDING - BAR_HEIGHT - currentY)
	scoreScrollPanel:SetPos(0, currentY)

	-- Sync scrolling between name and score panels
	nameScrollPanel.OnVScroll = function(pnl, offset)
		pnl.pnlCanvas:SetPos(0, offset)
		scoreScrollPanel:GetVBar().Scroll = offset * -1
		scoreScrollPanel.pnlCanvas:SetPos(0, offset)
	end
	scoreScrollPanel.OnVScroll = function(pnl, offset)
		pnl.pnlCanvas:SetPos(0, offset)
		nameScrollPanel:GetVBar().Scroll = offset * -1
		nameScrollPanel.pnlCanvas:SetPos(0, offset)
	end

	local scorePanel = vgui.Create("Panel", scoreScrollPanel)
	scorePanel:SetSize(#holes * HOLE_WIDTH, BAR_HEIGHT * numRows)
	scorePanel:SetPos(0, 0)
	scorePanel.Paint = function(scorePanel, w, h)
		surface.SetDrawColor(Minigolf.COLOR_PRIMARY_LIGHT)
		surface.DrawRect(0, 0, w, h)
	end

	self.nameScrollPanel = nameScrollPanel
	self.scorePanel = scorePanel
end

function PANEL:LayoutPlayerInfo(w, h)
	local holes = self:GetOrderedHoles()
	local players = playerLibrary.GetAll()

	-- Sort players alphabetically by name
	table.sort(players, function(a, b)
		return a:Nick() < b:Nick()
	end)

	for rowY, ply in pairs(players) do
		-- Create player name label
		local nameColumn = vgui.Create("Minigolf.ScoreCardColumn", self.nameScrollPanel)
		nameColumn:Dock(TOP)
		nameColumn:SetTall(BAR_HEIGHT)
		nameColumn:SetText(ply:Nick())

		-- Create score columns for each hole
		for i, hole in pairs(holes) do
			local column = vgui.Create("Minigolf.ScoreCardColumn", self.scorePanel)
			column:SetSize(HOLE_WIDTH, BAR_HEIGHT)
			column:SetPos((i - 1) * HOLE_WIDTH, (rowY - 1) * BAR_HEIGHT)

			-- Check if this hole is currently being played by this player
			local activePlayer = hole:GetNWEntity("Minigolf.ActivePlayer", NULL)
			if (IsValid(activePlayer) and activePlayer == ply) then
				column:SetHighlight(true)
			end

			-- Get and display the score
			local holeName = hole:GetUniqueHoleName()
			if (self.scoresOverride and self.scoresOverride[holeName]) then
				self:SetColumnScoreText(column, self.scoresOverride[holeName], hole:GetPar())
			else
				self:SetColumnScoreText(column, ply:GetNWInt(holeName .. "Strokes", Minigolf.HOLE_NOT_PLAYED),
					hole:GetPar())
			end
		end
	end
end

function PANEL:SetColumnScoreText(column, strokes, par)
	if (strokes == Minigolf.HOLE_NOT_PLAYED) then
		column:SetText("")
		column:SetTooltip("The player hasn't played on this hole yet.")
	elseif (strokes == Minigolf.HOLE_DISQUALIFIED) then
		column:SetText("DSQ")
		column:SetTooltip("On this hole the player either ran out of time or has reached the maximum strokes.")
	else
		local relativeToParText = "better than par."

		if (strokes > par) then
			relativeToParText = "worse than par. They should try getting less strokes next time!"
		elseif (strokes == par) then
			relativeToParText = "equal to par."
		end

		column:SetText(strokes)
		column:SetTooltip("The player got " ..
			tostring(strokes) .. " " .. Minigolf.Text.Pluralize("stroke", strokes) .. ". That is " .. relativeToParText)
	end

	hook.Call("Minigolf.AdjustColumnScore", Minigolf.GM(), column, strokes, par)
end

function PANEL:PerformLayout(w, h)
	-- self.mapLogo:SetPos(Minigolf.PADDING, Minigolf.PADDING)
	-- self.mapLogo:SetSize(LOGO_WIDTH, LOGO_HEIGHT)

	-- Position close button in top right corner
	self.closeButton:SetPos(w - CLOSE_BUTTON_SIZE, 0)

	-- Arithmetic written out in full because it's easier to see where the padding is going
	self.holeScroller:SetSize(w - Minigolf.PADDING - Minigolf.PADDING - LOGO_WIDTH - Minigolf.PADDING,
		h - Minigolf.PADDING - Minigolf.PADDING - BAR_HEIGHT)
	self.holeScroller:SetPos(Minigolf.PADDING + LOGO_WIDTH + Minigolf.PADDING,
		Minigolf.PADDING + BAR_HEIGHT + Minigolf.PADDING)

	self.labelPanel:SetSize(w - Minigolf.PADDING - self.holeScroller:GetWide() - Minigolf.PADDING,
		h - Minigolf.PADDING - LOGO_HEIGHT - Minigolf.PADDING - Minigolf.PADDING)
	self.labelPanel:SetPos(Minigolf.PADDING, Minigolf.PADDING + LOGO_HEIGHT + Minigolf.PADDING + Minigolf.PADDING)
end

function PANEL:Paint(w, h)
	local statusText = "Minigolf Scores"

	Derma_DrawBackgroundBlur(self, self.startTime)

	draw.RoundedBox(16, 0, 0, w, h, Color(255, 255, 255, 255))

	draw.SimpleText(statusText, "MinigolfMainBold", w * .5, Minigolf.PADDING * 2, Minigolf.COLOR_PRIMARY,
		TEXT_ALIGN_CENTER,
		TEXT_ALIGN_CENTER)

	surface.SetDrawColor(255, 255, 255, 255)
	surface.SetMaterial(logoMaterial)

	local logoW, logoH = 256, 256

	surface.DrawTexturedRect(w * .5 - (logoW * .5), -logoH - Minigolf.PADDING, logoW, logoH)
end

vgui.Register("Minigolf.ScoreCard", PANEL, "EditablePanel")

net.Receive("Minigolf.ShowScoreCard", function(length)
	local scoreCard = vgui.Create("Minigolf.ScoreCard")
	scoreCard:MakePopup()
	scoreCard:Center()
end)
