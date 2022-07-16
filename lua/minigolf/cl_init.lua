Minigolf.Menus = {}
Minigolf.Convars.ShowHints = CreateClientConVar("minigolf_show_hints", "1", true, false, "Whether to show hints on screen in Minigolf")

-- Fonts
surface.CreateFont("MinigolfMain", {
	font = "Sansation",
	size = 16,
	weight = 500,
})
surface.CreateFont("MinigolfMainBold", {
	font = "Sansation",
	size = 16,
	weight = 800,
})
surface.CreateFont("MinigolfMainSmall", {
	font = "Sansation",
	size = 24,
	weight = 800,
})
surface.CreateFont("MinigolfMainMedium", {
	font = "Sansation",
	size = 48,
	weight = 800,
})
surface.CreateFont("MinigolfMainLarge", {
	font = "Sansation",
	size = 54,
	weight = 800,
})
surface.CreateFont("MinigolfHuge", {
	font = "Sansation",
	size = 72,
	weight = 700,
})
surface.CreateFont("MinigolfTimeMain", {
	font = "Sansation",
	size = 32,
	weight = 700,
})
surface.CreateFont("MinigolfCardMain", {
	font = "Sansation",
	size = 22,
	weight = 500,
})
surface.CreateFont("MinigolfCardSub", {
	font = "Sansation",
	size = 16,
	weight = 700,
})
surface.CreateFont("MinigolfCardItalic", {
	font = "Sansation",
	size = 16,
	weight = 500,
	italic = true
})
surface.CreateFont("MinigolfIcons", {
	font = "Golf Icons",
	size = 64,
	weight = 500,
})

-- Palette: https://flatuicolors.com/palette/nl
Minigolf.Colors.Set("Background", Color(255, 255, 255)) -- White background
Minigolf.Colors.Set("Foreground", Color(27, 20, 100)) -- Purple for buttons and other controls
Minigolf.Colors.Set("Text", Color(0, 0, 0)) -- Black for most fonts
Minigolf.Colors.Set("ButtonText", Color(255, 255, 255)) -- Font colour on buttons
Minigolf.Colors.Set("Negative", Color(234, 32, 39)) -- Colour for negative messages/buttons
Minigolf.Colors.Set("Information", Color(6, 82, 221)) -- Colour for information messages/buttons
Minigolf.Colors.Set("Positive", Color(0, 148, 50)) -- Colour for positive messages/buttons
Minigolf.Colors.Set("ChatPrint", Color(247, 159, 31)) -- Orange-ish for chat messages by Game Avail
