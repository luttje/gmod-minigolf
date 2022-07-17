include("shared.lua")

function ENT:Initialize()
	if(self.ModelScale)then
		self:SetModelScale(self.ModelScale)
	end
end

function ENT:GetPlayer()
	return self:GetNWEntity("Player")
end

function ENT:GetPlayerName()
	return self:GetNWString("PlayerName", "Unknown Player")
end

function ENT:GetStart()
	return self:GetNWEntity("HoleStart")
end

function ENT:GetStrokes()
	return self:GetNWInt("Strokes", 0)
end

function ENT:Draw()
	local player = self:GetPlayer()

	if(not IsValid(player))then
		return
	end

	local overrideTable = {
		hasHandled = false
	}
	hook.Call("Minigolf.PreDrawPlayerBall", Minigolf.GM(), player, self)
	hook.Call("Minigolf.DrawPlayerBall", Minigolf.GM(), player, self, overrideTable)

	if(not overrideTable.hasHandled)then
		self:DrawModel()
	end
end

local PADDING_FLOOR_TEXT = 256
local FORCE_MAX = 1280
local FORCE_FRACTION_MAX = 1
local FORCE_FRACTION_MIN = 0.0001
local SCROLL_MODIFIER = 2
local PITCH_MULTIPLIER = 100
local PITCH_MIN = 0
local PITCH_MAX = 90

local inputtingForceBall = false
local arrow = Material("minigolf/direction-arrow.png")
local padding = 15
local currentAngle = Angle()
local lastPersonalForce
local currentForce = 0
local currentPitch = 0
local drawingName

local lastWheelInput = 0

net.Receive("Minigolf.GetBallForce", function()
	if(not IsValid(LocalPlayer()))then
		return
	end
	
	local activePlayer = net.ReadEntity()
	local ball = net.ReadEntity()

	activePlayer:SetBallGivingForce(ball)
	inputtingForceBall = ball

	if(activePlayer ~= LocalPlayer())then
		inputtingForceBall = ball
		currentForce = 0
		drawingName = activePlayer
	else
		currentForce = lastPersonalForce or ((FORCE_FRACTION_MIN + FORCE_FRACTION_MAX) * .5)
	end
end)

net.Receive("Minigolf.GetBallForceCancel", function()
	if(not IsValid(LocalPlayer()))then
		return
	end

	local activePlayer = net.ReadEntity()
	activePlayer:SetBallGivingForce(nil)

	inputtingForceBall = false
	currentForce = 0
	drawingName = nil
end)

local currentVelocity = SCROLL_MODIFIER
hook.Add("Think", "Minigolf.AdjustPowerAutomaticallyOnAutoMode", function(cmd, x, y, ang)
	if(not IsValid(inputtingForceBall))then
		return
	end

	local isAutoPowerMode = LocalPlayer():GetNWBool("Minigolf.AutoPowerMode", false)

	if(not isAutoPowerMode)then
		return
	end

	local velocityModifier = Minigolf.Convars.AutoPowerVelocity:GetInt() * 0.01 * RealFrameTime()

	if(currentForce >= FORCE_FRACTION_MAX)then
		currentVelocity = -SCROLL_MODIFIER
	elseif(currentForce <= FORCE_FRACTION_MIN)then
		currentVelocity = SCROLL_MODIFIER
	end

	currentForce = currentForce + (currentVelocity*velocityModifier)
end)

-- Translate scrolling to adjusting the force
local lastTimePitchErrorPlayed = 0
hook.Add("InputMouseApply", "Minigolf.AdjustPowerWithButtonsAndScrolla", function(cmd, x, y, ang)
	if(not IsValid(inputtingForceBall))then
		return
	end

	local isAutoPowerMode = LocalPlayer():GetNWBool("Minigolf.AutoPowerMode", false)
	local reloadButton = input.GetKeyCode(input.LookupBinding("reload"))

	if(input.IsButtonDown(reloadButton))then
		if(not isAutoPowerMode)then
			currentForce = FORCE_FRACTION_MIN
		end

		currentPitch = PITCH_MIN
		return
	end

	local scrollDelta = cmd:GetMouseWheel()

	if(input.IsButtonDown(KEY_PAGEUP))then
		scrollDelta = scrollDelta + 1
	elseif(input.IsButtonDown(KEY_PAGEDOWN))then
		scrollDelta = scrollDelta - 1
	end
	local adjust = 0

	if(scrollDelta == 0)then
		return
	end

	if CurTime() > lastWheelInput then
		lastWheelInput = CurTime() + 0.01
	else 
		scrollDelta = 0
	end

	adjust = scrollDelta * SCROLL_MODIFIER * RealFrameTime()

	if(adjust == 0)then
		return
	end

	local start = inputtingForceBall:GetStart()

	if(not IsValid(start))then
		-- Wait for the netmessage to tell us what the hole of this ball is
		return
	end

	local maxPitch = start:GetMaxPitch()
	local speedButton = input.GetKeyCode(input.LookupBinding("speed"))

	if(not input.IsButtonDown(speedButton) and not isAutoPowerMode)then
		currentForce = math.Round(math.max(FORCE_FRACTION_MIN, math.min(FORCE_FRACTION_MAX, currentForce + adjust)),2)
		return
	end

	if(maxPitch ~= 0)then
		currentPitch = math.min(PITCH_MAX, math.max(PITCH_MIN, currentPitch + (adjust * -PITCH_MULTIPLIER)))
	elseif(UnPredictedCurTime() - lastTimePitchErrorPlayed > 1)then
		lastTimePitchErrorPlayed = UnPredictedCurTime()
		LocalPlayer():EmitSound("Resource/warning.wav", 75, 200, 0.1)
		Minigolf.Messages.Print("Making lob shots is prohibited on this hole", "÷", Minigolf.TEXT_EFFECT_ATTENTION)
	end
end)

