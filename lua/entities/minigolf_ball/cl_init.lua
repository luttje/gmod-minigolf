include("shared.lua")

function ENT:Initialize()
	if (self.ModelScale) then
		self:SetModelScale(self.ModelScale)
	end
end

function ENT:GetPlayer()
	return self:GetNWEntity("Player")
end

function ENT:GetPlayerName()
	return self:GetNWString("PlayerName", "Unknown Player")
end

function ENT:GetStart()
	return self:GetNWEntity("HoleStart")
end

function ENT:GetStrokes()
	return self:GetNWInt("Strokes", 0)
end

function ENT:Think()
	local player = self:GetPlayer()

	if (not IsValid(player)) then
		return
	end

	hook.Call("Minigolf.ThinkPlayerBall", Minigolf.GM(), player, self)
end

function ENT:Draw()
	local player = self:GetPlayer()

	if (not IsValid(player)) then
		return
	end

	-- Allow items to override drawing the ball or drawing something underneath it
	local overrideTable = {
		hasHandled = false
	}
	hook.Call("Minigolf.PreDrawPlayerBall", Minigolf.GM(), player, self)
	hook.Call("Minigolf.DrawPlayerBall", Minigolf.GM(), player, self, overrideTable)
	hook.Call("Minigolf.PostDrawPlayerBall", Minigolf.GM(), player, self)

	if (not overrideTable.hasHandled) then
		self:DrawModel()
	end
end
