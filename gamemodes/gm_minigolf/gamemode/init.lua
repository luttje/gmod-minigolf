include("shared.lua")

--[[
	Common Resources
--]]
resource.AddWorkshop("2313854259")

resource.AddFile("resource/fonts/sansation_regular.ttf")
resource.AddFile("resource/fonts/sansation_bold.ttf")
resource.AddFile("resource/fonts/sansation_bold_italic.ttf")
resource.AddFile("resource/fonts/sansation_italic.ttf")
resource.AddFile("resource/fonts/golf_icons.ttf")

resource.AddFile("materials/minigolf/direction-arrow.png")
resource.AddFile("materials/minigolf/token.png")
resource.AddFile("materials/minigolf/logo_compact.png")
resource.AddFile("materials/minigolf/logo.png")
resource.AddFile("models/billiards/ball.mdl")

resource.AddFile("materials/minigolf/balls/regular_ball.vmt")
resource.AddFile("materials/minigolf/balls/regular_ball_normal.vtf")

--[[
	 Some default commands
--]]
Minigolf.Commands.Register("team", function(player, arguments)
	net.Start("Minigolf.ShowGolfTeamMenu")
	net.WriteBool(false)
	net.Send(player)
end, "Show information about your team, to change it, leave it and/or join another team")

Minigolf.Commands.Register("bet", function(player)
	player:ConCommand("menu_betting")
end, "Bet on upcoming players' performance")

Minigolf.Commands.Register("giveup", function(player)
	local activeHole = player:GetActiveHole()
	local ball = player:GetPlayerBall()

	if(IsValid(ball) and IsValid(activeHole))then
		Minigolf.Messages.Send(team.GetPlayers(player:Team()), player:Nick() .. " gave up!", nil, TEXT_EFFECT_DANGER)

		Minigolf.Holes.End(player, ball, activeHole)
	else
		Minigolf.Messages.Send(player, "You're not playing a hole, so can't give up!", nil, TEXT_EFFECT_DANGER)
	end
end, "Finish the hole you are currently playing at with a DSQ (disqualified) score")

Minigolf.Commands.Register("enablehints", function(player)
  player:ConCommand("minigolf_show_hints 1")
end, "Enables on screen help")

Minigolf.Commands.Register("disablehints", function(player)
  player:ConCommand("minigolf_show_hints 1")
end, "Disables on screen help")