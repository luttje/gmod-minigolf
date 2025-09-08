Minigolf.Items = Minigolf.Items or {}

Minigolf.Items._DelayedEquips = Minigolf.Items._DelayedEquips or {}
Minigolf.Items._DelayedUnequips = Minigolf.Items._DelayedUnequips or {}

--- Function to queue an equip operation for later processing when the player is valid
--- This is useful for cases where the player entity might not be fully initialized yet.
--- @param item table The item to equip
--- @param playerIndex number The entity index of the player
function Minigolf.Items.EquipDelayed(item, playerIndex)
	table.insert(Minigolf.Items._DelayedEquips, {
		item = item,
		playerIndex = playerIndex
	})
end

--- Function to queue an unequip operation for later processing when the player is valid
--- @param item table
--- @param playerIndex number
function Minigolf.Items.UnequipDelayed(item, playerIndex)
	table.insert(Minigolf.Items._DelayedUnequips, {
		item = item,
		playerIndex = playerIndex
	})
end

-- Process all queued operations when InitPostEntity is called
hook.Add("InitPostEntity", "Minigolf.Items.ProcessDelayedOperations", function()
	for _, operation in ipairs(Minigolf.Items._DelayedEquips) do
		local player = Entity(operation.playerIndex)

		if (IsValid(player)) then
			Minigolf.Items.Equip(operation.item, player)
		else
			ErrorNoHalt("Failed to process delayed equip: Player " .. operation.playerIndex .. " is still invalid!\n")
		end
	end

	for _, operation in ipairs(Minigolf.Items._DelayedUnequips) do
		local player = Entity(operation.playerIndex)

		if (IsValid(player)) then
			Minigolf.Items.Unequip(operation.item, player)
		else
			ErrorNoHalt("Failed to process delayed unequip: Player " .. operation.playerIndex .. " is still invalid!\n")
		end
	end

	-- Clear the queues after processing
	Minigolf.Items._DelayedEquips = {}
	Minigolf.Items._DelayedUnequips = {}
end)

--[[
	Net Messages
--]]

net.Receive("Minigolf.Items.Equip", function()
	local playerIndex = net.ReadUInt(MAX_EDICT_BITS)
	local itemPath = net.ReadString()
	local item = Minigolf.Items.FindByProperty("FilePath", itemPath)

	if (not item) then
		ErrorNoHalt("Received invalid item! " .. itemPath .. " is not a valid item!\n")
		return
	end

	local player = Entity(playerIndex)

	if (IsValid(player)) then
		Minigolf.Items.Equip(item, player)
	else
		Minigolf.Items.EquipDelayed(item, playerIndex)
	end
end)

net.Receive("Minigolf.Items.Unequip", function()
	local playerIndex = net.ReadUInt(MAX_EDICT_BITS)
	local itemPath = net.ReadString()
	local item = Minigolf.Items.FindByProperty("FilePath", itemPath)

	if (not item) then
		ErrorNoHalt("Received invalid item! " .. itemPath .. " is not a valid item!\n")
		return
	end

	local player = Entity(playerIndex)

	if (IsValid(player)) then
		Minigolf.Items.Unequip(item, player)
	else
		Minigolf.Items.UnequipDelayed(item, playerIndex)
	end
end)
