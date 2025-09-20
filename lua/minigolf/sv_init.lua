util.AddNetworkString("Minigolf.ShowScoreCard")

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
	 Commands
--]]

Minigolf.Commands.Register("giveup", function(player)
	local activeHole = player:GetActiveHole()
	local ball = player:GetMinigolfBall()

	if (IsValid(ball) and IsValid(activeHole)) then
		hook.Call("Minigolf.PlayerGivesUp", Minigolf.GM(), player, activeHole)
		Minigolf.Messages.Send(player, "You gave up!", nil, Minigolf.TEXT_EFFECT_DANGER)

		Minigolf.Holes.End(player, ball, activeHole)
	else
		Minigolf.Messages.Send(player, "You're not playing a hole, so can't give up!", nil, Minigolf.TEXT_EFFECT_DANGER)
	end
end, "Finish the hole you are currently playing at with a DSQ (disqualified) score")

Minigolf.Commands.Register("enablehints", function(player)
	player:ConCommand("minigolf_show_hints 1")
end, "Enables on screen help")

Minigolf.Commands.Register("disablehints", function(player)
	player:ConCommand("minigolf_show_hints 1")
end, "Disables on screen help")

Minigolf.Commands.Register("enableautopower", function(player)
	if (not Minigolf.Convars.PlayerConfigPowerMode:GetBool()) then
		Minigolf.Messages.Send(player, "The admin does not allow you to change your power mode.", nil,
			Minigolf.TEXT_EFFECT_DANGER)
		return
	end

	player:SetNWBool("Minigolf.AutoPowerMode", true)
	Minigolf.Messages.Send(player, "Automatic power mode enabled!", nil, Minigolf.TEXT_EFFECT_NORMAL)
end, "Enables automatic power mode")

Minigolf.Commands.Register("disableautopower", function(player)
	if (not Minigolf.Convars.PlayerConfigPowerMode:GetBool()) then
		Minigolf.Messages.Send(player, "The admin does not allow you to change your power mode.", nil,
			Minigolf.TEXT_EFFECT_DANGER)
		return
	end

	player:SetNWBool("Minigolf.AutoPowerMode", false)
	Minigolf.Messages.Send(player, "Automatic power mode disabled!", nil, Minigolf.TEXT_EFFECT_NORMAL)
end, "Disables automatic power mode")

Minigolf.Commands.Register("showscores", function(player)
	net.Start("Minigolf.ShowScoreCard")
	net.Send(player)
end, "Shows the score card")
