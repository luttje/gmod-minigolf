hook.Add("PlayerSay", "Minigolf.ProcessCommands", function(player, text)
  text = string.Trim(text)

  if(string.sub(text, 1, 1) == "/")then
    local firstSpace = string.find(text, " ", 1, true)
    local command = string.Trim(string.sub(text, 2, firstSpace))
    local callback = Minigolf.Commands.GetCallback(command)

    if(not callback)then
      player:ChatPrint("The command '".. command .."' does not exist!")
      return ""
    end

    local arguments = {}

    if(firstSpace)then
      local argumentsStart = string.Trim(string.sub(text, firstSpace))
      
      arguments = string.Explode(" ", argumentsStart)
    end

    callback(player, arguments)
    
    return ""
  end
end)