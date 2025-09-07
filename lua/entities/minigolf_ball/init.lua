--[[
	Credits:

	- Some ball physics borrowed from MBilliards to get better physics on the balls
--]]
physenv.AddSurfaceData([["minigolf_ball"
{
	"scraperough"	"DoorSound.Null"
	"scrapesmooth"	"DoorSound.Null"
	"impacthard"	"DoorSound.Null"
	"impactsoft"	"DoorSound.Null"

	"audioreflectivity"		"0.66"
	"audiohardnessfactor"	"0.0"
	"audioroughnessfactor"	"0.0"

	"elasticity"	"1000"
	"friction"		"0.4"
	"density"		"10000"
}]])

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

util.AddNetworkString("Minigolf.StartBallForce")
util.AddNetworkString("Minigolf.SetBallForce")
util.AddNetworkString("Minigolf.GetBallForce")
util.AddNetworkString("Minigolf.GetBallForceCancel")

net.Receive("Minigolf.StartBallForce", function(len, player)
	local ball = player:GetMinigolfBall()

	if (IsValid(ball) and ball:GetUseable() and ball:GetStationary() and player:IsInDistanceOf(ball, DISTANCE_TO_BALL_MAX)) then
		ball:ShowForceMeter(not IsValid(player:GetBallGivingForce()))
	end
end)

local function rollBallInDirection(ball, directionVector)
	local phys = ball:GetPhysicsObject()

	if (IsValid(phys)) then
		phys:SetVelocity(directionVector)

		return true
	end

	ErrorNoHalt("Ball has no physics, can't roll in direction")

	return false
end

function ENT:Initialize()
	self:SetModel(self.Model)
	self:SetMaterial("minigolf/balls/regular_ball")

	if (self.ModelScale) then
		self:SetModelScale(self.ModelScale)
		self:DrawShadow(false)
	end

	self:SetUseType(SIMPLE_USE)
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS) -- Automatically called by PhysicsInitSphere
	self:SetSolid(SOLID_VPHYSICS)    -- Overriden by PhysicsInitSphere to SOLID_BBOX
	self:SetCustomCollisionCheck(true)

	-- Set perfect sphere collisions (54mm of diameter)
	self:PhysicsInitSphere(0.94, "minigolf_ball")
	self:SetCollisionBounds(Vector(-0.94, -0.94, -0.94), Vector(0.94, 0.94, 0.94))

	local physObj = self:GetPhysicsObject()

	if (physObj:IsValid()) then
		physObj:SetMass(1)
		physObj:SetDamping(0, 1.2)
		physObj:Wake()
	end

	self:Activate()
	self:SetStrokes(0)
	self:SetUseable(true)
end

function ENT:OnRemove()
	hook.Call("Minigolf.BallRemove", Minigolf.GM(), self:GetPlayer(), self)
end

function ENT:PhysicsCollide(data, physObj)
	local speed, hitEnt = data.Speed, data.HitEntity
	local newVelocity = physObj:GetVelocity()
	local oldVelocityLength = data.OurOldVelocity:Length()

	newVelocity = physObj:GetVelocity():GetNormalized() * math.max(oldVelocityLength, speed)

	if (oldVelocityLength <= 0.14) then
		physObj:SetVelocity(Vector(0, 0, 0))
		physObj:EnableMotion(false)
		return physObj:EnableMotion(true)
	end

	newVelocity = newVelocity * 0.75

	return physObj:SetVelocity(newVelocity)
end

function ENT:Think()
	local velocity = self:GetVelocity()
	local velocityLength = velocity:Length()

	if (velocityLength < 5) then
		local phys = self:GetPhysicsObject()

		if (IsValid(phys)) then
			phys:AddVelocity(-velocity)
		end

		if (not self:GetStationary()) then
			self:SetStationary(true)

			local physObj = self:GetPhysicsObject()
			physObj:EnableMotion(false)
			physObj:SetVelocityInstantaneous(Vector(0, 0, 0))
			physObj:EnableMotion(true)

			hook.Call("Minigolf.BallRolledStationary", Minigolf.GM(), self)
		end
	else
		self:SetStationary(false)
	end
