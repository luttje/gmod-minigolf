# Code Conventions

In order to keep the code readable this document specifies the conventions this code tries to adhere to. **Disclaimer:** You might catch code breaking these conventions, or find some conventions too tedious. When that is the case feel free to open an issue with your feedback.

# Naming

* Global variables shouldn't exist, but if they do they are `UpperCamelCase` a.k.a. `PascalCase`
* Functions and "properties" within a variable are also `UpperCamelCase`
* Local variables and function argument variables are always `lowerCamelCase`
* Local functions are also `lowerCamelCase`
* Configuration constants in code are always `SCREAMING_SNAKE_CASE`, but where possible use a convar instead.
* Do not abbreviate unless that the abbreviation is common in programming. For example: `config` instead of `configuration` is fine, but `ply` instead of `player` is not.
* If you need to use the player library just define `local _player = player` at the top of the file.


# Syntax

* Do not use GLua specific syntax like `/* C-like comments */`, `!`, `&&` and `||`, but use the regular Lua counterparts instead (respectively: `--[[ multiline comment ]]`, `not`, `and`, and `or`)
* Do not end instructions with a semi-colon (;)

```lua
-- Comments clarify code and be used sparsely, it is preferable that clear variable and function names are used instead

-- Constants are namespaced inside the Minigolf global and in SCREAMING_SNAKE_CASE, where possible use ConVars instead
Minigolf.CONSTANT_CONFIG_VARIABLE = 999

-- All variables are written in full and not abreviated unless that is already common outside of Garry's Mod (such as config instead of configuration)
local lastHoleOfPlayer = NULL
local configChangedAt = CurTime()

-- Functions are never global or are always in a library (see section below on libraries directory)
local function getPlayerScore(player)
  -- etc...
end

-- Libraries are namespaced inside the global Minigolf variable
Minigolf.LibraryName = {}

function Minigolf.LibraryName.MyFunctionName(player, myParam2)
  local playerScore = getPlayerScore(player)

  -- If-statements do not contain spaces after if and before then, nor within the parentheses:
  if(playerScore > 10)then
    -- etc...
  -- If an if-statement is long use parentheses and line breaks for clarification
  elseif(playerScore < 5
    (and playerScore ~= 6
      or playerScore == 2))then
      -- etc...
  end
end

```


# Structure

This section attempts to inform you where certain code should be placed

## Directory: `gamemode/core`

Only code that are critical for the functioning of the gamemode.

As a rule of thumb: code in the core is generally not recycleable, but specific to a certain cause.

## Directory: `gamemode/libraries`

All functions that are useful for more than one context should be placed in this folder. Each file contains a library: a collection of functions which manipulate the same object, or otherwise involve the same subject.

These files generally start with:
```lua
Minigolf.LibraryName = {}

function Minigolf.LibraryName.MyFunctionName(player, myParam2)
  -- etc...
end
```