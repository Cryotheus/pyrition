--locals
local session_start_times = PYRITION.Players.Time.SessionStarts
local session_times = PYRITION.Players.Time.Sessions
local total_times = PYRITION.Players.Time.Total --their total play time on the server

--initial sync of session times accross maps
net.Receive("pyrition_players_time", function()
	
end)