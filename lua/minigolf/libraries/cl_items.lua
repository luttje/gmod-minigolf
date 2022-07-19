Minigolf.Items = Minigolf.Items or {}

function Minigolf.Items.Equip(item, player)
  player.MinigolfEquippedItems[item] = true

  Minigolf.Items.SyncItemEquipped(item, player)

  if(item.OnEquip)then
    item:OnEquip(player)
  end
end

function Minigolf.Items.Unequip(item, player)
  player.MinigolfEquippedItems[item] = nil

  Minigolf.Items.SyncItemUnequipped(item, player)
  
  if(item.OnUnequip)then
    item:OnUnequip(player)
  end
end