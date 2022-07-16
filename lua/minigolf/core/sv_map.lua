hook.Add("InitPostEntity", "Minigolf.CountHolesAndMarkPhysboxesForCustomPhys", function()
	Minigolf.Holes.TotalCount = 0

	Minigolf.Holes.All = Minigolf.Holes.All or {}

	-- When we decide to have multiple starts for a single hole count the unique hole names
	for _, hole in ipairs(ents.FindByClass("minigolf_hole_start")) do
		local uniqueHoleName = hole:GetUniqueHoleName()
		
		if(not Minigolf.Holes.All[uniqueHoleName])then
			Minigolf.Holes.All[uniqueHoleName] = hole

			Minigolf.Holes.TotalCount = Minigolf.Holes.TotalCount + 1
		end
	end

	for _, physBox in ipairs(ents.FindByClass("func_physbox")) do
		physBox:SetCustomCollisionCheck(true)
	end
end)