net.Receive("Minigolf.Items.Equip", function()
  local player = net.ReadEntity()
  local itemPath = net.ReadString()
  local item = Minigolf.Items.FindByProperty("FilePath", itemPath)
  
  if(not item)then
    ErrorNoHalt("Received invalid item! " .. itemPath .. " is not a valid item!\n")
    return
  end
  
  Minigolf.Items.Equip(item, player)
end)

net.Receive("Minigolf.Items.Unequip", function()
  local player = net.ReadEntity()
  local itemPath = net.ReadString()
  local item = Minigolf.Items.FindByProperty("FilePath", itemPath)
  
  if(not item)then
    ErrorNoHalt("Received invalid item! " .. itemPath .. " is not a valid item!\n")
    return
  end
  
  Minigolf.Items.Unequip(item, player)
end)