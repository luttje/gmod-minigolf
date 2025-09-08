local PADDING_FLOOR_TEXT = 256
local FORCE_MAX = 1280
local FORCE_FRACTION_MAX = 1
local FORCE_FRACTION_MIN = 0.0001
local SCROLL_MODIFIER = 2
local PITCH_MULTIPLIER = 100
local PITCH_MIN = 0

local arrow = Material("minigolf/direction-arrow.png")

Minigolf.Ball = Minigolf.Ball or {}

-- Per-ball state storage
Minigolf.Ball.States = Minigolf.Ball.States or {}

function Minigolf.Ball.GetOrCreateBallState(ball)
	if (not IsValid(ball)) then
		return nil
	end

	local ballIndex = ball:EntIndex()

	if (not Minigolf.Ball.States[ballIndex]) then
		Minigolf.Ball.States[ballIndex] = {
			currentAngle = Angle(),
			currentForce = (FORCE_FRACTION_MIN + FORCE_FRACTION_MAX) * 0.5,
			currentPitch = 0,
			currentVelocity = SCROLL_MODIFIER,
			lastPersonalForce = nil,
			isInputting = false,
			drawingName = nil,
			networkID = nil,
		}
	end

	return Minigolf.Ball.States[ballIndex]
end

--- Clean up state when ball is removed
function Minigolf.Ball.CleanupBallState(ball)
	if IsValid(ball) then
		Minigolf.Ball.States[ball:EntIndex()] = nil
	end
end

-- TODO: Wouldn't this always equal LocalPlayer():GetMinigolfBall()?
function Minigolf.Ball.GetLocalPlayerInputBall()
	if (not IsValid(LocalPlayer())) then
		return nil
	end

	for ballIndex, state in pairs(Minigolf.Ball.States) do
		if (state.isInputting) then
			local ball = Entity(ballIndex)

			if (IsValid(ball) and ball:GetPlayer() == LocalPlayer()) then
				return ball
			end
		end
	end

	return nil
end

--[[
	Hooks
--]]

-- Local player last used scroll wheel at
local lastWheelInput = 0

hook.Add("Think", "Minigolf.AdjustPowerAutomaticallyOnAutoMode", function(cmd, x, y, ang)
	local inputBall = Minigolf.Ball.GetLocalPlayerInputBall()

	if (not IsValid(inputBall)) then
		return
	end

	local ballState = Minigolf.Ball.GetOrCreateBallState(inputBall)

	if (not ballState) then
		return
	end

	local isAutoPowerMode = LocalPlayer():GetNWBool("Minigolf.AutoPowerMode", false)

	if (not isAutoPowerMode) then
		return
	end

	local velocityModifier = Minigolf.Convars.AutoPowerVelocity:GetInt() * 0.01 * RealFrameTime()

	if (ballState.currentForce >= FORCE_FRACTION_MAX) then
		ballState.currentVelocity = -SCROLL_MODIFIER
	elseif (ballState.currentForce <= FORCE_FRACTION_MIN) then
		ballState.currentVelocity = SCROLL_MODIFIER
	end

	ballState.currentForce = ballState.currentForce + (ballState.currentVelocity * velocityModifier)
end)

