-- After the map has loaded all entities
hook.Add("InitPostEntity", "Minigolf.CountHolesAndMarkPhysboxesForCustomPhys", function()
	NUM_HOLES = 0

	Minigolf.Holes.All = Minigolf.Holes.All or {}

	-- Maybe we decide to have multiple starts to a single hole, anyways lets then just count the unique hole names
	for _, hole in ipairs(ents.FindByClass("minigolf_hole_start")) do
		local uniqueHoleName = hole:GetUniqueHoleName()
		
		if(not Minigolf.Holes.All[uniqueHoleName])then
			Minigolf.Holes.All[uniqueHoleName] = hole

			NUM_HOLES = NUM_HOLES + 1
		end
	end

	for _, physBox in ipairs(ents.FindByClass("func_physbox")) do
		physBox:SetCustomCollisionCheck(true)
	end
end)