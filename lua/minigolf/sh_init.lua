Minigolf = Minigolf or {}

local validHoleModes = {
	turn_based = true,
	simultaneous = true,
	simultaneous_collide = true,
}

local validHoleModesString = table.concat(table.GetKeys(validHoleModes), ", ")

Minigolf.Convars = {}
Minigolf.Convars.CommandPrefix = CreateConVar("minigolf_command_prefix", "+",
	{ FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE }, "The prefix for all minigolf commands.")
Minigolf.Convars.HoleMode = CreateConVar("minigolf_hole_mode", "turn_based",
	{ FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE },
	"The way players play at a hole. Options: " .. validHoleModesString)
Minigolf.Convars.PlayerConfigPowerMode = CreateConVar("minigolf_allow_change_power_mode", "1",
	{ FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE }, "Can a player change their own power mode?")
Minigolf.Convars.DefaultAutoPowerMode = CreateConVar("minigolf_auto_power_mode", "0",
	{ FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE },
	"Should the powerbar bounce back and forth until the player releases a key?")
Minigolf.Convars.AutoPowerVelocity = CreateConVar("minigolf_auto_power_velocity", "50",
	{ FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE },
	"How fast should the powerbar bounce back and forth? (lower number is slower)")
Minigolf.Convars.TimeLimitMultiplierGlobal = CreateConVar("minigolf_time_limit_multiplier_global", "1",
	{ FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE },
	"Global time limit multiplier for all players.")

-- Validate Convar values
cvars.AddChangeCallback(Minigolf.Convars.HoleMode:GetName(), function(convarName, oldValue, newValue)
	if (not validHoleModes[newValue]) then
		Minigolf.Convars.HoleMode:SetString(oldValue)

		if (SERVER) then
			print(
				"[Minigolf] Invalid hole mode '" ..
				newValue ..
				"' set in convar '" ..
				convarName .. "'. Reverting to '" .. oldValue .. "'. Valid options are: " .. validHoleModesString
			)
		end
	end
end, "Minigolf.HoleMode.Validate")

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
