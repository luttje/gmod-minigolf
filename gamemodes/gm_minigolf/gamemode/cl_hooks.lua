Minigolf.HideDefaultHUDElements = {
	CHudHealth = true,
	CHudBattery = true,
	CHudAmmo = true,
	CHudDamageIndicator = true,
	CHudWeaponSelection = true,
	CHudCrosshair = true
};

hook.Add("HUDShouldDraw", "Minigolf.HideDefaultHUD", function(name)
	if(Minigolf.HideDefaultHUDElements[name]) then
		return false
	end
end);

hook.Add("SpawnMenuEnabled", "Minigolf.DisableSpawnMenu", function()
	return false
end)

hook.Add("ContextMenuOpen", "Minigolf.DisableContextMenu", function()
	return false
end)

hook.Add("PreDrawHalos", "Minigolf.AddHalosAroundTeamMembers", function()
	local teamID = LocalPlayer():Team()

	halo.Add(team.GetPlayers(teamID), team.GetColor(teamID), 5, 5, 2, true, true)
end)

-- Override drawing the death notices
function GM:DrawDeathNotice(x, y)
end