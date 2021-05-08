local PANEL = {}

function PANEL:Init()
	self:SetTextColor(Color(255,255,255))
	self:SizeToContents()
end

function PANEL:Paint(w, h)
  draw.RoundedBoxEx(16, 0, 0, w, h, Color(143, 168, 79), true)
end

vgui.Register("MinigolfActionButton", PANEL, "DButton")