-- Translate scrolling to adjusting the force
local lastTimePitchErrorPlayed = 0
hook.Add("InputMouseApply", "Minigolf.AdjustPowerWithButtonsAndScrolla", function(cmd, x, y, ang)
	local activeWeapon = LocalPlayer():GetActiveWeapon()
	local inputBall = Minigolf.Ball.GetLocalPlayerInputBall()

	if (not IsValid(inputBall) or not IsValid(activeWeapon) or activeWeapon:GetClass() ~= "minigolf_club") then
		return
	end

	local ballState = Minigolf.Ball.GetOrCreateBallState(inputBall)
	if (not ballState) then
		return
	end

	local isAutoPowerMode = LocalPlayer():GetNWBool("Minigolf.AutoPowerMode", false)
	local reloadButton = input.GetKeyCode(input.LookupBinding("reload"))

	if (input.IsButtonDown(reloadButton)) then
		if (not isAutoPowerMode) then
			ballState.currentForce = FORCE_FRACTION_MIN
		end

		ballState.currentPitch = PITCH_MIN

		return
	end

	local scrollDelta = cmd:GetMouseWheel()

	if (input.IsButtonDown(KEY_PAGEUP)) then
		scrollDelta = scrollDelta + 1
	elseif (input.IsButtonDown(KEY_PAGEDOWN)) then
		scrollDelta = scrollDelta - 1
	end

	local adjust = 0

	if (scrollDelta == 0) then
		return
	end

	if (CurTime() > lastWheelInput) then
		lastWheelInput = CurTime() + 0.01
	else
		scrollDelta = 0
	end

	adjust = scrollDelta * SCROLL_MODIFIER * RealFrameTime()

	if (adjust == 0) then
		return
	end

	local start = inputBall:GetStart()

	if (not IsValid(start)) then
		-- Wait for the net message to tell us what the hole of this ball is
		return
	end

	local maxPitch = start:GetMaxPitch()
	local speedButton = input.GetKeyCode(input.LookupBinding("speed"))

	if (not input.IsButtonDown(speedButton) and not isAutoPowerMode) then
		ballState.currentForce = math.Round(
			math.max(
				FORCE_FRACTION_MIN,
				math.min(FORCE_FRACTION_MAX, ballState.currentForce + adjust)
			),
			2
		)

		return
	end

	if (maxPitch ~= PITCH_MIN) then
		ballState.currentPitch = math.min(
			maxPitch,
			math.max(PITCH_MIN, ballState.currentPitch + (adjust * -PITCH_MULTIPLIER))
		)
	elseif (UnPredictedCurTime() - lastTimePitchErrorPlayed > 1) then
		lastTimePitchErrorPlayed = UnPredictedCurTime()
		LocalPlayer():EmitSound("Resource/warning.wav", 75, 200, 0.1)
		Minigolf.Messages.Print("Making lob shots is prohibited on this hole", "÷", Minigolf.TEXT_EFFECT_ATTENTION)
	end
end)

hook.Add("PostDrawTranslucentRenderables", "Minigolf.DrawDirectionArea", function(isDrawingDepth, isDrawSkybox)
	if (isDrawSkybox) then
		return
	end

	if (not IsValid(LocalPlayer())) then
		return
	end

	local inputBall = Minigolf.Ball.GetLocalPlayerInputBall()

	if (not IsValid(inputBall)) then
		return
	end

	local ballState = Minigolf.Ball.GetOrCreateBallState(inputBall)
	if (not ballState) then
		return
	end

	local directionVector = LocalPlayer():EyeAngles():Forward()
	local angle = directionVector:Angle()
	local forceHeight = FORCE_MAX * ballState.currentForce
	local start = inputBall:GetStart()

	if (not IsValid(start)) then
		-- Wait for the netmessage to tell us what the hole of this ball is
		return
	end

	local maxPitch = start:GetMaxPitch()

	angle:RotateAroundAxis(Vector(0, 0, 1), -90)
	angle = Angle(0, angle.y, maxPitch ~= 0 and ballState.currentPitch or 0)

	ballState.currentAngle = angle

	local angleNoPitch = Angle(angle)

	angleNoPitch.r = 0

	cam.IgnoreZ(true)
	cam.Start3D2D(inputBall:GetPos(), angleNoPitch, .03)
	if (ballState.currentPitch > 0) then
		surface.SetDrawColor(0, 0, 0, 255)
		surface.SetMaterial(arrow)
		local texWidth = 256
		surface.DrawTexturedRect(-(texWidth * .5), -FORCE_MAX, 256, FORCE_MAX)
	end
	cam.End3D2D()
	cam.IgnoreZ(false)

	cam.IgnoreZ(true)
	cam.Start3D2D(inputBall:GetPos(), angle, .03)
	surface.SetDrawColor(255, 255, 255, 255)
	surface.SetMaterial(arrow)
	local texWidth = 256
	surface.DrawTexturedRect(-(texWidth * .5), -FORCE_MAX, 256, FORCE_MAX)

	surface.SetDrawColor(255, 0, 0, 255)
	surface.DrawTexturedRectUV(-(texWidth * .5), FORCE_MAX * -ballState.currentForce, 256, forceHeight, 0,
		1 - ballState.currentForce,
		1, 1)

	cam.End3D2D()
	cam.IgnoreZ(false)
end)

