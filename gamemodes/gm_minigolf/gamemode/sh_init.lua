GM.Name = "Minigolf"
GM.Version = "Prototype"
GM.Author = "Luttje & Company"
GM.Email = ""
GM.IsMinigolf = true

-- Team restrictions
Minigolf.NO_TEAM_PLAYING = -1
Minigolf.TEAM_NAME_LENGTH_MAX = 50
Minigolf.TEAM_NAME_LENGTH_MAX_MESSAGE = string.format("Your team name can only be %d characters long!", Minigolf.TEAM_NAME_LENGTH_MAX)
Minigolf.TEAM_NAME_LENGTH_MIN = 2
Minigolf.TEAM_NAME_LENGTH_MIN_MESSAGE = string.format("Your team name must be at least %d characters long!", Minigolf.TEAM_NAME_LENGTH_MIN)
Minigolf.TEAM_NAME_PROFANITY_MESSAGE = "Your team name can not contain any profanities! Profanity was: %s"

-- When a player joins a team late, this stroke count is assigned to them for the holes that have already been played
Minigolf.HOLE_SKIPPED = Minigolf.HOLE_STATUS_MINIMUM - 1

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
