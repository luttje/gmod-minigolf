hook.Add("NetworkEntityCreated", "Minigolf.Sync.InformServerOfCreatedEntities", function(entity)
  net.Start("Minigolf.InformPlayerOfEntityExisting")
  net.WriteString(entity:GetClass())
  net.WriteEntity(entity)
  net.SendToServer()
end)

net.Receive("Minigolf.PlaySound", function(length)
  local soundFile = net.ReadString()
  
  surface.PlaySound(soundFile)
end)

hook.Add("InitPostEntity", "Minigolf.SetupLocalPlayer", function()
  LocalPlayer().MinigolfEquippedItems = {}
end)