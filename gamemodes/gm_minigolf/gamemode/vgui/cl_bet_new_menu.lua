-- local MENU_KEY = KEY_B
-- local BAR_HEIGHT = Minigolf.PADDING * 4
-- local scrW, scrH = ScrW(), ScrH()
-- local PANEL = {}

-- local playerLibrary = player

-- local hasOpenedFirstTime = false
-- local BET_OPEN_INTERVAL = 1.5
-- local lastOpen = 0

-- local function hideMenu()
-- 	Minigolf.Menus.Betting:Remove()
-- 	Minigolf.Menus.Betting = nil
-- end

-- local function showMenu(justLeftOtherTeam)
-- 	if(IsValid(Minigolf.Menus.Betting))then
-- 		hideMenu()
-- 	end

-- 	Minigolf.Menus.Betting = vgui.Create("Minigolf.BetMenu")
-- 	Minigolf.Menus.Betting:MakePopup()
-- end

-- -- Add a command to open the menu
-- concommand.Add("menu_betting", showMenu)

-- hook.Add("PlayerButtonDown", "Minigolf.ShowBetMenuOnKeyPress", function(player, button)
-- 	if((not PS.ShopMenu or not PS.ShopMenu:IsVisible())
-- 	and button == MENU_KEY
-- 	and player == LocalPlayer()
-- 	and (UnPredictedCurTime() - lastOpen) > BET_OPEN_INTERVAL)then
-- 		lastOpen = UnPredictedCurTime()
-- 		showMenu()
-- 	end
-- end)

-- function PANEL:Init()
-- 	local width = math.max(450, scrW * .3)
-- 	self:SetWide(width)

-- 	self.startTime = UnPredictedCurTime()

-- 	local actionButton = vgui.Create("MinigolfActionButton", self)
-- 	actionButton:SetText("View active bets")
-- 	actionButton:SizeToContents()
-- 	actionButton:SetSize(actionButton:GetWide() + (Minigolf.PADDING * 2), actionButton:GetTall() + (Minigolf.PADDING))
-- 	actionButton:SetPos(Minigolf.PADDING, Minigolf.PADDING)
-- 	actionButton.DoClick = function(btn)
-- 		self:Remove()
-- 		if(IsValid(Minigolf.Menus.Betting))then
-- 			Minigolf.Menus.Betting:Remove()
-- 		end
	
-- 		Minigolf.Menus.Betting = vgui.Create("Minigolf.BetOverviewMenu", GetHUDPanel())
-- 		Minigolf.Menus.Betting:MakePopup()
-- 	end
-- 	self.actionButton = actionButton
	
-- 	local closeButton = vgui.Create("MinigolfCloseButton", self)
-- 	closeButton.DoClick = function(btn)
-- 		self:Remove()
-- 	end
-- 	closeButton:SetPos(width - Minigolf.PADDING - closeButton:GetWide(), Minigolf.PADDING)
-- 	self.closeButton = closeButton
	
-- 	local infoLabel = vgui.Create("DLabel", self)
-- 	infoLabel:SetPos(Minigolf.PADDING, BAR_HEIGHT + Minigolf.PADDING)
-- 	infoLabel:SetText("Early betting system that needs much improvement. Please pay attention to your betting and report problems and suggestions to a developer.")
-- 	infoLabel:SetTextColor(Minigolf.COLOR_DARK)
-- 	infoLabel:SetAutoStretchVertical(true)
-- 	infoLabel:SetWide(width - Minigolf.PADDING * 2)
-- 	infoLabel:SetWrap(true)
	
-- 	local posX, posY = infoLabel:GetPos()

-- 	local amountLabel = vgui.Create("DLabel", self)
-- 	amountLabel:SetPos(Minigolf.PADDING, posY + Minigolf.PADDING + infoLabel:GetTall() + Minigolf.PADDING)
-- 	amountLabel:SetText("Bet this many tokens:")
-- 	amountLabel:SetTextColor(Minigolf.COLOR_DARK)
-- 	amountLabel:SizeToContents()
	
