Minigolf.Holes = Minigolf.Holes or {}

function Minigolf.Holes.GetActive()
	local activeHole = LocalPlayer():GetActiveHole()
	local overrideActiveHole = hook.Call("Minigolf.OverrideActiveHole", Minigolf.GM(), activeHole)

	if (overrideActiveHole ~= nil) then
		return overrideActiveHole
	end

	return activeHole
end
