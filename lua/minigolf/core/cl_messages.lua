net.Receive("Minigolf.PrintMessageToScreen", function()
	local msg = net.ReadString()
	local icon = net.ReadString()
	local textEffect = net.ReadUInt(8)

	Minigolf.Messages.Print(msg, icon, textEffect)
end)
