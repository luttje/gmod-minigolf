DEFINE_BASECLASS("base_anim")

DISTANCE_TO_BALL_MAX = 80

ENT.PrintName = "Minigolf Ball"
ENT.Author = "Luttje"
ENT.Information = "The ball to play with"
ENT.Category = "Minigolf"

ENT.Spawnable = false

--[[ Sadly an effect and has no physics:
ENT.Model = Model("models/nomad/golfball.mdl")
ENT.ModelScale = false]]
-- Shitty alternative: "models/xqm/rails/gumball_1.mdl"
ENT.Model = Model("models/billiards/ball.mdl")
