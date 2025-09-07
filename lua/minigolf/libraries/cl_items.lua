Minigolf.Items = Minigolf.Items or {}

function Minigolf.Items.Equip(item, player)
	local equipedItems = player:GetMinigolfData("EquippedItems")
	equipedItems[item] = true

	Minigolf.Items.SyncItemEquipped(item, player)

	if (item.OnEquip) then
		item:OnEquip(player)
	end
end

function Minigolf.Items.Unequip(item, player)
	local equipedItems = player:GetMinigolfData("EquippedItems")
	equipedItems[item] = nil

	Minigolf.Items.SyncItemUnequipped(item, player)

	if (item.OnUnequip) then
		item:OnUnequip(player)
	end
end
