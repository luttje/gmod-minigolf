local playerLibrary = player

Minigolf.HideDefaultHUDElements = {
	CHudHealth = true,
	CHudBattery = true,
	CHudAmmo = true,
	CHudDamageIndicator = true,
	CHudWeaponSelection = true,
	CHudCrosshair = true
}

hook.Add("Minigolf.GetAdjustedHoleFlagColor", "Minigolf.GetAdjustedHoleFlagColor", function(hole, flagColor)
	local teamID = hole:GetNWInt("Minigolf.ActiveTeam", Minigolf.NO_TEAM_PLAYING)
	if(teamID > Minigolf.NO_TEAM_PLAYING)then
		return team.GetColor(teamID)
	end
end)

hook.Add("Minigolf.AdjustColumnScore", "Minigolf.AdjustColumnScore", function(column, strokes, par)
	if(strokes == Minigolf.HOLE_SKIPPED)then
		column:SetText("SKIPPING")
		column:SetTooltip("The player is skipping this hole since they joined the team late.")
	end
end)

hook.Add("Minigolf.OverrideActiveHole", "Minigolf.OverrideActiveHole", function(activeHole)
	for _, start in ipairs(ents.FindByClass("minigolf_hole_start"))do
		if(start:GetNWInt("ActiveTeam", Minigolf.NO_TEAM_PLAYING) == LocalPlayer():Team())then
			return start
		end
	end
end)

local currentSwappingTime = nil

hook.Add("Minigolf.AdjustHolePanel", "Minigolf.DrawTeamMemberTimes", function(holePanel)
	-- Draw the timelimit for players on our team
	for _, player in pairs(playerLibrary.GetAll()) do
		if(LocalPlayer():Team() == player:Team())then
			if((player._LimitTimeLeft and player._LimitTimeLeft > UnPredictedCurTime()) 
			or LocalPlayer()._LimitTimeLeftForSwap)then
				if(LocalPlayer()._LimitTimeLeftForSwap)then
					local time = math.max(0, math.Round(LocalPlayer()._LimitTimeLeft - UnPredictedCurTime()))
					currentSwappingTime = time
					holePanel:PaintManual()
					
					return true
				else
					currentSwappingTime = nil
				end

				local time = math.max(0, math.Round(player._LimitTimeLeft - UnPredictedCurTime()))
				holePanel:SetPlaying(time)
				holePanel:PaintManual()
				
				return true
			end
		end
	end
end)

hook.Add("Minigolf.AdjustHintsTexts", "Minigolf.AdjustHintsTexts", function(texts)
	table.insert(texts, "Press 'T' or type /team to open the team menu")
end)

hook.Add("Minigolf.AdjustRebuildHolePanel", "Minigolf.AdjustRebuildHolePanel", function(holePanel, hole, strokes)
	local activeTeam = hole:GetNWInt("ActiveTeam", Minigolf.NO_TEAM_PLAYING)

	if(currentSwappingTime ~= nil)then
		holePanel:SetAlpha(200 + (55 * math.sin(CurTime())))
		holePanel.hintLabel:SetText("Waiting for a team member to start playing\nYou have " .. currentSwappingTime .. " seconds to switch player!")
		holePanel.hintLabel:SetContentAlignment(5) -- TODO: not working
	elseif(activeTeam > Minigolf.NO_TEAM_PLAYING and activeTeam ~= LocalPlayer():Team())then
		holePanel.hintLabel:SetText(team.GetName(activeTeam) .. " is currently playing this hole")
	elseif(activeTeam == LocalPlayer():Team())then
		holePanel.hintLabel:SetText("Your team is currently playing this hole.")
	end
end)

hook.Add("HUDShouldDraw", "Minigolf.HideDefaultHUD", function(name)
	if(Minigolf.HideDefaultHUDElements[name]) then
		return false
	end
end)

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