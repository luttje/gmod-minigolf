include("shared.lua")

ENT.Icon = "entities/minigolf_hole_end_dynamic.png"

function ENT:Initialize()
	self.GripMaterial = Material("sprites/grip")
	self.GripMaterialHover = Material("sprites/grip_hover")

	self:SetMinigolfData("CollideRule", "only_balls")
end

function ENT:Draw()
	if (GetConVar("developer"):GetInt() >= 1) then
		self:DrawModel()
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

function ENT:BeingLookedAtByLocalPlayer()
	local ply = LocalPlayer()
	local eyeTrace = ply:GetEyeTrace()

	if (not IsValid(eyeTrace.Entity)) then return false end
	if (eyeTrace.Entity ~= self) then return false end
	if (eyeTrace.HitPos:Distance(ply:EyePos()) > 100) then return false end

	return true
end

function ENT:GetHoleName()
	return self:GetNWString("HoleName", "")
end

function ENT:GetUniqueHoleName()
	return self:GetCourse() .. self:GetHoleName()
end

function ENT:GetCourse()
	return self:GetNWString("CourseName", "")
end

function ENT:GetStartName()
	return self:GetNWString("StartName", "")
end

--[[
	Net Messages
--]]

net.Receive("Minigolf.HoleConfigEnd", function()
	local entity = net.ReadEntity()

	if (not IsValid(entity)) then
		return
	end

	local holeName = entity:GetHoleName()
	local course = entity:GetCourse()
	local startName = entity:GetStartName()

	-- Create the configuration window
	local frame = vgui.Create("DFrame")
	frame:SetTitle("Configure Minigolf End")
	frame:SetSize(400, 600)
	frame:Center()
	frame:MakePopup()

	local paddingLeft, paddingTop, paddingRight, paddingBottom = frame:GetDockPadding()
	frame:DockPadding(paddingLeft, paddingTop, paddingRight, paddingBottom + 10)

	local function CreateTextEntry(parent, labelText, value, isNumeric, isDisabled)
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

		if (isDisabled) then
			entry:SetEnabled(false)
		end

		return entry
	end

	-- Create a dropdown showing all minigolf_hole_start entities
	local startHoles = {}

	for _, startHole in pairs(ents.FindByClass("minigolf_hole_start")) do
		if (not startHole:GetIsCustom()) then
			continue
		end

		table.insert(startHoles, startHole)
	end

	if (#startHoles == 0) then
		local label = vgui.Create("DLabel", frame)
		label:SetText("No custom start holes found! Please create a Minigolf Hole Start first.")
		label:Dock(TOP)
		label:DockMargin(10, 10, 10, 0)
		label:SizeToContents()

		frame:InvalidateChildren(true)
		frame:SizeToChildren(false, true)
		return
	end

	table.sort(startHoles, function(a, b)
		if (a:GetCourse() == b:GetCourse()) then
			return a:GetHoleName() < b:GetHoleName()
		end

		return a:GetCourse() < b:GetCourse()
	end)

	local panel = vgui.Create("DSizeToContents", frame)
	panel:Dock(TOP)
	panel:DockMargin(10, 10, 10, 0)
	panel:SetSizeX(false)

	local label = vgui.Create("DLabel", panel)
	label:SetText("Start Hole:")
	label:Dock(LEFT)
	label:SizeToContents()

	local startHoleDropdown = vgui.Create("DComboBox", panel)
	startHoleDropdown:Dock(FILL)
	startHoleDropdown:DockMargin(10, 0, 0, 0)

	for _, startHole in pairs(startHoles) do
		local name = string.format("%s - %s", startHole:GetCourse(), startHole:GetHoleName())
		local index = startHoleDropdown:AddChoice(name, startHole)

		if (startHole:GetHoleName() == startName and startHole:GetCourse() == course) then
			startHoleDropdown:ChooseOptionID(index)
		end
	end

	-- Create form fields
	local courseEntry = CreateTextEntry(frame, "Course Name:", course, false, true)
	local startNameEntry = CreateTextEntry(frame, "Start Name:", startName, false, true)
	local holeNameEntry = CreateTextEntry(frame, "Hole Name:", holeName, false, true)

	startHoleDropdown.OnSelect = function(_, index, value, data)
		if (IsValid(data)) then
			courseEntry:SetValue(data:GetCourse())
			startNameEntry:SetValue(data:GetHoleName())
			holeNameEntry:SetValue(data:GetHoleName())
		else
			courseEntry:SetValue("")
			startNameEntry:SetValue("")
			holeNameEntry:SetValue("")
		end
	end

	-- Save button
	local saveButton = vgui.Create("DButton", frame)
	saveButton:SetText("Save Configuration")
	saveButton:Dock(TOP)
	saveButton:DockMargin(10, 20, 10, 0)
	saveButton:SizeToContents()
	saveButton:SetTall(30)
	saveButton.DoClick = function()
		-- Send the configuration to the server
		net.Start("Minigolf.HoleConfigEndSave")
		net.WriteEntity(entity)
		net.WriteString(courseEntry:GetValue())
		net.WriteString(startNameEntry:GetValue())
		net.WriteString(holeNameEntry:GetValue())
		net.SendToServer()

		frame:Close()
	end

	frame:InvalidateChildren(true)
	frame:SizeToChildren(false, true)
end)