-- 	local posX, posY = amountLabel:GetPos()
-- 	local offsetX = posX + amountLabel:GetWide() + Minigolf.PADDING
-- 	local amountEntry = vgui.Create("DTextEntry", self)
-- 	amountEntry:SetEditable(true)
-- 	amountEntry:SetText("0")
-- 	amountEntry:SetEditable(true)
-- 	amountEntry:SetPos(offsetX, posY)
-- 	amountEntry:SetWide(width - offsetX - Minigolf.PADDING)
-- 	amountEntry:SetUpdateOnType(true)
-- 	amountEntry:SetNumeric(true)

-- 	-- Also don't allow . or -
-- 	amountEntry.OnValueChange = function(amountEntry, value)
-- 		for stringMatch in string.gmatch(value, "[^%d]+") do
-- 			local oldCaretPos = amountEntry:GetCaretPos()
-- 			amountEntry:SetText(value:Replace(stringMatch, ""))
-- 			amountEntry:SetCaretPos(oldCaretPos - 1)
-- 		end
-- 	end

-- 	self.amountEntry = amountEntry
	
-- 	local targetLabel = vgui.Create("DLabel" , self)
-- 	targetLabel:SetPos(Minigolf.PADDING, posY + amountEntry:GetTall() + Minigolf.PADDING)
-- 	targetLabel:SetText("That this player:")
-- 	targetLabel:SetTextColor(Minigolf.COLOR_DARK)
-- 	targetLabel:SizeToContents()

-- 	posX, posY = targetLabel:GetPos()
-- 	offsetX = posX + targetLabel:GetWide() + Minigolf.PADDING
	
-- 	local userEntry = vgui.Create("DComboBox", self)
-- 	userEntry:SetValue("<user to bet on>")
-- 	userEntry:SetPos(offsetX, posY)
-- 	userEntry:SetWide(width - offsetX - Minigolf.PADDING)
	
-- 	for _, ply in pairs(playerLibrary.GetAll()) do
-- 		userEntry:AddChoice(ply:Nick(), ply)
-- 	end
	
-- 	self.userEntry = userEntry
	
-- 	posX, posY = userEntry:GetPos()
-- 	offsetX = posX + userEntry:GetWide() + Minigolf.PADDING
	
-- 	local holeLabel = vgui.Create("DLabel" , self)
-- 	holeLabel:SetPos(Minigolf.PADDING, posY + userEntry:GetTall() + Minigolf.PADDING)
-- 	holeLabel:SetText("On this hole:")
-- 	holeLabel:SetTextColor(Minigolf.COLOR_DARK)
-- 	holeLabel:SizeToContents()

-- 	posX, posY = holeLabel:GetPos()
-- 	offsetX = posX + holeLabel:GetWide() + Minigolf.PADDING
	
-- 	local holeEntry = vgui.Create("DComboBox", self)
-- 	holeEntry:SetValue("<hole that they'll get the given score on>")
-- 	holeEntry:SetPos(offsetX, posY)
-- 	holeEntry:SetWide(width - offsetX - Minigolf.PADDING)
	
-- 	for _, hole in pairs(ents.FindByClass("minigolf_hole_start")) do
-- 		holeEntry:AddChoice(hole:GetHoleName(), hole)
-- 	end
	
-- 	self.holeEntry = holeEntry
	
-- 	posX, posY = holeEntry:GetPos()

-- 	local scoreEntry = vgui.Create("DNumSlider", self)
-- 	scoreEntry:SetText("Will get this many strokes:")
-- 	scoreEntry:SetMin(1)
-- 	scoreEntry:SetMax(256)
-- 	scoreEntry:SetValue(1)
-- 	scoreEntry:SetDecimals(0)
-- 	scoreEntry:SetPos(Minigolf.PADDING, posY + holeEntry:GetTall() + Minigolf.PADDING)
-- 	scoreEntry:SetSize(width - Minigolf.PADDING - Minigolf.PADDING, 25)
-- 	scoreEntry.Label:SetTextColor(Minigolf.COLOR_DARK)
-- 	scoreEntry.Label:SizeToContents()

