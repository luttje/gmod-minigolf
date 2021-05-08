CATEGORY.Name = 'Ball Trails'
CATEGORY.Icon = 'rainbow'
CATEGORY.Watermark = Guildhall.GamemodeSpecific.Minigolf

function CATEGORY:CanPlayerEquip(item, ply)
	return engine.ActiveGamemode() == "gm_minigolf", "This item can only be equiped in the MiniGolf gamemode."
end