end

function ENT:MoveToPos(position)
	local physObj = self:GetPhysicsObject()

	physObj:EnableMotion(false)
	self:SetPos(position)
	physObj:SetVelocityInstantaneous(Vector(0, 0, 0))
	physObj:EnableMotion(true)
end

function ENT:ReturnToStart()
	local startPos = self:GetStart():GetPos()

	self:MoveToPos(startPos)
end

function ENT:OnUse(activator)
	-- Make sure the activator is a player and is in range
	if (activator:IsPlayer() and activator:IsInDistanceOf(self, DISTANCE_TO_BALL_MAX)) then
		if (activator:KeyDown(IN_RELOAD)) then
			if (activator == self:GetPlayer()) then
				self:SetStrokes(self:GetStrokes() + 1)
				self:ReturnToStart()
			elseif (not IsValid(self:GetPlayer())) then
				Minigolf.Holes.End(nil, self, self:GetStart())
			end
		end
	end
end

function ENT:ShowForceMeter(shouldShow)
	local player = self:GetPlayer()

	if (shouldShow) then
		player:SetBallGivingForce(self)

		hook.Call("Minigolf.BallStartedGivingForce", Minigolf.GM(), player, self)
	else
		player:SetBallGivingForce(nil)

		hook.Call("Minigolf.BallStoppedGivingForce", Minigolf.GM(), player, self)
	end
end

function ENT:SetStationary(stationary)
	self._Stationary = stationary
end

function ENT:GetStationary()
	return self._Stationary
end

function ENT:SetUseable(useable)
	self._Useable = useable
end

function ENT:GetUseable()
	return self._Useable
end

function ENT:SetPlayer(player)
	self._Player = player
	self._Player:SetPlayerBall(self)

	player:SetNWEntity("Ball", self)
	self:SetNWString("PlayerName", player:Nick())
	self:SetNWEntity("Player", player)

	if (not self.hasInitialized) then
		self.hasInitialized = true
		hook.Call("Minigolf.BallInit", Minigolf.GM(), player, self)
	end
end

function ENT:GetPlayer()
	return self._Player
end

function ENT:SetStart(start)
	self._Start = start
	self:SetNWEntity("HoleStart", start)
end

function ENT:GetStart()
	return self._Start
end

function ENT:SetStrokes(amount)
	self._Strokes = amount
	self:SetNWInt("Strokes", amount)
end

function ENT:GetStrokes()
	return self._Strokes
end

function ENT:OnTakeDamage(dmgInfo)
	dmgInfo:ScaleDamage(0)
end

net.Receive("Minigolf.SetBallForce", function(len, ply)
	local ball = ply:GetBallGivingForce()

	if (IsValid(ball)) then
		local givenForce = net.ReadFloat()

		if (givenForce == Minigolf.CANCEL_BALL_FORCE) then
			ball:ShowForceMeter(false)
			return
		end

		local ballForce = math.min(givenForce * 1000, 2048)
		local ballAngle = net.ReadAngle()

		-- Don't let us hit the ball into the ground.
		-- ballAngle.p = math.max(0, ballAngle.p)

		-- In fact, make it zero for now, so we only fire level with the ground
		ballAngle.p = 0

		local hookCall = hook.Call("Minigolf.PlayerHitBall", Minigolf.GM(), ply, ball)

		if (hookCall ~= false) then
			rollBallInDirection(ball, -ballAngle:Right() * ballForce)

			ball:SetStrokes(ball:GetStrokes() + 1)
		end

		ball = nil
	end
end)

function ENT:UpdateTransmitState()
	return TRANSMIT_ALWAYS
end
