local scrW, scrH = ScrW(), ScrH()
local PANEL = {}

function PANEL:BuildTeamMenu(isEditting)
	local width = scrW * .25
	self:SetWide(width)

	local closeButton = vgui.Create("MinigolfCloseButton", self)
	closeButton.DoClick = function(btn)
		self:Remove()
	end
	closeButton:SetPos(width - PADDING - closeButton:GetWide(), PADDING)
	self.closeButton = closeButton
	
	self.startTime = UnPredictedCurTime()
	
	local teamLabel = vgui.Create("DLabel", self)
	teamLabel:SetPos(PADDING, 22 + PADDING)
	teamLabel:SetText("Your team name:")
	teamLabel:SetTextColor(COLOR_DARK)
	teamLabel:SizeToContents()
	
	local posX, posY = teamLabel:GetPos()
	local offsetX = posX + teamLabel:GetWide() + PADDING
	local teamEntry = vgui.Create("DTextEntry", self)
	teamEntry:SetEditable(true)
	teamEntry:SetPos(offsetX, posY)
	teamEntry:SetWide(width - offsetX - PADDING)

	self.teamEntry = teamEntry
	
	local passwordLabel = vgui.Create("DLabel" , self)
	passwordLabel:SetPos(PADDING, posY + teamEntry:GetTall() + PADDING)
	passwordLabel:SetText("Password (enter nothing to keep the same):")
	passwordLabel:SetTextColor(COLOR_DARK)
	passwordLabel:SizeToContents()

	posX, posY = passwordLabel:GetPos()
	offsetX = posX + passwordLabel:GetWide() + PADDING
	
	local passwordEntry = vgui.Create("DTextEntry", self)
	passwordEntry:SetEditable(true)
	passwordEntry:SetPos(offsetX, posY)
	passwordEntry:SetWide(width - offsetX - PADDING)
	
	self.passwordEntry = passwordEntry
	
  posX, posY = passwordLabel:GetPos()

	local colorLabel = vgui.Create("DLabel" , self)
	colorLabel:SetPos(PADDING, posY + passwordLabel:GetTall() + PADDING)
	colorLabel:SetText("Team color:")
	colorLabel:SetTextColor(COLOR_DARK)
  colorLabel:SizeToContents()
  self.colorLabel = colorLabel
  
  local colorPicker = vgui.Create("DColorMixer", self)
  colorPicker:SetPalette(false)
  colorPicker:SetAlphaBar(false)
  colorPicker:SetWangs(false)
  colorPicker:SetSize(width - PADDING - PADDING - colorLabel:GetWide() - PADDING, 128)
  colorPicker:SetPos(width - colorPicker:GetWide() - PADDING, posY + passwordLabel:GetTall() + PADDING)

  colorPicker.ValueChanged = function(colorPicker, color)
    -- color table doesn't have Color metatable (known Gmod bug mentioned @ https://wiki.facepunch.com/gmod/DColorMixer:ValueChanged)
    self.teamColor = Color(color.r, color.g, color.b)
  end

  posX, posY = colorPicker:GetPos()

  local lastHeight = 0
  
  if(isEditting)then
    local teamID = LocalPlayer():Team()
    teamEntry:SetValue(team.GetName(teamID))

    self.teamColor = team.GetColor(teamID)
    colorPicker:SetColor(self.teamColor)
    colorPicker:ValueChanged(self.teamColor)

    local teamList = vgui.Create("DListView", self)
    teamList:SetPos(PADDING, posY + PADDING + colorPicker:GetTall())
    teamList:SetSize(width - PADDING * 2, 100)
    teamList:SetMultiSelect( false )
    teamList:AddColumn("Player")
    teamList:AddColumn("SteamID")
    teamList:AddColumn("Rank")
    teamList.OnRowRightClick = function(teamList, lineID, line)
      local name = line:GetColumnText(1)
      local steamID = line:GetColumnText(2)
      local rankText = line:GetColumnText(3)
      
      local contextMenu = DermaMenu()

      if(LocalPlayer():GetTeamLeader())then
        if(rankText:len() == 0)then
          local promoteButton = contextMenu:AddOption("Promote to team leader")
          promoteButton:SetIcon("icon16/award_star_gold_1.png")
          promoteButton.DoClick = function()
            RunConsoleCommand("team_set_rank", steamID, "leader")
          end
        else
          local demoteButton = contextMenu:AddOption("Demote to team member")
          demoteButton:SetIcon("icon16/user.png")
          demoteButton.DoClick = function()
            RunConsoleCommand("team_set_rank", steamID, "member")
          end
        end
      end

      local kickButton = contextMenu:AddOption("Kick from team")
      kickButton:SetIcon("icon16/door_out.png")
      kickButton.DoClick = function()
        Derma_Query("Are you sure you wish to kick this player?", "Kicking " .. name, 
        "Yes, kick this player",
        function()
          RunConsoleCommand("team_kick", steamID)
        end,
        "No, let them stay")
      end
      
      contextMenu:Open()
    end
    teamList.DoDoubleClick = teamList.OnRowRightClick

    for _, teamMember in pairs(team.GetPlayers(teamID)) do
      teamList:AddLine(teamMember:Nick(), teamMember:SteamID(), teamMember:GetTeamLeader() and "Team Leader" or "")
    end

    posX, posY = teamList:GetPos()

    local leaveButton = vgui.Create("DButton", self)
    leaveButton:SetPos(PADDING, posY + PADDING + teamList:GetTall())
    leaveButton:SetText("Leave Team")
    leaveButton:SizeToContents()
    leaveButton.DoClick = function()
      -- You didly sure?
      Derma_Query("You are about to leave the team. Are you sure?", "Leave Team", 
      "Yes, I want to leave", 
      function()
        RunConsoleCommand("team_leave")
        self:Remove()
      end, 
      "No let me stay")
    end

    self.leaveButton = leaveButton

    posX, posY = leaveButton:GetPos()
	
    local teamButton = vgui.Create("DButton", self)
    teamButton:SetSize(width - (PADDING * 2), 50)
    teamButton:SetPos(PADDING, posY + PADDING + leaveButton:GetTall())
    teamButton:SetText("Update Team")
    teamButton.DoClick = function()
      local password = passwordEntry:GetValue()
      local passwordSet = password ~= "";
      local name = teamEntry:GetValue()

      if(utf8.len(name) == 0)then
        Minigolf.Messages.Print("The name of a team can't be empty!", nil, TEXT_EFFECT_DANGER)
        return
      end

      if(utf8.len(name) > TEAM_NAME_LENGTH_MAX)then
        Minigolf.Messages.Print(TEAM_NAME_LENGTH_MAX_MESSAGE, nil, TEXT_EFFECT_DANGER)
        return
      end
      
      if(utf8.len(name) < TEAM_NAME_LENGTH_MIN)then
        Minigolf.Messages.Print(TEAM_NAME_LENGTH_MIN_MESSAGE, nil, TEXT_EFFECT_DANGER)
        return
      end

      net.Start("Minigolf.TryUpdateTeam")
      net.WriteString(name)
      net.WriteColor(self.teamColor)
      net.WriteString(passwordSet and password or "")
      net.SendToServer()
      
      print("You have updated your team with name " .. name .. (passwordSet and (" and changed the password to " .. password) or "") )

      self:Remove()
    end

    self.teamButton = teamButton
    
    posX, posY = teamButton:GetPos()
    lastHeight = teamButton:GetTall()
  else -- If creating new
    self.teamColor = ColorRand()
    colorPicker:SetColor(self.teamColor)
    colorPicker:ValueChanged(self.teamColor)

    timer.Create("WaitForLPToSetTeamName", 0.1, 0, function()
      if(IsValid(LocalPlayer()) and IsValid(teamEntry))then
        local name = LocalPlayer():Nick()

        if(name ~= "unconnected")then
          teamEntry:SetText(name .. "'s Team")

          timer.Remove("WaitForLPToSetTeamName")
        end
      end
    end)

    local teamButton = vgui.Create("DButton", self)
    teamButton:SetSize(width - (PADDING * 2), 50)
    teamButton:SetPos(PADDING, posY + PADDING + colorPicker:GetTall())
    teamButton:SetText("Create Team")
    teamButton.DoClick = function()
      local password = passwordEntry:GetValue()
      local passwordSet = password ~= "";
      local name = string.Trim(teamEntry:GetValue())
  
      if(utf8.len(name) == 0)then
        Minigolf.Messages.Print("The name of a team can't be empty!", nil, TEXT_EFFECT_DANGER)
        return
      end
  
      if(utf8.len(name) > TEAM_NAME_LENGTH_MAX)then
        Minigolf.Messages.Print(TEAM_NAME_LENGTH_MAX_MESSAGE, nil, TEXT_EFFECT_DANGER)
        return
      end
      
      if(utf8.len(name) < TEAM_NAME_LENGTH_MIN)then
        Minigolf.Messages.Print(TEAM_NAME_LENGTH_MIN_MESSAGE, nil, TEXT_EFFECT_DANGER)
        return
      end
  
      local tableColor = colorPicker:GetColor() -- Apparently this isn't a color so:
      local color = Color(tableColor.r, tableColor.g, tableColor.b, 255)
      net.Start("Minigolf.TryCreateTeam")
      net.WriteString(name)
      net.WriteColor(color)
      net.WriteString(passwordSet and password or "")
      net.SendToServer()
      print("You have created your team with name " .. name .. (passwordSet and (" and the password " .. password) or "") )
  
      self:Remove()
    end
  
    self.teamButton = teamButton
  
    posX, posY = teamButton:GetPos()
  
    local joinButton = vgui.Create("DButton", self)
    joinButton:SetSize(width - (PADDING * 2), 22)
    joinButton:SetPos(PADDING, posY + PADDING + teamButton:GetTall())
    joinButton:SetText("Join another team")
    joinButton.DoClick = function ()
      local joinMenu = DermaMenu()
  
      for teamID, team in pairs(Minigolf.Teams.All) do
        local details = team.Password and " (passworded)" or ""
  
        joinMenu:AddOption(team.Name .. details, function()
          if(team.Password)then
            Derma_StringRequest(
              team.Name .. " requires a password", 
              "What is the password for the team '" .. team.Name .. "'?", 
              "", -- No default password
              function(password) -- try
                RunConsoleCommand("team_join", teamID, password)
              end, 
              nil, -- cancel override
              "Try", 
              "Cancel")
          else
            RunConsoleCommand("team_join", teamID)
          end
        end)
      end
  
      joinMenu:Open()
    end
    
    self.joinButton = joinButton
    
    posX, posY = joinButton:GetPos()
    lastHeight = joinButton:GetTall()
  end

	self:SetTall(posY + lastHeight + PADDING)
  self:Center()
end

function PANEL:Paint(w, h)
	Derma_DrawBackgroundBlur(self, self.startTime)

	draw.RoundedBox(16, 0, 0, w, h, Color(255,255,255,255))

  draw.SimpleText("Your Team", "MinigolfMainBold", w * .5, PADDING * 2, COLOR_PRIMARY, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
  
  surface.SetDrawColor(self.teamColor)
  surface.DrawRect(self.colorLabel.x, self.colorLabel.y + self.colorLabel:GetTall() + PADDING, self.colorLabel:GetWide(), self.colorLabel:GetWide())
end

function PANEL:OnKeyCodeReleased(key)
  if(key == KEY_ESCAPE or (self:HasFocus() and key == Minigolf.Teams.MenuKey and CurTime() - self.startTime > 1))then
		self:Remove()
    gui.HideGameUI()
	end
end

vgui.Register("Minigolf.TeamMenu", PANEL, "EditablePanel")