-- 	holeEntry.OnSelect = function(holeEntry, index, value, data)
-- 		scoreEntry:SetMax(data:GetMaxStrokes() - 1)
-- 	end
	
-- 	self.scoreEntry = scoreEntry
	
-- 	posX, posY = scoreEntry:GetPos()

-- 	local betButton = vgui.Create("DButton", self)
-- 	betButton:SetSize(width - (Minigolf.PADDING * 2), 50)
-- 	betButton:SetPos(Minigolf.PADDING, posY + Minigolf.PADDING + scoreEntry:GetTall())
-- 	betButton:SetText("Place Bet")
-- 	betButton.DoClick = function()
-- 		local _, targetPlayer = userEntry:GetSelected()
-- 		local betAmount = tonumber(amountEntry:GetValue())
-- 		local expectedScore = scoreEntry:GetValue()
-- 		local _, targetHole = holeEntry:GetSelected()

-- 		if(not targetPlayer)then
-- 			Minigolf.Messages.Print("No Player selected to bet on!", nil, Minigolf.TEXT_EFFECT_DANGER)
-- 			return
-- 		end

-- 		if(not betAmount)then
-- 			Minigolf.Messages.Print("No valid bet amount given!", nil, Minigolf.TEXT_EFFECT_DANGER)
-- 			return
-- 		end

-- 		if(not LocalPlayer():PS_HasPoints(betAmount))then
-- 			Minigolf.Messages.Print("You do not have this many points!", nil, Minigolf.TEXT_EFFECT_DANGER)
-- 			return
-- 		end
		
-- 		if(not expectedScore or expectedScore == "")then
-- 			Minigolf.Messages.Print("No expected score given!", nil, Minigolf.TEXT_EFFECT_DANGER)
-- 			return
-- 		end

-- 		if(not targetHole)then
-- 			Minigolf.Messages.Print("No target hole selected!", nil, Minigolf.TEXT_EFFECT_DANGER)
-- 			return
-- 		end

-- 		RunConsoleCommand("bet_place", (targetPlayer:AccountID() or player:UserID()), betAmount, expectedScore, targetHole:GetUniqueHoleName())
-- 	end

-- 	self.betButton = betButton

-- 	self:SetTall(Minigolf.PADDING + self.betButton:GetTall() + Minigolf.PADDING + self.userEntry:GetTall() + Minigolf.PADDING + self.amountEntry:GetTall() + Minigolf.PADDING + self.scoreEntry:GetTall() + Minigolf.PADDING + self.holeEntry:GetTall() + Minigolf.PADDING + infoLabel:GetTall() + Minigolf.PADDING + Minigolf.PADDING + BAR_HEIGHT)
-- 	self:Center()
-- end

-- function PANEL:Think()	
-- 	local amount = tonumber(self.amountEntry:GetValue())
-- 	self.userEntry:SetEnabled(amount and amount > 0)
-- 	local _, user = self.userEntry:GetSelected()
-- 	self.holeEntry:SetEnabled(IsValid(user))
-- 	local _, hole = self.userEntry:GetSelected()
-- 	self.scoreEntry:SetEnabled(IsValid(hole))
-- 	self.betButton:SetEnabled(self.scoreEntry:IsEnabled())
-- end

-- function PANEL:Paint(w, h)
-- 	Derma_DrawBackgroundBlur(self, self.startTime)

-- 	draw.RoundedBox(16, 0, 0, w, h, Color(255,255,255,255))

-- 	draw.SimpleText("Place bets on upcoming players", "MinigolfMainBold", w * .5, Minigolf.PADDING * 2, Minigolf.COLOR_PRIMARY, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
-- end

-- function PANEL:OnKeyCodeReleased(key)
-- 	if(key == KEY_ESCAPE or (self:HasFocus() and key == MENU_KEY and CurTime() - self.startTime > 1))then
-- 		hideMenu()
--     gui.HideGameUI()
-- 	end
-- end

-- vgui.Register("Minigolf.BetMenu", PANEL, "EditablePanel")