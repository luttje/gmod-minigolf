ITEM.Name = "Facepunch Ball"
ITEM.Model = "models/billiards/ball.mdl"
ITEM.Material = "minigolf/balls/communities/facepunch"
ITEM.UniqueID = "ball_facepunch"

if SERVER then
	resource.AddFile("materials/minigolf/balls/communities/facepunch.vmt")
	resource.AddFile("materials/minigolf/balls/communities/facepunch_normal.vtf")
end
