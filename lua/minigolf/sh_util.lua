local PATH_SEPERATORS = {"/", "\\"}
local STACK_CALLING_FUNCTION = 2

--- Returns the gamemode object
---@return GM
function Minigolf.GM()
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
---@param baseFolder string|nil Optional basefolder instead of gamemodes/ (e.g: lua/)
---@param recurse boolean|nil Should subdirectories be loaded?
---@param preLoad function|nil Optional function to be called right before loading the file
---@param postLoad function|nil Optional function to be called right after loading the file
---@param loadHandler function|nil Optional function to be used for loading the file
function Minigolf.IncludeDirectory(directory, baseFolder, recurse, preLoad, postLoad, loadHandler)
  if(baseFolder == nil)then
    baseFolder = "gamemodes/"
  end

  if(directory:StartWith(baseFolder))then
    directory = directory:sub(baseFolder:len() + 1)
  end
  
  if(not loadHandler)then
    loadHandler = Minigolf.IncludePrefixed
  end

  local files, directories = file.Find(directory .. "/*", "LUA")

  if(recurse)then
    for _,subDirectory in pairs(directories)do
      local subDirectoryPath = Minigolf.PathCombine(directory, subDirectory)
      
      Minigolf.CurrentIncludeDirectory = subDirectoryPath
      Minigolf.IncludeDirectory(subDirectoryPath, baseFolder, recurse, preLoad, postLoad, loadHandler)
      Minigolf.CurrentIncludeDirectory = nil
    end
  end

  for _, fileName in pairs(files) do
    local relativePath = Minigolf.PathCombine(directory, fileName)

    loadHandler(relativePath, fileName, preLoad, postLoad)
  end
end

function Minigolf.IncludePrefixed(relativePath, fileName, preLoad, postLoad)
  if(fileName:StartWith("sv_"))then
    if(SERVER)then
      if(preLoad)then
        preLoad(fileName, relativePath)
      end

      include(relativePath)

      if(postLoad)then
        postLoad(fileName, relativePath)
      end
    end
  elseif(fileName:StartWith("cl_"))then
    if(SERVER)then
      AddCSLuaFile(relativePath)
    else
      if(preLoad)then
        preLoad(fileName, relativePath)
      end

      include(relativePath)

      if(postLoad)then
        postLoad(fileName, relativePath)
      end
    end
  elseif(fileName:StartWith("sh_"))then
    if(SERVER)then
      AddCSLuaFile(relativePath)
    end

    if(preLoad)then
      preLoad(fileName, relativePath)
    end
    
    include(relativePath)

    if(postLoad)then
      postLoad(fileName, relativePath)
    end
  end
end

function Minigolf.IncludeShared(relativePath, fileName, preLoad, postLoad)
  if(SERVER)then
    AddCSLuaFile(relativePath)
  end

  if(preLoad)then
    preLoad(fileName, relativePath)
  end

  include(relativePath)

  if(postLoad)then
    postLoad(fileName, relativePath)
  end
end