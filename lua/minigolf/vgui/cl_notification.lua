local MAX_DISPLAYED = 5 -- TODO: Make this configurable with a server convar
local nextCreateSparkle

-- TODO: Actually make this fancy and move this to a functions
local sparkles = {}

local function drawSparkle(x, y, w, h, color, duration)
	w = w * .5
	h = h * .5

	table.insert(sparkles, {
		x = x,
		y = y,
		w = w,
		h = h,
		color = color,
		dieTime = UnPredictedCurTime() + (duration or 1)
	})
end

local function drawSparkles()
	for i=#sparkles, 1, -1 do
		local sparkleData = sparkles[i]

		if(sparkleData.dieTime > UnPredictedCurTime())then
			local x, y = sparkleData.x, sparkleData.y
			local w, h = sparkleData.w, sparkleData.h
			local color = sparkleData.color

			surface.SetDrawColor(color)
			surface.DrawLine(x, y, x - w, y)
			surface.DrawLine(x, y, x + w, y)
			surface.DrawLine(x, y, x, y - h)
			surface.DrawLine(x, y, x, y + h)
		else
			table.remove(sparkles, i)
		end
	end
end

-- Draw messages in the center
hook.Add("DrawOverlay", "Minigolf.DrawMessages", function()
	if(IsValid(LocalPlayer()))then
    local fontIcon = "MinigolfIcons"
    local fontNotification = "MinigolfMainBold"
    local colorBackground = Minigolf.Colors.Get("Background")
    local colorText = Minigolf.Colors.Get("Text")

		local allMessages = Minigolf.Messages.GetAll()
		local scrW, scrH = ScrW(), ScrH()
		local oldMessages = {}
		local numDisplayed = 0
    local totalHeight = 0

		for i, msgData in ipairs(allMessages)do
			if(msgData.VanishTime and msgData.VanishTime < UnPredictedCurTime())then
				table.insert(oldMessages, i)
			else
				if(not msgData.VanishTime)then
					-- Set this message to vanish
					msgData.VanishTime = UnPredictedCurTime() + msgData.Duration
				end

				-- Increment how many messages are showing
				numDisplayed = numDisplayed + 1

				surface.SetFont(fontNotification)
				local width, height = surface.GetTextSize(msgData.Message)

				local textX, textY = (scrW * .5) - (width * .5), Minigolf.PADDING + totalHeight
				local widthIcon, heightIcon

				if(fontIcon == nil or msgData.Icon == "NONE" or not msgData.Icon)then          
          local x = textX - Minigolf.HALF_PADDING
          local y = textY - Minigolf.HALF_PADDING
          local fullWidth = width + Minigolf.PADDING
          local fullHeight = height + Minigolf.PADDING
          
          Minigolf.Draw.Shadow(x - 5, y - 5, fullWidth + 10, fullHeight + 10)
          
          surface.SetDrawColor(colorBackground)
          surface.DrawRect(x, y, fullWidth, fullHeight)
        else
					surface.SetFont(fontIcon)
					widthIcon, heightIcon = surface.GetTextSize(msgData.Icon)

          local x = textX - Minigolf.HALF_PADDING
          local y = textY - Minigolf.HALF_PADDING
          local fullWidth = width + Minigolf.PADDING
          local fullHeight = height + Minigolf.PADDING + heightIcon + Minigolf.PADDING
          
          Minigolf.Draw.Shadow(x - 5, y - 5, fullWidth + 10, fullHeight + 10)
          
          surface.SetDrawColor(colorBackground)
          surface.DrawRect(x, y, fullWidth, fullHeight)

					draw.SimpleTextOutlined(msgData.Icon, fontIcon, scrW * .5, textY, msgData.Color, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 2, Minigolf.Colors.Get("Text"))

					textY = textY + Minigolf.PADDING + heightIcon
				end

				-- Increment the total height with the current message height
				totalHeight = textY + height + Minigolf.HALF_PADDING

				local drawFunc = draw.SimpleText

				if(msgData.Color.r > 200 and msgData.Color.g > 200 and msgData.Color.b > 200)then
					drawFunc = draw.SimpleTextOutlined
				end

				drawFunc(msgData.Message, fontNotification, textX, textY, msgData.Color, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 1, colorText)

				if(msgData.TextEffect == Minigolf.TEXT_EFFECT_SPARKLE)then
					if(not nextCreateSparkle or nextCreateSparkle < UnPredictedCurTime())then
						local size = math.random(5, 20)
						local deviateX = math.random(0, width)
						local deviateY = math.random(msgData.Icon ~= "NONE" and -heightIcon or 0, height)

						drawSparkle(textX + deviateX, textY + deviateY, size, size, msgData.Color, math.Rand(0, 1))

						nextCreateSparkle = UnPredictedCurTime() + .3
					end

					drawSparkles()
				end

				if(numDisplayed >= MAX_DISPLAYED)then
					-- Wait with showing the next ones
					break
				end
			end
		end

		-- Remove the old messages
		for _,index in pairs(oldMessages) do
			Minigolf.Messages.Remove(index)
		end
	end
end)