hook.Add("PostDrawTranslucentRenderables", "Minigolf.DrawBallOwner", function(isDrawingDepth, isDrawSkybox)
	if (isDrawSkybox) then
		return
	end

	if (not IsValid(LocalPlayer())) then
		return
	end

	-- Get local player's ball for distance calculations
	local localPlayerBall = LocalPlayer():GetMinigolfBall()

	for _, ball in pairs(ents.FindInSphere(LocalPlayer():GetPos(), 512)) do
		if (not IsValid(ball) or ball:GetClass() ~= "minigolf_ball") then
			continue
		end

		local ballName = ball:GetPlayerName() .. "'s ball"
		local player = ball:GetPlayer()
		local angle = LocalPlayer():EyeAngles()
		local start = ball:GetStart()

		if (not IsValid(start)) then
			-- Wait for the netmessage to tell us what the hole of this ball is
			return
		end

		local maxPitch = start:GetMaxPitch()
		local ballState = Minigolf.Ball.GetOrCreateBallState(ball)

		angle = Angle(angle.x, angle.y, 0)
		angle:RotateAroundAxis(angle:Up(), -90)
		angle:RotateAroundAxis(angle:Forward(), 90)

		local texts = {}
		local textsRight = {}
		local showHints = Minigolf.Convars.ShowHints:GetBool()
		local isAutoPowerMode = LocalPlayer():GetNWBool("Minigolf.AutoPowerMode", false)

		-- Calculate alpha based on distance to local player's ball
		local alpha = 255
		local isLocalPlayerBall = (player == LocalPlayer())

		if (not isLocalPlayerBall and IsValid(localPlayerBall) and localPlayerBall ~= ball) then
			local distance = ball:GetPos():Distance(localPlayerBall:GetPos())
			local fadeStartDistance = 256 -- Distance at which alpha starts reducing
			local fadeEndDistance = 64 -- Distance at which alpha reaches minimum
			local minAlpha = 50     -- Minimum alpha value

			if (distance <= fadeEndDistance) then
				alpha = minAlpha
			elseif (distance >= fadeStartDistance) then
				alpha = 255
			else
				-- Interpolate from minAlpha to full alpha as distance increases
				local factor = (distance - fadeEndDistance) / (fadeStartDistance - fadeEndDistance)
				alpha = minAlpha + (255 - minAlpha) * factor
			end
		end

		if (IsValid(player)) then
			if (player == LocalPlayer()) then
				if (showHints) then
					texts[#texts + 1] = string.format(
						"Stuck? Press '%s' + '%s' on the ball to move back to the start",
						input.LookupBinding("reload"):upper(), input.LookupBinding("use"):upper())
				end

				if (ballState and ballState.isInputting) then
					if (showHints) then
						textsRight[#textsRight + 1] = string.format("Press '%s' to shoot",
							input.LookupBinding("attack"):upper())

						if (maxPitch ~= 0) then
							if (isAutoPowerMode) then
								textsRight[#textsRight + 1] = string.format(
									"Scroll (or use PAGE UP and PAGE DOWN) to set the pitch for a 'lob shot'.",
									input.LookupBinding("speed"):upper())
							else
								textsRight[#textsRight + 1] = string.format(
									"Hold '%s' and scroll (or use PAGE UP and PAGE DOWN) to set the pitch for a 'lob shot'.",
									input.LookupBinding("speed"):upper())
							end
						end

						if (not isAutoPowerMode) then
							textsRight[#textsRight + 1] =
							"SCROLL your mouse wheel or use 'PAGE UP' and 'PAGE DOWN' to set the force"
						end
					end

					if (not isAutoPowerMode and ballState) then
						textsRight[#textsRight + 1] = "Force: " .. (ballState.currentForce * 100)
					end
				else
					if (ball:GetVelocity():Length() > 0 and showHints) then
						texts[#texts + 1] = string.format("Wait for the ball to stop rolling...")
					end
				end
			elseif (ballState and ballState.drawingName == player) then
				-- Show that another player is currently inputting force for this ball
				texts[#texts + 1] = player:Name() .. " is aiming..."
			end

			local strokes = ball:GetStrokes()

			texts[#texts + 1] = ""
			texts[#texts + 1] = strokes .. Minigolf.Text.Pluralize(" stroke", strokes) .. " so far"
			texts[#texts + 1] = ballName
		elseif (showHints) then
			texts[#texts + 1] = string.format("This player left, press '%s' + '%s' to remove their ball",
				input.LookupBinding("reload"):upper(), input.LookupBinding("use"):upper())
		end

		cam.IgnoreZ(true)
		cam.Start3D2D(ball:GetPos(), angle, .03)
		hook.Call("Minigolf.BallPreDrawText", Minigolf.GM(), player, ball, texts)

		surface.SetFont("MinigolfHuge")

		local startY = PADDING_FLOOR_TEXT * .5

		-- Apply alpha to the colors
		local lightColor = Color(Minigolf.COLOR_LIGHT.r, Minigolf.COLOR_LIGHT.g, Minigolf.COLOR_LIGHT.b, alpha)
		local darkColor = Color(Minigolf.COLOR_DARK.r, Minigolf.COLOR_DARK.g, Minigolf.COLOR_DARK.b, alpha)
		local secondaryColor = Color(Minigolf.COLOR_SECONDARY.r, Minigolf.COLOR_SECONDARY.g, Minigolf.COLOR_SECONDARY.b,
			alpha)

		for _, text in ipairs(texts) do
			local textWidth, textHeight = surface.GetTextSize(text)

			draw.SimpleTextOutlined(text, "MinigolfHuge", -PADDING_FLOOR_TEXT, startY, lightColor,
				TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP, 5, darkColor)

			startY = startY - textHeight - 15
		end

		startY = PADDING_FLOOR_TEXT * .5

		for _, text in ipairs(textsRight) do
			local textWidth, textHeight = surface.GetTextSize(text)

			draw.SimpleTextOutlined(text, "MinigolfHuge", PADDING_FLOOR_TEXT, startY, secondaryColor,
				TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 5, darkColor)

			startY = startY - textHeight - 15
		end
		cam.End3D2D()
		cam.IgnoreZ(false)
	end
end)

hook.Add("KeyRelease", "Minigolf.CheckForHit", function(player, key)
	if (key ~= IN_ATTACK) then
		return
	end

	local inputBall = Minigolf.Ball.GetLocalPlayerInputBall()

	if (not IsValid(inputBall)) then
		return
	end

	-- Ensure the player has the golf club out
	local activeWeapon = player:GetActiveWeapon()

	if (not IsValid(activeWeapon) or activeWeapon:GetClass() ~= "minigolf_club") then
		return
	end

	local ballState = Minigolf.Ball.GetOrCreateBallState(inputBall)

	if (ballState and ballState.isInputting and not ballState.networkID) then
		ballState.isInputting = false
		LocalPlayer():SetBallGivingForce(nil)
		ballState.lastPersonalForce = ballState.currentForce

		net.Start("Minigolf.SetBallForce")
		net.WriteFloat(ballState.currentForce)
		net.WriteAngle(ballState.currentAngle)
		net.SendToServer()
	end
end)

local lastBallInteraction = 0
hook.Add("Think", "Minigolf.CancelIfNotNearBall", function()
	local ball = LocalPlayer():GetMinigolfBall()

	if (not IsValid(ball)) then
		return
	end

	local ballState = Minigolf.Ball.GetOrCreateBallState(ball)

	if (not ballState) then
		return
	end

	local inRange = LocalPlayer():IsInDistanceOf(ball, MINIGOLF_DISTANCE_TO_BALL_MAX)

	if (ballState.isInputting and not inRange) then
		ballState.isInputting = false
		ballState.lastPersonalForce = ballState.currentForce
		LocalPlayer():SetBallGivingForce(nil)

		LocalPlayer():EmitSound("Resource/warning.wav", 75, 200, 0.1)
		net.Start("Minigolf.SetBallForce")
		net.WriteFloat(Minigolf.CANCEL_BALL_FORCE)
		net.WriteAngle(Angle(0, 0, 0))
		net.SendToServer()
	elseif (not ballState.isInputting and inRange and UnPredictedCurTime() - lastBallInteraction > 1) then
		lastBallInteraction = UnPredictedCurTime()
		net.Start("Minigolf.StartBallForce")
		net.SendToServer()
	end
end)

gameevent.Listen("player_disconnect")
hook.Add("player_disconnect", "Minigolf.StopMeteringWhenPlayerLeaves", function(data)
	local networkID = data.networkid

	-- Clean up any ball states for the disconnected player
	for ballIndex, state in pairs(Minigolf.Ball.States) do
		if (state.networkID and state.networkID == networkID) then
			state.isInputting = false
			state.drawingName = nil
			state.networkID = nil
		end
	end
end)

-- Clean up ball states when entities are removed
hook.Add("EntityRemoved", "Minigolf.CleanupBallStates", function(ent)
	if (ent:GetClass() == "minigolf_ball") then
		Minigolf.Ball.CleanupBallState(ent)
	end
end)

--[[
	Net Messages
--]]

net.Receive("Minigolf.GetBallForce", function()
	if (not IsValid(LocalPlayer())) then
		return
	end

	local activePlayer = net.ReadEntity()
	local ball = net.ReadEntity()

	if (not IsValid(activePlayer) or not IsValid(ball)) then
		-- TODO: Check if this is problematic and we just need to network EntIndex so we can look it up again
		-- TODO: once the ball/player come into PVS
		print("Received invalid data for Minigolf.GetBallForce", activePlayer, ball)
		return
	end

	activePlayer:SetBallGivingForce(ball)

	local ballState = Minigolf.Ball.GetOrCreateBallState(ball)
	if (not ballState) then
		return
	end

	if (activePlayer ~= LocalPlayer()) then
		-- Watching another player input force
		ballState.isInputting = false
		ballState.currentForce = 0
		ballState.drawingName = activePlayer
		ballState.networkID = activePlayer:SteamID()
	else
		-- Local player is inputting force for their own ball
		ballState.isInputting = true
		ballState.currentForce = ballState.lastPersonalForce or ((FORCE_FRACTION_MIN + FORCE_FRACTION_MAX) * .5)
		ballState.drawingName = nil
		ballState.networkID = nil
	end
end)

net.Receive("Minigolf.GetBallForceCancel", function()
	if (not IsValid(LocalPlayer())) then
		return
	end

	local activePlayer = net.ReadEntity()
	activePlayer:SetBallGivingForce(nil)

	-- Find and cancel the appropriate ball state
	for ballIndex, state in pairs(Minigolf.Ball.States) do
		local ball = Entity(ballIndex)

		if (IsValid(ball) and ball:GetPlayer() == activePlayer) then
			state.isInputting = false
			state.currentForce = 0
			state.drawingName = nil
			state.networkID = nil
			break
		end
	end
end)
