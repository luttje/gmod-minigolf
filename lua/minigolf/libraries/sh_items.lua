local BASE_FILE_NAME = "_base.lua"

Minigolf.Items = Minigolf.Items or {}
Minigolf.Items.All = Minigolf.Items.All or {}
Minigolf.Items.BaseItems = Minigolf.Items.BaseItems or {}

local oldITEM

function Minigolf.Items.CreateNew()
	local item = {}

	item.Name = "Unnamed Item"
	item.Base = nil
	item.Icon = "box"

	table.insert(Minigolf.Items.All, item)

	return item
end

function Minigolf.Items.GetAll()
	return Minigolf.Items.All
end

function Minigolf.Items.Get(uniqueID)
	return Minigolf.Items.FindByProperty("UniqueID", uniqueID)
end

function Minigolf.Items.FindByProperty(property, value)
	for _, item in pairs(Minigolf.Items.All) do
		if item[property] == value then
			return item
		end
	end

	return nil
end

function Minigolf.Items.PrepareLoadItem(fileName, itemFilePath)
	oldITEM = ITEM

	ITEM = Minigolf.Items.CreateNew()
	ITEM.FilePath = itemFilePath

	-- Check if this is in a directory and thus is based on a base item file
	if (Minigolf.CurrentIncludeDirectory == nil) then
		return
	end

	local baseItem = Minigolf.Items.BaseItems[Minigolf.CurrentIncludeDirectory]

	if (baseItem == nil) then
		if (fileName == BASE_FILE_NAME) then
			ITEM.IsBaseItem = true
		else
			error("Base item file not found for item at " .. ITEM.FilePath)
		end
	end

	-- If we are loading an item in a sub category, set it's base to the item reference
	ITEM.Base = baseItem

	setmetatable(ITEM, {
		__index = function(table, key)
			if (baseItem and key ~= "IsBaseItem" and key ~= "Base") then
				return baseItem[key]
			end

			return rawget(table, key)
		end
	})
end

function Minigolf.Items.FinishLoadItem(fileName, itemFilePath)
	if (ITEM.IsBaseItem) then
		Minigolf.Items.BaseItems[Minigolf.CurrentIncludeDirectory] = ITEM
	end

	ITEM = oldITEM
end

function Minigolf.Items.IncludeDirectory(directory, baseFolder)
	Minigolf.IncludeDirectory(
		directory,
		baseFolder,
		true,
		Minigolf.Items.PrepareLoadItem,
		Minigolf.Items.FinishLoadItem,
		Minigolf.IncludeShared)
end

function Minigolf.Items.Equip(item, player)
	local equipedItems = player:GetMinigolfData("EquippedItems")
	equipedItems[item] = true

	if (SERVER) then
		Minigolf.Items.SyncItemEquipped(item, player)
	end

	if (item.OnEquip) then
		item:OnEquip(player)
	end
end

function Minigolf.Items.Unequip(item, player)
	local equipedItems = player:GetMinigolfData("EquippedItems")
	equipedItems[item] = nil

	if (SERVER) then
		Minigolf.Items.SyncItemUnequipped(item, player)
	end

	if (item.OnUnequip) then
		item:OnUnequip(player)
	end
end

--- Runs a function for each of the players' items which is or derives from the given base
function Minigolf.Items.RunCallbackForEquipedItems(player, itemOrBase, callback, ...)
	local equipedItems = player:GetMinigolfData("EquippedItems")

	for item, _ in pairs(equipedItems) do
		if (item == itemOrBase or item.Base == itemOrBase) then
			callback(player, item, ...)
		end
	end
end
