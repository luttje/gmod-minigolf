AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:SpawnFunction( ply, tr, ClassName )
	if ( not tr.Hit ) then return end

	local ent = ents.Create( ClassName )
	ent:SetPos( tr.HitPos + (tr.HitNormal * 15) )
	ent:Spawn()

	return ent
end

function ENT:Initialize()
	self._MaxRetryRules = self._MaxRetryRules or {}
	self:SetModel(self.Model)
	self:SetMoveType(MOVETYPE_NONE)
	self:SetUseType( SIMPLE_USE )
	self:SetSolid(SOLID_BBOX)
	self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
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
			local canPlay = hook.Call("Minigolf.CanStartPlaying", Minigolf.GM(), activator, self)
			
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
			Minigolf.Messages.Send(activator, "You can not play on this hole as you are already playing the hole '" .. activeHole:GetHoleName() .. "'!", nil, Minigolf.TEXT_EFFECT_DANGER)
		end
	else
		local ballPlayer = ball:GetPlayer()

		if(ballPlayer ~= activator)then
			if(IsValid(ballPlayer))then
				Minigolf.Messages.Send(activator, "You can not play on this hole as '" .. ballPlayer:Nick() .. "' is already playing'!", nil, Minigolf.TEXT_EFFECT_DANGER)
			else
				Minigolf.Holes.End(nil, ball, ball:GetStart())
				Minigolf.Messages.Send(activator, "A player disconnected while playing here. Removed their ball, try again to start playing.", nil, Minigolf.TEXT_EFFECT_ATTENTION)
			end
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
	elseif(key == "maxretriesaftercompleting")then
		self:SetMaxRetries(Minigolf.RETRY_RULE_AFTER_COMPLETING, tonumber(value))
	elseif(key == "maxretriesaftertimelimit")then
		self:SetMaxRetries(Minigolf.RETRY_RULE_AFTER_TIME_LIMIT, tonumber(value))
	elseif(key == "maxretriesaftermaxstrokes")then
		self:SetMaxRetries(Minigolf.RETRY_RULE_AFTER_MAX_STROKES, tonumber(value))
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

function ENT:SetMaxRetries(rule, maxRetries)
	self._MaxRetryRules = self._MaxRetryRules or {}
	self._MaxRetryRules[rule] = maxRetries
end

function ENT:GetMaxRetries(rule)
	if(self._MaxRetryRules[rule] ~= nil)then
		return self._MaxRetryRules[rule]
	end

	local globalConfig = ents.FindByClass("minigolf_config")[1]

	if(not IsValid(globalConfig))then
		return
	end

	return globalConfig:GetDefaultMaxRetries(rule)
end

function ENT:UpdateTransmitState()	
	return TRANSMIT_ALWAYS 
end