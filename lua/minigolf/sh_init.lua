Minigolf = Minigolf or {}

Minigolf.Convars = {}
Minigolf.Convars.CommandPrefix = CreateConVar("minigolf_command_prefix", "+", {FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE}, "The prefix for all minigolf commands.")

Minigolf.CANCEL_BALL_FORCE = -1

-- Hole status enumerations (must be negative since positive is used to count strokes)
Minigolf.HOLE_NOT_PLAYED = -1
Minigolf.HOLE_DISQUALIFIED = -2
Minigolf.HOLE_STATUS_MINIMUM = -3

-- Text effect enumerations
Minigolf.TEXT_EFFECT_NORMAL = 0
Minigolf.TEXT_EFFECT_ATTENTION = 1
Minigolf.TEXT_EFFECT_DANGER = 2
Minigolf.TEXT_EFFECT_SPARKLE = 3
Minigolf.TEXT_EFFECT_CASH = 4

-- Sizing constants
Minigolf.PADDING = 10
Minigolf.HALF_PADDING = Minigolf.PADDING * .5
Minigolf.DOUBLE_PADDING = Minigolf.PADDING * 2

-- Colour constants
Minigolf.COLOR_DARK = Color(10, 10, 10)
Minigolf.COLOR_LIGHT = Color(255, 255, 255)

Minigolf.COLOR_PRIMARY = Color(91, 127, 0)
Minigolf.COLOR_PRIMARY_LIGHT = Color(143, 168, 79)
Minigolf.COLOR_SECONDARY = Color(143, 168, 79)
Minigolf.COLOR_SECONDARY_LIGHT = Color(118, 153, 31)

if(SERVER)then AddCSLuaFile("sh_util.lua") end
include("sh_util.lua")

-- Automatically include everything in these directories
Minigolf.IncludeDirectory(Minigolf.PathCombine("gamemodes/gm_minigolf/gamemode", "libraries/"))
Minigolf.IncludeDirectory(Minigolf.PathCombine("gamemodes/gm_minigolf/gamemode", "core/"))
Minigolf.IncludeDirectory(Minigolf.PathCombine("gamemodes/gm_minigolf/gamemode", "vgui/"))

if(SERVER)then
	AddCSLuaFile("minigolf/cl_init.lua")
	include("minigolf/sv_init.lua")

	AddCSLuaFile("sh_hooks.lua")
	include("sv_hooks.lua")
elseif(CLIENT)then
	include("cl_hooks.lua")
	include("minigolf/cl_init.lua")
end

include("sh_hooks.lua")