hook.Add("PostDrawTranslucentRenderables", "Minigolf.DrawDirectionArea", function(isDrawingDepth, isDrawSkybox)
	if(isDrawSkybox)then return; end

	if(IsValid(LocalPlayer()) and inputtingForceBall)then
		local ball = LocalPlayer():GetNWEntity("Ball")

		if(IsValid(ball))then
			local directionVector = LocalPlayer():EyeAngles():Forward()
			local angle = directionVector:Angle()
			local forceHeight = FORCE_MAX * currentForce
			local start = ball:GetStart()
			
			if(not IsValid(start))then
				-- Wait for the netmessage to tell us what the hole of this ball is
				return
			end

			local maxPitch = start:GetMaxPitch()

			angle:RotateAroundAxis(Vector(0,0,1), -90)
			angle = Angle(0, angle.y, maxPitch ~= 0 and currentPitch or 0)

			currentAngle = angle

			local angleNoPitch = Angle(angle)

			angleNoPitch.r = 0

			cam.IgnoreZ(true)
			cam.Start3D2D(ball:GetPos(), angleNoPitch, .03)
				if(currentPitch > 0)then
					surface.SetDrawColor(0, 0, 0, 255)
					surface.SetMaterial(arrow)
					local texWidth = 256
					surface.DrawTexturedRect(-(texWidth * .5), -FORCE_MAX, 256, FORCE_MAX)
				end
			cam.End3D2D()
			cam.IgnoreZ(false)

			cam.IgnoreZ(true)
			cam.Start3D2D(ball:GetPos(), angle, .03)
				surface.SetDrawColor(255, 255, 255, 255)
				surface.SetMaterial(arrow)
				local texWidth = 256
				surface.DrawTexturedRect(-(texWidth * .5), -FORCE_MAX, 256, FORCE_MAX)

				surface.SetDrawColor(255, 0, 0, 255)
				surface.DrawTexturedRectUV(-(texWidth * .5), FORCE_MAX * -currentForce, 256, forceHeight, 0, 1-currentForce, 1, 1)

			cam.End3D2D()
			cam.IgnoreZ(false)
		end
	end
end)

