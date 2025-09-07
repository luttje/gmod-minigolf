include("shared.lua")

ENT.Icon = "entities/minigolf_hole_start.png"

-- Draw at custom time, after everything else
ENT.RenderGroup = RENDERGROUP_OTHER

function ENT:Initialize()
	self.GripMaterial = Material("sprites/grip")
	self.GripMaterialHover = Material("sprites/grip_hover")
end

function ENT:Draw()
	if (not self:GetIsCustom()) then
		return
	end

	local player = LocalPlayer()
	local weapon = player:GetActiveWeapon()

	if (not IsValid(weapon)) then
		return
	end

	local weaponName = weapon:GetClass()

	if (weaponName ~= "weapon_physgun" and weaponName ~= "gmod_tool") then
		return
	end

	if (self:BeingLookedAtByLocalPlayer()) then
		render.SetMaterial(self.GripMaterialHover)
	else
		render.SetMaterial(self.GripMaterial)
	end

	render.DrawSprite(self:GetPos(), 16, 16, color_white)
end

hook.Add("PostDrawOpaqueRenderables", "Minigolf.DrawStartEntities",
	function(isDrawingDepth, isDrawingSkybox, isDrawing3dSkybox)
		if (isDrawingDepth or isDrawingSkybox or isDrawing3dSkybox) then
			return
		end

		for _, entity in pairs(ents.FindByClass("minigolf_hole_start")) do
			if (IsValid(entity)) then
				entity:Draw()
			end
		end
	end)

function ENT:BeingLookedAtByLocalPlayer()
	local ply = LocalPlayer()
	local eyeTrace = ply:GetEyeTrace()

	if (not IsValid(eyeTrace.Entity)) then return false end
	if (eyeTrace.Entity ~= self) then return false end
	if (eyeTrace.HitPos:Distance(ply:EyePos()) > 100) then return false end

	return true
end

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

--[[
	Net Messages
--]]

net.Receive("Minigolf.HoleConfigStart", function()
	local entity = net.ReadEntity()
	local maxRetriesCompleting = net.ReadInt(8)
	local maxRetriesTimeLimit = net.ReadInt(8)
	local maxRetriesMaxStrokes = net.ReadInt(8)

	if (not IsValid(entity)) then
		return
	end

	local holeName = entity:GetHoleName()
	local course = entity:GetCourse()
	local order = entity:GetOrder()
	local par = entity:GetPar()
	local limit = entity:GetLimit()
	local description = entity:GetDescription()
	local maxStrokes = entity:GetMaxStrokes()
	local maxPitch = entity:GetMaxPitch()

	-- Create the configuration window
	local frame = vgui.Create("DFrame")
	frame:SetTitle("Configure Minigolf Hole")
	frame:SetSize(400, 600)
	frame:Center()
	frame:MakePopup()

	local paddingLeft, paddingTop, paddingRight, paddingBottom = frame:GetDockPadding()
	frame:DockPadding(paddingLeft, paddingTop, paddingRight, paddingBottom + 10)

	local function CreateTextEntry(parent, labelText, value, isNumeric)
		local panel = vgui.Create("DSizeToContents", parent)
		panel:Dock(TOP)
		panel:DockMargin(10, 10, 10, 0)
		panel:SetSizeX(false)

		local label = vgui.Create("DLabel", panel)
		label:SetText(labelText)
		label:Dock(LEFT)
		label:SizeToContents()

		local entry = vgui.Create("DTextEntry", panel)
		entry:Dock(FILL)
		entry:DockMargin(10, 0, 0, 0)
		entry:SetValue(tostring(value))
		if (isNumeric) then
			entry:SetNumeric(true)
		end

		return entry
	end

	-- Create form fields
	local holeNameEntry = CreateTextEntry(frame, "Hole Name:", holeName, false)
	local courseEntry = CreateTextEntry(frame, "Course Name:", course, false)
	local orderEntry = CreateTextEntry(frame, "Order:", order, true)
	local parEntry = CreateTextEntry(frame, "Par:", par, true)
	local limitEntry = CreateTextEntry(frame, "Time Limit (sec):", limit, true)
	local descEntry = CreateTextEntry(frame, "Description:", description, false)
	local maxStrokesEntry = CreateTextEntry(frame, "Max Strokes:", maxStrokes, true)
	local maxPitchEntry = CreateTextEntry(frame, "Max Pitch (degrees):", maxPitch, true)
	local maxRetriesCompEntry = CreateTextEntry(frame, "Retries After Success:", maxRetriesCompleting, true)
	local maxRetriesTimeEntry = CreateTextEntry(frame, "Retries After Time Limit:", maxRetriesTimeLimit, true)
	local maxRetriesStrokesEntry = CreateTextEntry(frame, "Retries After Max Strokes:", maxRetriesMaxStrokes, true)

	-- Help text
	local helpLabel = vgui.Create("DLabel", frame)
	helpLabel:SetText("Use -1 for infinite retries, 0 for no retries")
	helpLabel:Dock(TOP)
	helpLabel:DockMargin(10, 10, 10, 0)
	helpLabel:SizeToContents()

	-- Save button
	local saveButton = vgui.Create("DButton", frame)
	saveButton:SetText("Save Configuration")
	saveButton:Dock(TOP)
	saveButton:DockMargin(10, 20, 10, 0)
	saveButton:SizeToContents()
	saveButton:SetTall(30)
	saveButton.DoClick = function()
		-- Send the configuration to the server
		net.Start("Minigolf.HoleConfigStartSave")
		net.WriteEntity(entity)
		net.WriteString(holeNameEntry:GetValue())
		net.WriteString(courseEntry:GetValue())
		net.WriteInt(tonumber(orderEntry:GetValue()) or 1, 16)
		net.WriteInt(tonumber(parEntry:GetValue()) or 3, 8)
		net.WriteInt(tonumber(limitEntry:GetValue()) or 60, 16)
		net.WriteString(descEntry:GetValue())
		net.WriteInt(tonumber(maxStrokesEntry:GetValue()) or 12, 8)
		net.WriteInt(tonumber(maxPitchEntry:GetValue()) or 0, 8)
		net.WriteInt(tonumber(maxRetriesCompEntry:GetValue()) or 0, 8)
		net.WriteInt(tonumber(maxRetriesTimeEntry:GetValue()) or 0, 8)
		net.WriteInt(tonumber(maxRetriesStrokesEntry:GetValue()) or 0, 8)
		net.SendToServer()

		frame:Close()
	end

	frame:InvalidateChildren(true)
	frame:SizeToChildren(false, true)
end)
