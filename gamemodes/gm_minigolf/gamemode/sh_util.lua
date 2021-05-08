local PATH_SEPERATORS = {"/", "\\"}
local STACK_CALLING_FUNCTION = 2

--- Returns the gamemode object
---@return GM
function gm()
  return GM or GAMEMODE or gmod.GetGamemode() or gamemode.Get()
end

function Minigolf.PathCombine(...)
  local path = ""
  local args = {...}

  for _,pathPiece in pairs(args) do
    path = path .. pathPiece

    if(not table.HasValue(PATH_SEPERATORS, pathPiece:sub(-1)))then
      path = path .. PATH_SEPERATORS[1]
    end
  end

  return path:sub(1, -2)
end

---@param directory string Which directory should be loaded
---@param preLoad function|nil Optional function to be called right before loading the file
---@param postLoad function|nil Optional function to be called right after loading the file
function Minigolf.IncludeDirectory(directory, preLoad, postLoad)
  local gamemodeDirectory = "gamemodes/"

  if(directory:StartWith(gamemodeDirectory))then
    directory = directory:sub(gamemodeDirectory:len() + 1)
  end
  
  local files, directories = file.Find(directory .. "/*", "LUA")

  for _, fileName in pairs(files) do
    local relativePath = Minigolf.PathCombine(directory, fileName)

    if(fileName:StartWith("sv_"))then
      if(SERVER)then
        if(preLoad)then
          preLoad(fileName)
        end

        include(relativePath)

        if(postLoad)then
          postLoad(fileName)
        end
      end
    elseif(fileName:StartWith("cl_"))then
      if(SERVER)then
        AddCSLuaFile(relativePath)
      else
        if(preLoad)then
          preLoad(fileName)
        end

        include(relativePath)

        if(postLoad)then
          postLoad(fileName)
        end
      end
    elseif(fileName:StartWith("sh_"))then
      if(SERVER)then
        AddCSLuaFile(relativePath)
      end

      if(preLoad)then
        preLoad(fileName)
      end
      
      include(relativePath)

      if(postLoad)then
        postLoad(fileName)
      end
    end
  end
end