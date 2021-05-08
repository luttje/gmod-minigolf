
function ConfigMenu()
	local main = createFrame("Config Menu")

	main:MakePopup()
	RestoreCursorPosition()
end


function createLabel(text, color)

end

function createSetting()
	--sd
end

-- Listen for callback from server when pressing F1 (help menu)
net.Receive("Minigolf.ConfigMenu", function()
	ConfigMenu()
end)
