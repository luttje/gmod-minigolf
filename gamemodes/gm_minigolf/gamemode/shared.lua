GM.Name = "Minigolf"
GM.Version = "Prototype"
GM.Author = "Lutt.online & Company"
GM.Email = ""
GM.IsMinigolf = true

-- Table that contains all Minigolf information
Minigolf = Minigolf or {}

-- Team restrictions
TEAM_NAME_LENGTH_MAX = 50
TEAM_NAME_LENGTH_MAX_MESSAGE = string.format("Your team name can only be %d characters long!", TEAM_NAME_LENGTH_MAX)
TEAM_NAME_LENGTH_MIN = 2
TEAM_NAME_LENGTH_MIN_MESSAGE = string.format("Your team name must be at least %d characters long!", TEAM_NAME_LENGTH_MIN)
TEAM_NAME_PROFANITY_MESSAGE = "Your team name can not contain any profanities! Profanity was: %s"

-- Hole status enumerations
HOLE_NOT_PLAYED = -1
HOLE_DISQUALIFIED = -2
HOLE_SKIPPED = -3 -- When a player joins a team late, this is assigned to them for the holes that have already been played

-- Text effect enumerations
TEXT_EFFECT_NORMAL = 0
TEXT_EFFECT_ATTENTION = 1
TEXT_EFFECT_DANGER = 2
TEXT_EFFECT_SPARKLE = 3
TEXT_EFFECT_CASH = 4

-- Sizing constants
PADDING = 10
HALF_PADDING = PADDING * .5
DOUBLE_PADDING = PADDING * 2

-- Colour constants
COLOR_DARK = Color(10, 10, 10)
COLOR_LIGHT = Color(255, 255, 255)

COLOR_PRIMARY = Color(91, 127, 0)
COLOR_PRIMARY_LIGHT = Color(143, 168, 79)
COLOR_SECONDARY = Color(143, 168, 79)
COLOR_SECONDARY_LIGHT = Color(118, 153, 31)

if(SERVER)then AddCSLuaFile("sh_util.lua") end
include("sh_util.lua")

-- Automatically include everything in these directories
Minigolf.IncludeDirectory(Minigolf.PathCombine("gamemodes/gm_minigolf/gamemode", "libraries/"))
Minigolf.IncludeDirectory(Minigolf.PathCombine("gamemodes/gm_minigolf/gamemode", "core/"))
Minigolf.IncludeDirectory(Minigolf.PathCombine("gamemodes/gm_minigolf/gamemode", "vgui/"))

if(SERVER)then
	AddCSLuaFile("cl_hooks.lua")
	AddCSLuaFile("cl_init.lua")
	AddCSLuaFile("sh_hooks.lua")
	AddCSLuaFile() -- this shared.lua file
	
	include("sv_hooks.lua")
elseif(CLIENT)then
	include("cl_hooks.lua")
end

include("sh_hooks.lua")

-- Create the no-team team
TEAM_MINIGOLF_SPECTATORS = TEAM_MINIGOLF_SPECTATORS or Minigolf.Teams.Update(nil, "Spectators", Color(193, 180, 180))
