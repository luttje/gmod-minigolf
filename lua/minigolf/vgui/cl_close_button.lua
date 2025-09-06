---@class MinigolfCloseButton : DButton
local PANEL = {}

function PANEL:Init()
	self:SetText("x")
	self:SetTextColor(Color(255,255,255))
	self:SizeToContents()
	self:SetSize(24, 24)
end

function PANEL:Paint(w, h)
  draw.RoundedBoxEx(16, 0, 0, w, h, Color(255,0,0,255), nil, true)
end

vgui.Register("MinigolfCloseButton", PANEL, "DButton")