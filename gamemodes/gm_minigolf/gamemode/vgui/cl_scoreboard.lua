--[[
	TODO: Move all Team related stuff to the gamemode, only call hooks here.
		Then test:
		- Does the addon work without the gamemode?
		- Does the gamemode work with the addon?
--]]



local BAR_HEIGHT = Minigolf.PADDING * 2
local LOGO_WIDTH = 256
local LOGO_HEIGHT = 128
local HOLE_WIDTH = 125
local BORDER_WIDTH = 4 -- Must be even to avoid half pixels
local playerLibrary = player

local logoMaterial = Material("minigolf/logo_compact.png")

Minigolf.Menus.Scoreboard = Minigolf.Menus.Scoreboard

local PANEL = {}

AccessorFunc(PANEL, "text", "Text")
AccessorFunc(PANEL, "heading", "Heading", FORCE_BOOL)
AccessorFunc(PANEL, "backgroundColor", "BackgroundColor")
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

	if(self:GetHeading())then
		color = Minigolf.COLOR_SECONDARY_LIGHT
		borderColor = Minigolf.COLOR_SECONDARY
	end

	if(self:GetHighlight())then
		color = Color(255, 216, 0)
		borderColor = Color(127, 106, 0)
		textColor = borderColor
	end

	if(self:GetBackgroundColor())then
		color = self:GetBackgroundColor()
	end

	surface.SetDrawColor(color)
	surface.DrawRect(0,0,w,h)

	draw.SimpleText(self:GetText(), "MinigolfMain", w * .5, h * .5, textColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

	local halfBorder = BORDER_WIDTH * .5

	surface.SetDrawColor(borderColor)
	surface.DrawRect(0, 0, halfBorder, h)
	surface.DrawRect(w - halfBorder, 0, halfBorder, h)
	surface.DrawRect(0, 0, w, halfBorder)
	surface.DrawRect(0, h - halfBorder, w, halfBorder)
end

vgui.Register("Minigolf.ScoreBoardColumn", PANEL, "Panel")


local PANEL = {}

function PANEL:Init()
	self.startTime = UnPredictedCurTime()

	self:NoClipping(true)

	-- local mapLogo = vgui.Create("DImage", self)
	-- mapLogo:SetImage("minigolf/maps/golf_test_course20.png") -- TODO: Insert map image here

	-- self.mapLogo = mapLogo

	local holeScroller = vgui.Create("DHorizontalScroller", self)
	holeScroller:SetOverlap(0)
	holeScroller.Paint = function(s, w,h)
		--  surface.SetDrawColor(255,0,0) surface.DrawRect(0,0,w,h)
	end
	self.holeScroller = holeScroller

	local labelPanel = vgui.Create("DPanel", self)
	self.labelPanel = labelPanel

	self:CalculateSize()
	Minigolf.WaitOneTick(function() -- TODO: Make this not so hacky
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

function PANEL:CalculateSize()
	local minHeight = Minigolf.PADDING + LOGO_HEIGHT + Minigolf.PADDING + Minigolf.PADDING + BAR_HEIGHT + BAR_HEIGHT
	local maxHeight = ScrH() * .8
	local numRows = #playerLibrary.GetAll() + #Minigolf.Teams.All

	local height = Minigolf.PADDING + LOGO_HEIGHT + Minigolf.PADDING + Minigolf.PADDING + BAR_HEIGHT + (numRows * BAR_HEIGHT)

	if(height < minHeight)then
		print("capped scoreboard at min, height was: ", height)
		height = minHeight
	elseif(height > maxHeight)then
		print("capped scoreboard at max, height was: ", height)
		height = maxHeight
	end

	self:SetSize(ScrW() * .6, height)
	self:SetPos(ScrW() * .2, ScrH() * .5 - (minHeight * .5))
end

function PANEL:GetOrderedHoles()
	if(self._CachedOrderedHoles)then
		return self._CachedOrderedHoles
	end

	local holes = ents.FindByClass("minigolf_hole_start")
	local currentY = 0

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

function PANEL:LoadHoles(w, h)
	local holes = self:GetOrderedHoles()
	local currentY = 0

	local horizontalPanel = vgui.Create("DPanel", self.holeScroller)
	horizontalPanel:SetWide(#holes * HOLE_WIDTH)

	self.horizontalPanel = horizontalPanel

	local headingPanel = vgui.Create("Panel", horizontalPanel)
	headingPanel:SetSize(#holes * HOLE_WIDTH, Minigolf.PADDING + LOGO_HEIGHT + Minigolf.PADDING - BAR_HEIGHT - Minigolf.PADDING)

	for i, hole in pairs(holes) do
		local column = vgui.Create("Minigolf.ScoreBoardColumn", headingPanel)
		column:SetHeading(true)
		column:SetSize(HOLE_WIDTH, headingPanel:GetTall())
		column:SetText(hole:GetHoleName())
		column:SetPos((i-1) * HOLE_WIDTH, 0)
	end

	currentY = currentY + headingPanel:GetTall()

	local parLabel = vgui.Create("Minigolf.ScoreBoardColumn", self.labelPanel)
	parLabel:SetHeading(true)
	parLabel:Dock(TOP)
	parLabel:SetTall(BAR_HEIGHT)
	parLabel:SetText("PAR")
	parLabel:SetPos(0, 0)

	local parPanel = vgui.Create("Panel", horizontalPanel)
	parPanel:SetSize(#holes * HOLE_WIDTH, BAR_HEIGHT)
	parPanel:SetPos(0, currentY)

	for i, hole in pairs(holes) do
		local column = vgui.Create("Minigolf.ScoreBoardColumn", parPanel)
		column:SetHeading(true)
		column:SetSize(HOLE_WIDTH, parPanel:GetTall())
		column:SetText(hole:GetPar())
		column:SetPos((i-1) * HOLE_WIDTH, 0)
	end

	currentY = currentY + parPanel:GetTall()

	self:LayoutScorePanel(w, h, currentY, #playerLibrary.GetAll() + #Minigolf.Teams.All)
	local countRows = 1

	for teamID, teamData in ipairs(Minigolf.Teams.All)do
		local teamNameLabel = vgui.Create("Minigolf.ScoreBoardColumn", self.nameScrollPanel)
		teamNameLabel:SetHeading(true)
		teamNameLabel:SetBackgroundColor(team.GetColor(teamID))
		teamNameLabel:Dock(TOP)
		teamNameLabel:SetTall(BAR_HEIGHT)
		teamNameLabel:SetText(team.GetName(teamID))

		countRows = self:LayoutTeamInfo(w, h, countRows, teamID) + 1
	end

	self.holeScroller:AddPanel(horizontalPanel)
end

function PANEL:LayoutScorePanel(w, h, currentY, numRows)
	local holes = self:GetOrderedHoles()

	local nameScrollPanel = vgui.Create("DScrollPanel", self.labelPanel)
	nameScrollPanel:Dock(FILL)

	local scoreScrollPanel = vgui.Create("DScrollPanel", self.horizontalPanel)
	scoreScrollPanel:SetSize(#holes * HOLE_WIDTH, h - Minigolf.PADDING - Minigolf.PADDING - BAR_HEIGHT - currentY)
	scoreScrollPanel:SetPos(0, currentY)

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

function PANEL:LayoutTeamInfo(w, h, rowY, teamID)
	local holes = self:GetOrderedHoles()
	local teamPlayers = team.GetPlayers(teamID)

	for teamPlayerIndex, teamPlayer in pairs(teamPlayers)do
		local column = vgui.Create("Minigolf.ScoreBoardColumn", self.nameScrollPanel)
		column:Dock(TOP)
		column:SetTall(BAR_HEIGHT)
		column:SetText(teamPlayer:Nick())

		for i, hole in pairs(holes) do
			local column = vgui.Create("Minigolf.ScoreBoardColumn", self.scorePanel)
			column:SetSize(HOLE_WIDTH, BAR_HEIGHT)
			column:SetPos((i-1) * HOLE_WIDTH, rowY * BAR_HEIGHT)

			local activeTeam = hole:GetNWInt("MiniGolf.ActiveTeam", Minigolf.NO_TEAM_PLAYING)
			
			if(activeTeam == teamPlayer:Team())then
				column:SetHighlight(true)
			end

			-- Also make sure we highlight the last hole
			if(self.lastHole and self.lastHole == hole)then
				column:SetHighlight(true)
			end

			local holeName = hole:GetUniqueHoleName()
			if(self.scoresOverride and self.scoresOverride[holeName])then
				self:SetColumnScoreText(column, self.scoresOverride[holeName], hole:GetPar())
			else
				self:SetColumnScoreText(column, teamPlayer:GetNWInt(holeName .. "Strokes", Minigolf.HOLE_NOT_PLAYED), hole:GetPar())
			end
		end

		rowY = rowY + 1
	end

	return rowY
end

function PANEL:SetColumnScoreText(column, strokes, par)
	if(strokes == Minigolf.HOLE_NOT_PLAYED)then
		column:SetText("")
		column:SetTooltip("The player hasn't played on this hole yet.")
	elseif(strokes == Minigolf.HOLE_DISQUALIFIED)then
		column:SetText("DSQ")
		column:SetTooltip("On this hole the player either ran out of time or has reached the maximum strokes.")
	else
		local relativeToParText = "better than par."

		if(strokes > par)then
			relativeToParText = "worse than par. They should try getting less strokes next time!"
		elseif(strokes == par)then
			relativeToParText = "equal to par."
		end

		column:SetText(strokes)
		column:SetTooltip("The player got " .. tostring(strokes) .. " " .. Minigolf.Text.Pluralize("stroke", strokes) .. ". That is " .. relativeToParText)
	end

	hook.Call("Minigolf.AdjustColumnScore", Minigolf.GM(), column, strokes, par)
end

function PANEL:PerformLayout(w, h)
	-- self.mapLogo:SetPos(Minigolf.PADDING, Minigolf.PADDING)
	-- self.mapLogo:SetSize(LOGO_WIDTH, LOGO_HEIGHT)

	-- Arithmetic written out in full because it's easier to see where the padding is going
	self.holeScroller:SetSize(w - Minigolf.PADDING - Minigolf.PADDING - LOGO_WIDTH - Minigolf.PADDING, h - Minigolf.PADDING - Minigolf.PADDING - BAR_HEIGHT)
	self.holeScroller:SetPos(Minigolf.PADDING + LOGO_WIDTH + Minigolf.PADDING, Minigolf.PADDING + BAR_HEIGHT)

	self.labelPanel:SetSize(w - Minigolf.PADDING - self.holeScroller:GetWide() - Minigolf.PADDING, h - Minigolf.PADDING - LOGO_HEIGHT - Minigolf.PADDING - Minigolf.PADDING)
	self.labelPanel:SetPos(Minigolf.PADDING, Minigolf.PADDING + LOGO_HEIGHT + Minigolf.PADDING)
end

function PANEL:Paint(w, h)
	local teamName = "You are spectating"
	local textColor = Color(255, 255, 255, 255)

	if(LocalPlayer():Team() ~= TEAM_MINIGOLF_SPECTATORS)then
		teamName = "Team: " .. team.GetName(LocalPlayer():Team())
	end

	Derma_DrawBackgroundBlur(self, self.startTime)

	draw.RoundedBox(16, 0, 0, w, h, Color(255,255,255,255))

	draw.SimpleText(teamName, "MinigolfMainBold", w * .5, Minigolf.PADDING * 2, Minigolf.COLOR_PRIMARY, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

	surface.SetDrawColor(255, 255, 255, 255)
	surface.SetMaterial(logoMaterial)

	local logoW, logoH = 256, 256

	surface.DrawTexturedRect(w * .5 - (logoW * .5), -logoH - Minigolf.PADDING, logoW, logoH)

	if(Minigolf.Menus.Scoreboard.lastHole ~= nil)then
		draw.SimpleText("Press your scoreboard key to close this scoreboard", "MinigolfMainBold", w * .5, h + Minigolf.PADDING * 2, Minigolf.COLOR_LIGHT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
end

-- Needed since the + and -showscores bind isn't triggered when we're in the scoreboard opened at a different time
function PANEL:OnKeyCodeReleased(key)
	local scoreKey = "KEY_" .. input.LookupBinding("showscores"):upper()

	-- If the scoreboard key is pressed then close the scoreboard
	if(key == _G[scoreKey] or key == KEY_ESCAPE)then
		if(IsValid(Minigolf.Menus.Scoreboard))then
			Minigolf.Menus.Scoreboard:Remove()
			gui.HideGameUI()
		end
	end
end

vgui.Register("Minigolf.ScoreBoard", PANEL, "EditablePanel")

-- Called to inform the player has stopped playing a hole
net.Receive("Minigolf.PlayerShowScoreboard", function()
	local hole = net.ReadEntity()
	local holeScores = net.ReadTable()
	local clearLocalScores = net.ReadBool()

	--TODO: Be able to use mouse, however for game fluidity closing with TAB is preferable
	if(not IsValid(Minigolf.Menus.Scoreboard))then
		Minigolf.Menus.Scoreboard = vgui.Create("Minigolf.ScoreBoard")
		Minigolf.Menus.Scoreboard.lastHole = hole
		Minigolf.Menus.Scoreboard.scoresOverride = holeScores

		Minigolf.Menus.Scoreboard:MakePopup()
		Minigolf.Menus.Scoreboard:Restore()
	end

	if(clearLocalScores)then
		for _, hole in pairs(ents.FindByClass("minigolf_hole_start")) do
			hole._Strokes = nil
		end
	end
end)

-- When the scoreboard needs to be shown
hook.Add("ScoreboardShow", "Minigolf.ScoreboardShowBoard", function()
	if(IsValid(Minigolf.Menus.Scoreboard))then
		Minigolf.Menus.Scoreboard:Remove()

		return false
	end

	Minigolf.Menus.Scoreboard = vgui.Create("Minigolf.ScoreBoard")
	Minigolf.Menus.Scoreboard:MakePopup()
	Minigolf.Menus.Scoreboard:Restore()

	-- Override default
	return false
end)

-- When the scoreboard can be be hidden
hook.Add("ScoreboardHide", "Minigolf.ScoreboardHideBoard", function()
	if(IsValid(Minigolf.Menus.Scoreboard))then
		Minigolf.Menus.Scoreboard:Close()
	end
end)