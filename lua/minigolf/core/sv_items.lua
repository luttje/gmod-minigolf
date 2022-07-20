Minigolf.Commands.Register("equipitem", function(player, ...)
	if(not player:IsAdmin())then
		Minigolf.Messages.Send(player, "This command is only for admins!", nil, Minigolf.TEXT_EFFECT_DANGER)
		return
	end

	local itemNameOrID = table.concat({...}, " ")
	local item = Minigolf.Items.Get(itemNameOrID)
	
	if(not item)then
		item = Minigolf.Items.FindByProperty("Name", itemNameOrID)
	
		if(not item)then
			Minigolf.Messages.Send(player, itemNameOrID .. " is not a valid item!", nil, Minigolf.TEXT_EFFECT_DANGER)
			return
		end
	end

	Minigolf.Items.Equip(item, player)
	Minigolf.Messages.Send(player, "You equipped " .. itemNameOrID .. "!", nil, Minigolf.TEXT_EFFECT_SUCCESS)
end, "Equip a Minigolf item on yourself")

Minigolf.Commands.Register("unequipitem", function(player, ...)
	if(not player:IsAdmin())then
		Minigolf.Messages.Send(player, "This command is only for admins!", nil, Minigolf.TEXT_EFFECT_DANGER)
		return
	end

	local itemName = table.concat({...}, " ")
	local item = Minigolf.Items.FindByProperty("Name", itemName)

	if(not item)then
		Minigolf.Messages.Send(player, itemName .. " is not a valid item!", nil, Minigolf.TEXT_EFFECT_DANGER)
		return
	end

	Minigolf.Items.Unequip(item, player)
	Minigolf.Messages.Send(player, "You unequipped " .. itemName .. "!", nil, Minigolf.TEXT_EFFECT_SUCCESS)
end, "Equip a Minigolf item on yourself")

hook.Add("PlayerInitialSpawn", "Minigolf.SyncAllPlayerItems", function(player)
	player:SetMinigolfData("EquippedItems", {})

	Minigolf.Items.SyncAllEquippedItems(player)
end)