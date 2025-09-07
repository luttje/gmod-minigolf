util.AddNetworkString("Minigolf.PrintMessageToScreen")

Minigolf.Messages = Minigolf.Messages or {}

function Minigolf.Messages.Send(receivers, message, icon, textEffect)
	print("[Minigolf Message] ", message)

	net.Start("Minigolf.PrintMessageToScreen")
	net.WriteString(message)
	net.WriteString(icon or "NONE")
	net.WriteUInt(textEffect or Minigolf.TEXT_EFFECT_NORMAL, 8)

	if (not receivers) then
		net.Broadcast()
	else
		net.Send(receivers)
	end
end
