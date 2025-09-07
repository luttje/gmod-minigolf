include("shared.lua")

function ENT:GetMaxStrokes()
	return self:GetNWInt("MaxStrokes", 12)
end

function ENT:GetMaxPitch()
	return self:GetNWInt("MaxPitch", 0)
end

function ENT:GetHoleName()
	return self:GetNWString("HoleName", "Unknown Hole")
end

function ENT:GetUniqueHoleName()
	return self:GetCourse() .. self:GetHoleName()
end

function ENT:GetCourse()
	return self:GetNWString("HoleCourse", "")
end

function ENT:GetOrder()
	return self:GetNWInt("HoleOrder")
end

function ENT:GetPar()
	return self:GetNWInt("HolePar", 3)
end

function ENT:GetLimit()
	return self:GetNWInt("HoleLimit", 60)
end

function ENT:GetDescription()
	return self:GetNWString("HoleDescription", "")
end
