local BAR_HEIGHT = Minigolf.PADDING * 2
local HOLE_WIDTH = 125
local playerLibrary = player

DEFINE_BASECLASS("Minigolf.ScoreCard")

---@class Minigolf.ScoreBoard : EditablePanel
local PANEL = {}

function PANEL:GetNumRows()
	return #playerLibrary.GetAll() + #Minigolf.Teams.All
end

function PANEL:LoadHoles(w, h)
	local horizontalPanel, currentY = self:LayoutBaseHoles(w, h)

	local countRows = 1

	local sortedTeams = {}

	for _, teamData in pairs(Minigolf.Teams.All) do
		table.insert(sortedTeams, teamData)
	end

	-- Sort alphabetically by Team Name, ensure 'Spectators' is last
	table.sort(sortedTeams, function(a, b)
		if (a.ID == TEAM_MINIGOLF_SPECTATORS) then
			return false
		elseif (b.ID == TEAM_MINIGOLF_SPECTATORS) then
			return true
		end

		return team.GetName(a.ID) < team.GetName(b.ID)
	end)

	for i, teamData in ipairs(sortedTeams) do
		local teamID = teamData.ID
		local teamNameLabel = vgui.Create("Minigolf.ScoreCardColumn", self.nameScrollPanel)
		teamNameLabel:SetHeading(true)
		teamNameLabel:SetBackgroundColor(team.GetColor(teamID))
		teamNameLabel:Dock(TOP)
		teamNameLabel:SetTall(BAR_HEIGHT)
		teamNameLabel:SetText(team.GetName(teamID))

		countRows = self:LayoutTeamInfo(w, h, countRows, teamID) + 1
	end

	self.holeScroller:AddPanel(horizontalPanel)
end

function PANEL:LayoutTeamInfo(w, h, rowY, teamID)
	local holes = self:GetOrderedHoles()
	local teamPlayers = team.GetPlayers(teamID)

	for teamPlayerIndex, teamPlayer in pairs(teamPlayers) do
		local column = vgui.Create("Minigolf.ScoreCardColumn", self.nameScrollPanel)
		column:Dock(TOP)
		column:SetTall(BAR_HEIGHT)
		column:SetText(teamPlayer:Nick())

		for i, hole in pairs(holes) do
			local column = vgui.Create("Minigolf.ScoreCardColumn", self.scorePanel)
			column:SetSize(HOLE_WIDTH, BAR_HEIGHT)
			column:SetPos((i - 1) * HOLE_WIDTH, rowY * BAR_HEIGHT)

			local activeTeam = hole:GetNWInt("Minigolf.ActiveTeam", Minigolf.NO_TEAM_PLAYING)

			if (activeTeam == teamPlayer:Team()) then
				column:SetHighlight(true)
			end

			-- Also make sure we highlight the last hole
			if (self.lastHole and self.lastHole == hole) then
				column:SetHighlight(true)
			end

			local holeName = hole:GetUniqueHoleName()
			if (self.scoresOverride and self.scoresOverride[holeName]) then
				self:SetColumnScoreText(column, self.scoresOverride[holeName], hole:GetPar())
			else
				self:SetColumnScoreText(column, teamPlayer:GetNWInt(holeName .. "Strokes", Minigolf.HOLE_NOT_PLAYED),
					hole:GetPar())
			end
		end

		rowY = rowY + 1
	end

	return rowY
end

function PANEL:Paint(w, h)
	BaseClass.Paint(self, w, h)

	if (Minigolf.Menus.Scoreboard.lastHole ~= nil) then
		draw.SimpleText("Press your scoreboard key to close this scoreboard", "MinigolfMainBold", w * .5,
			h + Minigolf.PADDING * 2, Minigolf.COLOR_LIGHT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
end

-- Needed since the + and -showscores bind isn't triggered when we're in the scoreboard opened at a different time
function PANEL:OnKeyCodeReleased(key)
	local scoreKey = "KEY_" .. input.LookupBinding("showscores"):upper()

	-- If the scoreboard key is pressed then close the scoreboard
	if (key == _G[scoreKey] or key == KEY_ESCAPE) then
		if (IsValid(Minigolf.Menus.Scoreboard)) then
			Minigolf.Menus.Scoreboard:Remove()
			gui.HideGameUI()
		end
	end
end

vgui.Register("Minigolf.ScoreBoard", PANEL, "Minigolf.ScoreCard")

-- Called to inform the player has stopped playing a hole
net.Receive("Minigolf.PlayerShowScoreboard", function()
	local hole = net.ReadEntity()
	local holeScores = net.ReadTable()
	local clearLocalScores = net.ReadBool()

	--TODO: Be able to use mouse, however for game fluidity closing with TAB is preferable
	if (not IsValid(Minigolf.Menus.Scoreboard)) then
		Minigolf.Menus.Scoreboard = vgui.Create("Minigolf.ScoreBoard")
		Minigolf.Menus.Scoreboard.lastHole = hole
		Minigolf.Menus.Scoreboard.scoresOverride = holeScores

		Minigolf.Menus.Scoreboard:MakePopup()
		Minigolf.Menus.Scoreboard:Restore()
	end

	if (clearLocalScores) then
		for _, hole in pairs(ents.FindByClass("minigolf_hole_start")) do
			hole._Strokes = nil
		end
	end
end)

-- When the scoreboard needs to be shown
hook.Add("ScoreboardShow", "Minigolf.ScoreboardShowBoard", function()
	if (IsValid(Minigolf.Menus.Scoreboard)) then
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
	if (IsValid(Minigolf.Menus.Scoreboard)) then
		Minigolf.Menus.Scoreboard:Close()
	end
end)
