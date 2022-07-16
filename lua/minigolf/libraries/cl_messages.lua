-- Store messages received
local storedMessages = {}

Minigolf.Messages = Minigolf.Messages or {}

--- Prints a message to the message medium (screen) immediately.
---@overload fun(msg:string, icon:string):nil
---@overload fun(msg:string):nil
---@param msg string The message to print
---@param icon string Optional icon to give the message (see: `content/resource/fonts/golf_icons.ttf`)
---@param textEffect number Optional effect used when drawing the message. See TEXT_EFFECT_ defintions in shared.lua
---@return nil
function Minigolf.Messages.Print(msg, icon, textEffect)
	local colorNegative = Minigolf.Colors.Get("Negative")
	local colorInformation = Minigolf.Colors.Get("Information")
	local colorChat = Minigolf.Colors.Get("ChatPrint")
	local colorPositive = Minigolf.Colors.Get("Positive")
	local color = Minigolf.Colors.Get("Background")

	if(textEffect == Minigolf.TEXT_EFFECT_ATTENTION)then
		color = colorChat
	elseif(textEffect == Minigolf.TEXT_EFFECT_DANGER)then
		color = colorNegative
	elseif(textEffect == Minigolf.TEXT_EFFECT_SPARKLE)then
		color = Color(255, 195, 18)
	elseif(textEffect == Minigolf.TEXT_EFFECT_CASH)then
		color = colorPositive
	end

	table.insert(storedMessages, {
		Duration = 5,
		TextEffect = textEffect,
		Message = msg,
		Icon = icon,
		Color = color
	})

	chat.AddText(color, msg)
	surface.PlaySound("UI/buttonclick.wav")
end

function Minigolf.Messages.GetAll()
	return storedMessages
end

function Minigolf.Messages.Remove(index)
	table.remove(storedMessages, index)
end