Minigolf = Minigolf or {}

Minigolf.Convars = {}
Minigolf.Convars.CommandPrefix = CreateConVar("minigolf_command_prefix", "+",
	{ FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE }, "The prefix for all minigolf commands.")
Minigolf.Convars.PlayerConfigPowerMode = CreateConVar("minigolf_allow_change_power_mode", "1",
	{ FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE }, "Can a player change their own power mode?")
Minigolf.Convars.DefaultAutoPowerMode = CreateConVar("minigolf_auto_power_mode", "0",
	{ FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE },
	"Should the powerbar bounce back and forth until the player releases a key?")
Minigolf.Convars.AutoPowerVelocity = CreateConVar("minigolf_auto_power_velocity", "50",
	{ FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE },
	"How fast should the powerbar bounce back and forth? (lower number is slower)")

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

-- Retry rule enumerations
Minigolf.RETRY_RULE_AFTER_COMPLETING = 1
Minigolf.RETRY_RULE_AFTER_TIME_LIMIT = 2
Minigolf.RETRY_RULE_AFTER_MAX_STROKES = 3

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

if (SERVER) then AddCSLuaFile("sh_util.lua") end
include("sh_util.lua")

-- Automatically include everything in these directories
Minigolf.IncludeDirectory(Minigolf.PathCombine("lua/minigolf", "libraries/"), "lua/")
Minigolf.IncludeDirectory(Minigolf.PathCombine("lua/minigolf", "core/"), "lua/")
Minigolf.IncludeDirectory(Minigolf.PathCombine("lua/minigolf", "vgui/"), "lua/")

Minigolf.Items.IncludeDirectory(Minigolf.PathCombine("lua/minigolf", "items/"), "lua/")

if (SERVER) then
	AddCSLuaFile("cl_init.lua")
	include("sv_init.lua")

	AddCSLuaFile("sh_hooks.lua")
	include("sv_hooks.lua")
elseif (CLIENT) then
	include("cl_init.lua")
end

include("sh_hooks.lua")
