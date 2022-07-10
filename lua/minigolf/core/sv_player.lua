util.AddNetworkString("Minigolf.InformPlayerOfEntityExisting")

net.Receive("Minigolf.InformPlayerOfEntityExisting", function(len, player)
  local className = net.ReadString() -- DBG only, not needed
  local sharedEntity = net.ReadEntity()

  if(not IsValid(sharedEntity) and not sharedEntity == Entity(0))then
    print("Received info on clientside entity (I think)", sharedEntity, className) -- Debug: test if this can actually happen. Are clientside entities NW entities? No right?
    return
  end

  player:SetEntityExists(sharedEntity)
end)
