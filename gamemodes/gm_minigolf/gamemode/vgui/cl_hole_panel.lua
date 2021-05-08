
local PANEL = {}
local panelWidth = 512

local playWithTeamText = string.format("Press '%s' to start playing this hole with your team", input.LookupBinding("use"):upper())

function PANEL:Init()
	local holeNameLabel = vgui.Create("DLabel", self)
	holeNameLabel:SetFont("MinigolfCardMain")
	holeNameLabel:SetTextColor(COLOR_LIGHT)

	local holeDescriptionLabel = vgui.Create("DLabel", self)
	holeDescriptionLabel:SetFont("MinigolfCardItalic")
	holeDescriptionLabel:SetTextColor(COLOR_DARK)

	local holeParLabel = vgui.Create("DLabel", self)
	holeParLabel:SetFont("MinigolfCardSub")
	holeParLabel:SetTextColor(COLOR_DARK)

	local holeMaxStrokesLabel = vgui.Create("DLabel", self)
	holeMaxStrokesLabel:SetFont("MinigolfCardSub")
	holeMaxStrokesLabel:SetTextColor(COLOR_DARK)

	local holeMaxPitchLabel = vgui.Create("DLabel", self)
	holeMaxPitchLabel:SetFont("MinigolfCardSub")
	holeMaxPitchLabel:SetTextColor(COLOR_DARK)

	local holeTimeLimitLabel = vgui.Create("DLabel", self)
	holeTimeLimitLabel:SetFont("MinigolfCardSub")
	holeTimeLimitLabel:SetTextColor(COLOR_DARK)

	local hintLabel = vgui.Create("DLabel", self)
	hintLabel:SetFont("MinigolfCardSub")
	hintLabel:SetText(playWithTeamText)
	hintLabel:SetTextColor(COLOR_PRIMARY)
	hintLabel:SizeToContents()

	self.holeNameLabel = holeNameLabel
	self.holeDescriptionLabel = holeDescriptionLabel
	self.holeParLabel = holeParLabel
	self.holeMaxStrokesLabel = holeMaxStrokesLabel
	self.holeMaxPitchLabel = holeMaxPitchLabel
	self.holeTimeLimitLabel = holeTimeLimitLabel
	self.hintLabel = hintLabel
end

function PANEL:PositionLabels()
	local holeDescVisible = self.holeDescriptionLabel:GetText() ~= ""
	local currentY = PADDING

	self.holeNameLabel:SizeToContents()
	self.holeNameLabel:SetPos(self:GetWide() * .5 - (self.holeNameLabel:GetWide() * .5), currentY)
	currentY = currentY + self.holeNameLabel:GetTall() + (PADDING * 2)

	if(holeDescVisible)then
		self.holeDescriptionLabel:SizeToContents()
		self.holeDescriptionLabel:SetPos(self:GetWide() * .5 - (self.holeDescriptionLabel:GetWide() * .5), currentY)
		currentY = currentY + self.holeDescriptionLabel:GetTall() + PADDING
	end

	self.holeParLabel:SizeToContents()
	self.holeParLabel:SetPos(self:GetWide() * .5 - (self.holeParLabel:GetWide() * .5), currentY)
	currentY = currentY + self.holeParLabel:GetTall() + PADDING

	self.holeMaxStrokesLabel:SizeToContents()
	self.holeMaxStrokesLabel:SetPos(self:GetWide() * .5 - (self.holeMaxStrokesLabel:GetWide() * .5), currentY)
	currentY = currentY + self.holeMaxStrokesLabel:GetTall() + PADDING

	self.holeMaxPitchLabel:SizeToContents()
	self.holeMaxPitchLabel:SetPos(self:GetWide() * .5 - (self.holeMaxPitchLabel:GetWide() * .5), currentY)
	currentY = currentY + self.holeMaxPitchLabel:GetTall() + PADDING

	self.holeTimeLimitLabel:SizeToContents()
	self.holeTimeLimitLabel:SetPos(self:GetWide() * .5 - (self.holeTimeLimitLabel:GetWide() * .5), currentY)
	currentY = currentY + self.holeTimeLimitLabel:GetTall() + PADDING

	self.hintLabel:SizeToContents()
	self.hintLabel:SetPos(self:GetWide() * .5 - (self.hintLabel:GetWide() * .5), currentY)
	currentY = currentY + self.hintLabel:GetTall() + PADDING

	self.calculatedY = currentY
