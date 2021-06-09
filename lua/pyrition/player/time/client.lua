--locals
local session_start_times = PYRITION.Player.Time.SessionStarts
local session_times = PYRITION.Player.Time.Sessions
local total_times = PYRITION.Player.Time.Total --their total play time on the server

--initial sync of session times accross maps
net.Receive("pyrition_player_time", function()
	
end)