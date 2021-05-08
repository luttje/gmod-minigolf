local PANEL = {}
local playerLibrary = player

local function getActiveHole()
	for _, start in ipairs(ents.FindByClass("minigolf_hole_start"))do
		if(start:GetNWInt("ActiveTeam", -1) == LocalPlayer():Team())then
			return start
		end
	end
end

function PANEL:Init()
	self:SetSize(ScrW(), ScrH())
end

function PANEL:OnScreenSizeChanged(oldWidth, oldHeight)
	self:SetSize(ScrW(), ScrH())
end

function PANEL:PerformLayout(width, height)
end

function PANEL:Think()
	-- Draw active hole
	self.activeHole = getActiveHole()

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
		table.insert(texts, "Press 'T' or type /team to open the team menu")
		--table.insert(texts, "Press 'B' or type /bet to see and place bets")
		-- table.insert(texts, {"MinigolfMain", "You can disable hints in the config menu, just type /config"}) -- TODO: Finish the config menu Tori :)
	end

	for _,text in pairs(texts) do
		local font = "MinigolfMainSmall"
		if(type(text) == "table")then
			font = text[1]
			text = text[2]
		end

		draw.SimpleTextOutlined(text, font, w - PADDING, PADDING + currentY, COLOR_LIGHT, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP,  1, COLOR_DARK)
		local textWidth, textHeight = surface.GetTextSize(text)
		
		currentY = currentY + textHeight + PADDING
	end

	-- Draw the timelimit for players on our team
	for _, player in pairs(playerLibrary.GetAll()) do
		if(LocalPlayer():Team() == player:Team())then
			if((player._LimitTimeLeft and player._LimitTimeLeft > UnPredictedCurTime()) or LocalPlayer()._LimitTimeLeftForSwap)then
				if(not self.activeHole)then
					goto endOfLoop
				end

				if(not IsValid(self.activeHolePanel))then
					self.activeHolePanel = vgui.Create("Minigolf.HolePanel")
					self.activeHolePanel:SetPaintedManually(true)
				end
				
				self.activeHolePanel:SetHole(self.activeHole)

				self.activeHolePanel:SetPos(w - self.activeHolePanel:GetWide() - PADDING, h - self.activeHolePanel:GetTall() - PADDING)
				
				if(LocalPlayer()._LimitTimeLeftForSwap)then
					local time = math.max(0, math.Round(LocalPlayer()._LimitTimeLeft - UnPredictedCurTime()))
					self.activeHolePanel:SetSwapping(time)
					self.activeHolePanel:PaintManual()
					
					goto endOfLoop
				else
					self.activeHolePanel:SetSwapping(nil)
				end

				local time = math.max(0, math.Round(player._LimitTimeLeft - UnPredictedCurTime()))

				self.activeHolePanel:SetPlaying(time)
				self.activeHolePanel:PaintManual()
			end
		end

		::endOfLoop::
	end
end

vgui.Register("Minigolf.HUD", PANEL, "PANEL")
