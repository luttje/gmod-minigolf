Minigolf.Items = Minigolf.Items or {}

util.AddNetworkString("Minigolf.Items.Equip")
util.AddNetworkString("Minigolf.Items.Unequip")

function Minigolf.Items.IsEquiped(item, player)
	return player:GetMinigolfData("EquippedItems")[item] ~= nil
end

function Minigolf.Items.SyncItemEquipped(item, player, receiver)
	net.Start("Minigolf.Items.Equip")
	net.WriteEntity(player)
	net.WriteString(item.FilePath)

	if (receiver) then
		net.Send(receiver)
	else
		net.Broadcast()
	end
end

function Minigolf.Items.SyncItemUnequipped(item, player)
	net.Start("Minigolf.Items.Unequip")
	net.WriteEntity(player)
	net.WriteString(item.FilePath)
	net.Broadcast()
end

function Minigolf.Items.SyncAllEquippedItems(receiver)
	for _, player in ipairs(player.GetAll()) do
		local equipedItems = player:GetMinigolfData("EquippedItems", {})

		if (equipedItems) then
			for item, _ in pairs(equipedItems) do
				Minigolf.Items.SyncEquippedItem(item, player, receiver)
			end
		end
	end
end
