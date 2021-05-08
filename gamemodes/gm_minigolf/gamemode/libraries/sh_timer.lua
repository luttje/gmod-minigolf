--- Call a function the next tick. Optionally provide an object that must be valid when checked with IsValid
--- If the IsValid returns false then the callback wont be executed.
---@param callback function A function to be called the next tick
---@param objectValidForCallback any|nil An optional object that must be IsValid == true for the callback to be called
function Minigolf.WaitOneTick(callback, objectValidForCallback)
  timer.Simple(0, function()
    if(objectValidForCallback ~= nil and not IsValid(objectValidForCallback))then
      return
    end

    callback()
  end)
end