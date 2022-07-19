ITEM.Name = "Dragon Ball Z Ball"
ITEM.Model = "models/billiards/ball.mdl"
ITEM.Material = Material("minigolf/balls/dragon_ball_z/dragon_ball_1")
ITEM.ModulateColor = Color(255, 255, 255, 150)

if SERVER then
	resource.AddFile("materials/minigolf/balls/dragon_ball_z/dragon_ball_1.vmt")
	resource.AddFile("materials/minigolf/balls/dragon_ball_z/dragon_ball_1_normal.vtf")
end
