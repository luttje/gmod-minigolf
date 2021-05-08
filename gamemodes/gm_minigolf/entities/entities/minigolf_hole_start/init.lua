AddCSLuaFile("cl_init.lua");
AddCSLuaFile("shared.lua");
include("shared.lua");

function ENT:SpawnFunction( ply, tr, ClassName )
	if ( not tr.Hit ) then return end

	local ent = ents.Create( ClassName )
	ent:SetPos( tr.HitPos + (tr.HitNormal * 15) )
	ent:Spawn()

	return ent
end

function ENT:Initialize()
	if ( CLIENT ) then return end

	self:SetModel(self.Model)
	self:SetMoveType(MOVETYPE_NONE)
	self:SetUseType( SIMPLE_USE )
	self:SetSolid(SOLID_BBOX);
	self:SetCollisionGroup(COLLISION_GROUP_WEAPON);
	self:SetNoDraw(true)
end

function ENT:SpawnBall(activator)
	local ball = ents.Create("minigolf_ball")
	ball:SetPos(self:GetPos())
	ball:Spawn()

	ball:SetStart(self)
	ball:SetPlayer(activator)
	ball:ShowForceMeter() -- start immediately

	return ball
end

function ENT:Use(activator, caller)
	local ball = self:GetBall()

	if(not IsValid(ball) and activator:IsPlayer())then
		local activeHole = activator:GetActiveHole()

		if(not IsValid(activeHole))then
			local canPlay = hook.Call("MinigolfCanStartPlaying", gm(), activator, self)
			
			if(canPlay ~= false)then
				ball = self:SetBall(self:SpawnBall(activator))

				Minigolf.Holes.Start(activator, ball, self)

				ball:ShowForceMeter(true)
			end
		elseif(activeHole == self)then
			if(IsValid(ball))then
				ball:ReturnToStart()
			else
				-- It seems the ball has glitched out and gone missing? Respawn it
				self:SetBall(self:SpawnBall(activator))
			end
		else
			Minigolf.Messages.Send(activator, "You can not play on this hole as you are already playing the hole '" .. activeHole:GetHoleName() .. "'!", nil, TEXT_EFFECT_DANGER)
		end
	else
		if(ball:GetPlayer() ~= activator)then
			local playerName = "A disconnected player"

			if(IsValid(ball:GetPlayer()))then
				playerName = ball:GetPlayer():Nick()
			end

			Minigolf.Messages.Send(activator, "You can not play on this hole as '" .. playerName .. "' is already playing'!", nil, TEXT_EFFECT_DANGER)
		end
	end
end

function ENT:OnBallHit(ball)
end

function ENT:KeyValue(key, value)
	key = string.lower(key)
	
	if(key == "hole")then
		self:SetHoleName(tostring(value):Trim())
	elseif(key == "course")then
		self:SetCourse(tostring(value):Trim())
	elseif(key == "order")then
		self:SetOrder(tonumber(value))
	elseif(key == "par")then
		self:SetPar(tonumber(value))
	elseif(key == "limit")then
		self:SetLimit(tonumber(value))
	elseif(key == "description")then
		self:SetDescription(tostring(value):Trim())
	elseif(key == "maxstrokes")then
		self:SetMaxStrokes(tonumber(value))
	elseif(key == "maxpitch")then
		self:SetMaxPitch(tonumber(value))
	end
end

function ENT:SetBall(ball)
	self._Ball = ball

	return ball
end

function ENT:GetBall()
	return self._Ball
end

function ENT:GetPlayer()
	if(not IsValid(self._Ball))then
		return
	end

	return self._Ball:GetPlayer()
end

function ENT:SetActiveTeam(team)
	self._ActiveTeam = team
	self:SetNWInt("ActiveTeam", team or -1)
end

function ENT:GetActiveTeam()
	return self._ActiveTeam
end

function ENT:SetMaxStrokes(maxStrokes)
	self._MaxStrokes = maxStrokes
	self:SetNWInt("MaxStrokes", maxStrokes)
end

function ENT:GetMaxStrokes()
	return self._MaxStrokes or 12
end

function ENT:SetMaxPitch(maxPitch)
	self._MaxPitch = maxPitch
	self:SetNWInt("MaxPitch", maxPitch)
end

function ENT:GetMaxPitch()
	return self._MaxPitch or 0
end

function ENT:SetHoleName(holeName)
	self._HoleName = holeName
	self:SetNWString("HoleName", holeName)
end

function ENT:GetHoleName()
	return self._HoleName
end

function ENT:GetUniqueHoleName()
	return self:GetCourse() .. self:GetHoleName()
end

function ENT:SetCourse(courseName)
	self._HoleCourse = courseName
	self:SetNWString("HoleCourse", courseName)
end

function ENT:GetCourse()
	return self._HoleCourse or ""
end

--- Set the order in the scoreboard
function ENT:SetOrder(order)
	self._HoleOrder = order
	self:SetNWInt("HoleOrder", order)
end

function ENT:GetOrder()
	return self._HoleOrder
end

function ENT:SetPar(par)
	self._HolePar = par
	self:SetNWInt("HolePar", par)
end

function ENT:GetPar()
	return self._HolePar or 3
end

function ENT:SetLimit(limitInSeconds)
	self._HoleLimit = limitInSeconds
	self:SetNWInt("HoleLimit", limitInSeconds)
end

function ENT:GetLimit()
	return self._HoleLimit or 60
end

function ENT:SetDescription(description)
	self._HoleDescription = description
	self:SetNWString("HoleDescription", description)
end

function ENT:GetDescription()
	return self._HoleDescription
end

function ENT:UpdateTransmitState()	
	return TRANSMIT_ALWAYS 
end