-- Draw the owner of a ball
local ballOwnerOffset = {
	x = 50,
	y = -25
}
hook.Add("PostDrawTranslucentRenderables", "Minigolf.DrawBallOwner", function(isDrawingDepth, isDrawSkybox)
	if(isDrawSkybox)then return; end

	if(IsValid(LocalPlayer()))then
		for _, ball in pairs(ents.FindInSphere(LocalPlayer():GetPos(), 512)) do
			if(ball:GetClass() == "minigolf_ball")then
				if(IsValid(ball))then
					local ballName = ball:GetPlayerName() .. "'s ball"
					local player = ball:GetPlayer()
					local angle = LocalPlayer():EyeAngles()
					local start = ball:GetStart()

					if(not IsValid(start))then
						-- Wait for the netmessage to tell us what the hole of this ball is
						return
					end

					local maxPitch = start:GetMaxPitch()

					angle = Angle(angle.x, angle.y, 0)
					angle:RotateAroundAxis(angle:Up(), -90)
					angle:RotateAroundAxis(angle:Forward(), 90)

					local texts = {}
					local textsRight = {}
					local showHints = Minigolf.Convars.ShowHints:GetBool()
					local isAutoPowerMode = LocalPlayer():GetNWBool("Minigolf.AutoPowerMode", false)

					if(IsValid(player))then
						if(player == LocalPlayer())then
							if(showHints)then
								texts[#texts + 1] = string.format("Stuck? Press '%s' + '%s' on the ball to move back to the start", input.LookupBinding("reload"):upper(), input.LookupBinding("use"):upper())
							end

							if(inputtingForceBall)then
								if(showHints)then
									textsRight[#textsRight + 1] = string.format("Press '%s' to shoot", input.LookupBinding("attack"):upper())

									if(maxPitch ~= 0)then
										if(isAutoPowerMode)then
											textsRight[#textsRight + 1] = string.format("Scroll (or use PAGE UP and PAGE DOWN) to set the pitch for a 'lob shot'.", input.LookupBinding("speed"):upper())
										else
											textsRight[#textsRight + 1] = string.format("Hold '%s' and scroll (or use PAGE UP and PAGE DOWN) to set the pitch for a 'lob shot'.", input.LookupBinding("speed"):upper())
										end
									end

									if(not isAutoPowerMode)then
										textsRight[#textsRight + 1] = "SCROLL your mouse wheel or use 'PAGE UP' and 'PAGE DOWN' to set the force"
									end
								end

								if(not isAutoPowerMode)then
									textsRight[#textsRight + 1] = "Force: " .. (currentForce * 100)
								end
							else
								if(ball:GetVelocity():Length() > 0 and showHints)then
									texts[#texts + 1] = string.format("Wait for the ball to stop rolling...")
								end
							end
						end

						local strokes = ball:GetStrokes()

						texts[#texts + 1] = ""
						texts[#texts + 1] = strokes .. Minigolf.Text.Pluralize(" stroke", strokes) .. " so far"
						texts[#texts + 1] = ballName
					elseif(showHints)then
						texts[#texts + 1] = string.format("This player left, press '%s' + '%s' to remove their ball", input.LookupBinding("reload"):upper(), input.LookupBinding("use"):upper())
					end

					cam.IgnoreZ(true)
					cam.Start3D2D(ball:GetPos(), angle, .03)
						hook.Call("Minigolf.BallPreDrawText", Minigolf.GM(), player, ball, texts)

						surface.SetFont("MinigolfHuge")

						local startY = PADDING_FLOOR_TEXT * .5

						for _, text in ipairs(texts)do
							local textWidth, textHeight = surface.GetTextSize(text)

							draw.SimpleTextOutlined(text, "MinigolfHuge", -PADDING_FLOOR_TEXT, startY, Minigolf.COLOR_LIGHT, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP, 5, Minigolf.COLOR_DARK)

							startY = startY - textHeight - 15
						end

						startY = PADDING_FLOOR_TEXT * .5

						for _, text in ipairs(textsRight)do
							local textWidth, textHeight = surface.GetTextSize(text)

							draw.SimpleTextOutlined(text, "MinigolfHuge", PADDING_FLOOR_TEXT, startY, Minigolf.COLOR_SECONDARY, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 5, Minigolf.COLOR_DARK)

							startY = startY - textHeight - 15
						end
					cam.End3D2D()
					cam.IgnoreZ(false)
				end
			end
		end
	end
end)

hook.Add("KeyRelease", "Minigolf.CheckForHit", function(player, key)
	if(key == IN_ATTACK and not drawingName and inputtingForceBall)then
		inputtingForceBall = false

		LocalPlayer():SetBallGivingForce(nil)
		lastPersonalForce = currentForce

		net.Start("Minigolf.SetBallForce")
			net.WriteFloat(currentForce)
			net.WriteAngle(currentAngle)
		net.SendToServer()
	end
end)

local lastBallInteraction = 0
hook.Add("Think", "Minigolf.CancelIfNotNearBall", function()
	local ball = LocalPlayer():GetPlayerBall()

	if(IsValid(ball))then
		if(inputtingForceBall == ball and not LocalPlayer():IsInDistanceOf(ball, DISTANCE_TO_BALL_MAX))then
			inputtingForceBall = false
			lastPersonalForce = currentForce
			LocalPlayer():SetBallGivingForce(nil)
			
			LocalPlayer():EmitSound("Resource/warning.wav", 75, 200, 0.1)
			net.Start("Minigolf.SetBallForce")
				net.WriteFloat(Minigolf.CANCEL_BALL_FORCE)
				net.WriteAngle(Angle(0,0,0))
			net.SendToServer()
		elseif(not inputtingForceBall and UnPredictedCurTime() - lastBallInteraction > 1)then
			lastBallInteraction = UnPredictedCurTime()
			net.Start("Minigolf.StartBallForce")
			net.SendToServer()
		end
	end
end)

hook.Add("PlayerDisconnected", "Minigolf.StopMeteringWhenPlayerLeaves", function(player)
	if(drawingName and drawingName == player)then
		inputtingForceBall = false
		drawingName = nil
	end
end)