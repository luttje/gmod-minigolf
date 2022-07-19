ITEM.Name = "Facepunch Ball"
ITEM.Model = "models/billiards/ball.mdl"
ITEM.Material = Material("minigolf/balls/communities/facepunch")

if SERVER then
	resource.AddFile("materials/minigolf/balls/communities/facepunch.vmt")
	resource.AddFile("materials/minigolf/balls/communities/facepunch_normal.vtf")	
end
