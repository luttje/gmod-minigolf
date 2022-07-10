local open = false

Minigolf.Chatbox = Minigolf.Chatbox or {}

function Minigolf.Chatbox.GetOpen()
  return open
end

function Minigolf.Chatbox.SetOpen(isOpen)
  if(open and not isOpen)then
    Minigolf.Chatbox._LastClosed = CurTime()
  end
  
  open = isOpen
end

--- Returns wether the chatbox was just closed
---@param justInSeconds number How many seconds ago is "just"? Defaults to 1 second
function Minigolf.Chatbox.WasJustClosed(justInSeconds)
  if(not Minigolf.Chatbox._LastClosed)then
    return false
  end

  justInSeconds = justInSeconds or 1
  
  return Minigolf.Chatbox._LastClosed + justInSeconds > CurTime()
end