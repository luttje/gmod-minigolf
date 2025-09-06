AddCSLuaFile()

DEFINE_BASECLASS("base_anim")

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Minigolf Track Designer Vertex"
ENT.Category = "Minigolf"
ENT.Spawnable = false
ENT.AdminOnly = false

hook.Add("PhysgunPickup", "MinigolfDesignerVertex.PreventPhysgunPickup", function(ply, entity)
  if (entity:GetClass() == "minigolf_track_designer_vertex" and entity:GetNoDraw()) then
    return false
  end
end)