end

function PANEL:SetHole(hole)
	self._Hole = hole

	self:RebuildHoleInfo()
end

function PANEL:RebuildHoleInfo()
	local hole = self._Hole

	if(not IsValid(hole))then
		-- Ignore holes we haven't received in a networkmessage yet.
		return
	end

	local holeDesc = hole:GetNWString("HoleDescription", "")
	local holeDescVisible = holeDesc ~= ""

	self.holeNameLabel:SetText(hole:GetHoleName())
	self.holeDescriptionLabel:SetText(holeDesc)
	self.holeParLabel:SetText("Par: " .. hole:GetPar())
	self.holeMaxStrokesLabel:SetText("Maximum strokes: " .. hole:GetMaxStrokes())

	local pitch = hole:GetMaxPitch()

	if(pitch == 0)then
		self.holeMaxPitchLabel:SetText("You are prohibited from making lob shots here.")
	else
		self.holeMaxPitchLabel:SetText("You can make lob shots at a maximum pitch of " .. pitch .. "° here.")
	end

	local strokes = LocalPlayer():GetNWInt(hole:GetUniqueHoleName() .. "Strokes", HOLE_NOT_PLAYED)
	local activeTeam = hole:GetNWInt("ActiveTeam", -1)

	if(strokes > 0)then
		self.hintLabel:SetText("You already played this hole and got " .. strokes .. " " .. Minigolf.Text.Pluralize("stroke", strokes) .. " on it!")
	elseif(self.currentSwappingTime)then
		self:SetAlpha(200 + (55 * math.sin(CurTime())))
		self.hintLabel:SetText("Waiting for a team member to start playing\nYou have " .. self.currentSwappingTime .. " seconds to switch player!")
		self.hintLabel:SetContentAlignment(5) -- TODO: not working
	elseif(strokes == HOLE_DISQUALIFIED)then
		self.hintLabel:SetText("You already played this hole and got disqualified on it!")
	elseif(activeTeam == -1 and strokes == HOLE_NOT_PLAYED)then
			self.hintLabel:SetText(playWithTeamText)
	elseif(activeTeam ~= LocalPlayer():Team())then
		self.hintLabel:SetText(team.GetName(activeTeam) .. " is currently playing this hole")
	elseif(activeTeam == LocalPlayer():Team())then
		self.hintLabel:SetText("Your team is currently playing this hole.")
	else
		self.hintLabel:SetText(":)") -- TODO: logic error in code above
	end
	
	if(self.currentTime)then
		self.holeTimeLimitLabel:SetText(tostring(self.currentTime) .. " seconds remaining (Time Limit: " .. hole:GetLimit() .. " seconds)")
		self.holeTimeLimitLabel:SizeToContents()
	else
		self.holeTimeLimitLabel:SetText("Time Limit: " .. hole:GetLimit() .. " seconds")	
	end
	
	self.hintLabel:SizeToContents()
	self.holeNameLabel:SizeToContents()
	self.holeDescriptionLabel:SizeToContents()
	self.holeParLabel:SizeToContents()
	self.holeMaxStrokesLabel:SizeToContents()
	self.holeMaxPitchLabel:SizeToContents()
	self.holeTimeLimitLabel:SizeToContents()

	self:PositionLabels()
	self:SetSize(panelWidth, self.calculatedY)
end

function PANEL:Think()
	if(not self._Hole)then
		return
	end

	self:RebuildHoleInfo()
end

function PANEL:SetPlaying(time)
	self.currentTime = time
end

function PANEL:SetSwapping(time)
	self.currentSwappingTime = time
end

function PANEL:Paint(w, h)
	draw.RoundedBox(5, 0, 0, w, h, COLOR_LIGHT)
	draw.RoundedBox(5, 0, 0, w, PADDING * 2 + self.holeNameLabel:GetTall(), COLOR_PRIMARY)
end

vgui.Register("Minigolf.HolePanel", PANEL, "PANEL")