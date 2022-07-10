local PANEL = {}

function PANEL:Init()
	self:SetSize(ScrW(), ScrH())
end

function PANEL:OnScreenSizeChanged(oldWidth, oldHeight)
	self:SetSize(ScrW(), ScrH())
end

function PANEL:PerformLayout(width, height)
end

function PANEL:Think()
	-- TODO: Don't do this so often
	self.activeHole = Minigolf.Holes.GetActive()

	-- If PAC is installed and the editor is opened, get out of the way
	if(pace and pace.Active and self:GetPos() ~= ScrW())then
		self:SetPos(ScrW(), 0)
	elseif(self:GetPos() ~= 0)then
		self:SetPos(0, 0)
	end
end

function PANEL:Paint(w, h)
	local currentY = 0
	local texts = {}

	if(Minigolf.Convars.ShowHints:GetBool())then
		hook.Call("Minigolf.AdjustHintsTexts", Minigolf.GM(), texts)
	end

	for _,text in pairs(texts) do
		local font = "MinigolfMainSmall"
		if(type(text) == "table")then
			font = text[1]
			text = text[2]
		end

		draw.SimpleTextOutlined(text, font, w - Minigolf.PADDING, Minigolf.PADDING + currentY, Minigolf.COLOR_LIGHT, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP,  1, Minigolf.COLOR_DARK)
		local textWidth, textHeight = surface.GetTextSize(text)
		
		currentY = currentY + textHeight + Minigolf.PADDING
	end

	if(not IsValid(self.activeHole))then
		return
	end

	if(not IsValid(self.activeHolePanel))then
		self.activeHolePanel = vgui.Create("Minigolf.HolePanel")
		self.activeHolePanel:SetPaintedManually(true)
	end
	
	self.activeHolePanel:SetHole(self.activeHole)
	self.activeHolePanel:SetPos(w - self.activeHolePanel:GetWide() - Minigolf.PADDING, h - self.activeHolePanel:GetTall() - Minigolf.PADDING)

	local adjustHolePanel = hook.Call("Minigolf.AdjustHolePanel", Minigolf.GM(), self.activeHolePanel)
	if(adjustHolePanel == true)then
		return
	end

	local time = math.max(0, math.Round(LocalPlayer()._LimitTimeLeft - UnPredictedCurTime()))
	self.activeHolePanel:SetPlaying(time)
	self.activeHolePanel:PaintManual()
end

vgui.Register("Minigolf.HUD", PANEL, "PANEL")
