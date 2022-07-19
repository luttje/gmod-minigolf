local BASE_FILE_NAME = "_base.lua"

Minigolf.Items = Minigolf.Items or {}
Minigolf.Items.All = Minigolf.Items.All or {}

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
  table.insert(Minigolf.Items.All, ITEM)
  ITEM.FilePath = itemFilePath

  if(Minigolf.CurrentIncludeDirectory == nil)then
    return
  end

  local baseItemPath = Minigolf.PathCombine(Minigolf.CurrentIncludeDirectory, BASE_FILE_NAME)

  if(itemFilePath == baseItemPath)then
    ITEM.IsBaseItem = true
    return
  end

  -- If we are loading an item in a sub category, set it's base to the item reference
  ITEM.Base = Minigolf.Items.FindByProperty("FilePath", baseItemPath)

  setmetatable(ITEM, {__index = ITEM.Base})
end

function Minigolf.Items.FinishLoadItem(fileName, itemFilePath)
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
  player.MinigolfEquippedItems[item] = true

  if(SERVER)then
    Minigolf.Items.SyncItemEquipped(item, player)
  end

  if(item.OnEquip)then
    item:OnEquip(player)
  end
end

function Minigolf.Items.Unequip(item, player)
  player.MinigolfEquippedItems[item] = nil

  if(SERVER)then
    Minigolf.Items.SyncItemUnequipped(item, player)
  end

  if(item.OnUnequip)then
    item:OnUnequip(player)
  end
end
