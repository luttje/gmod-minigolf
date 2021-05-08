util.AddNetworkString("Minigolf.PrintMessageToScreen")

Minigolf.Messages = {}

function Minigolf.Messages.Send(receivers, message, icon, textEffect)
	net.Start("Minigolf.PrintMessageToScreen")
	net.WriteString(message)
	net.WriteString(icon or "NONE")
	net.WriteUInt(textEffect or TEXT_EFFECT_NORMAL, 8)

	if(not receivers)then
		net.Broadcast()
	else
		net.Send(receivers)
	end
end
