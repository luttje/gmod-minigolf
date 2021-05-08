-- Called when a team should be created
net.Receive("Minigolf.SetupTeamForMinigolf", function()
   local teamIndex = net.ReadUInt(8)
   local name = net.ReadString()
   local color = net.ReadColor()

   team.SetUp(teamIndex, name, color)
end)

net.Receive("Minigolf.PlayerJoinedTeam", function()
   local player = net.ReadEntity()

   hook.Call("MinigolfPlayerJoinTeam", gm(), player)
end)

local hasOpenedFirstTime = false
local TEAM_OPEN_INTERVAL = 1.5
local lastOpen = 0

local function hideMenu()
	TEAM_MENU:Remove()
	TEAM_MENU = nil
end

local function showMenu(justLeftOtherTeam)
	if(IsValid(TEAM_MENU))then
		hideMenu()
	end

	local team = IsValid(LocalPlayer()) and LocalPlayer():Team() or nil

	-- Open the creation menu when we: just left a different team
	if(justLeftOtherTeam 
	-- Have just joined the server
	or not IsValid(LocalPlayer()) 
	-- Are in the spectator team
	or team == TEAM_MINIGOLF_SPECTATORS 
	-- Are in a gmod default team like the Joining/Connecting or (wrong) Spectators team
	or not Minigolf.Teams.All[team])then
		TEAM_MENU = vgui.Create("Minigolf.TeamMenu")
		TEAM_MENU:BuildTeamMenu()
		TEAM_MENU:MakePopup()
	else
		TEAM_MENU = vgui.Create("Minigolf.TeamMenu")
		TEAM_MENU:BuildTeamMenu(true)
		TEAM_MENU:MakePopup()
	end
end

-- Add a command to open the menu
concommand.Add("menu_team", showMenu)

-- Called to update the information in the team menu
net.Receive("Minigolf.UpdateGolfTeamMenu", function()
	-- Update our local team information
	local golfTeams = net.ReadTable()

	Minigolf.Teams.All = {}

	for teamID, teamInfo in pairs(golfTeams) do
		Minigolf.Teams.All[teamID] = {
			Name = teamInfo.n,
			Password = teamInfo.p,
		}
	end
end)

-- Called to show the team menu
net.Receive("Minigolf.ShowGolfTeamMenu", function()
	local justLeftOtherTeam = net.ReadBool()

	showMenu(justLeftOtherTeam)
end)

-- Detect keypresses to open this menu
hook.Add("PlayerButtonDown", "Minigolf.ShowTeamMenuOnKeyPress", function(player, button)
	if((not PS or not PS.ShopMenu or not PS.ShopMenu:IsVisible())
	and button == Minigolf.Teams.MenuKey
	and not Minigolf.Chatbox.WasJustClosed()
	and player == LocalPlayer()
	and (UnPredictedCurTime() - lastOpen) > TEAM_OPEN_INTERVAL)then
		lastOpen = UnPredictedCurTime()
		showMenu()
	end
end)

-- When a player joins a team
hook.Add("MinigolfPlayerJoinTeam", "Minigolf.MinigolfPlayerJoinTeamHideMenu", function(player)
	if(IsValid(player) and IsValid(LocalPlayer()) and player == LocalPlayer() and IsValid(TEAM_MENU))then
		hideMenu()
	end
end)
