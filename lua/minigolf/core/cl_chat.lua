hook.Add("StartChat", "Minigolf.HasStartedTyping", function( isTeamChat )
  Minigolf.Chatbox.SetOpen(true)
end)

hook.Add("FinishChat", "Minigolf.HasFinishedTyping", function( isTeamChat )
  Minigolf.Chatbox.SetOpen(false)
end)