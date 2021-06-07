local session_start_times = {} --when they started playing in this map
local session_times = {} --their previous session time to add
local total_times = {} --their total play time on the server

--globals
PYRITION.Players.Time.Sessions = session_times
PYRITION.Players.Time.SessionStarts = session_start_times
PYRITION.Players.Time.Total = total_times