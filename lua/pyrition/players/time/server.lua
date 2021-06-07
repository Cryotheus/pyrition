--locals
local prior_session_count
local prior_session_expire_time = 15
local prior_sessions
local session_start_times = PYRITION.Players.Time.SessionStarts
local session_times = PYRITION.Players.Time.Sessions
local total_times = PYRITION.Players.Time.Total

--pyrition functions
function PYRITION:PyritionPlayerTimeGetSession(ply)
	return ply:TimeConnected() - session_start_times[ply] + session_times[ply]
end

function PYRITION:PyritionPlayerTimeGetSessionPrior(ply) return prior_sessions[ply:SteamID()] end

--hooks
hook.Add("InitPostEntity", "pyrition_player_time", function()
	local player_sessions_json = file.Read("pyrition/players/sessions.json", "DATA")
	
	if player_sessions_json then
		prior_sessions = util.JSONToTable(player_sessions_json)
		
		if prior_sessions then
			prior_session_count = table.Count(prior_sessions)
			
			if prior_session_count > 0 then print("Successfully fetched " .. prior_session_count .. " session times from the last map. This data will expire in " .. prior_session_expire_time .. " minutes.")
			else
				prior_session_count = nil
				prior_sessions = nil
				
				print("No entries in the prior session times JSON.")
			end
		else print("Failed to read the prior session times JSON.") end
	else print("No prior sessions times JSON.") end
end)

hook.Add("PlayerDisconnected", "pyrition_player_time", function(ply)
	session_start_times[ply] = nil
	session_times[ply] = nil
end)

hook.Add("PlayerInitialSpawn", "pyrition_player_time", function(ply, map_transition)
	--instead of initial spawn, we want a hook that gets called when the player first moves
	session_start_times[ply] = ply:TimeConnected()
	
	if (map_transition or prior_sessions_always) and prior_sessions then
		prior_session_count = prior_session_count - 1
		session_times[ply] = hook.Call("PyritionPlayerTimeGetSessionPrior", PYRITION, ply)
		
		if prior_session_count <= 0 or prior_session_expire_time then
			prior_session_count = nil
			prior_sessions = nil
		end
	else session_times[ply] = 0 end
end)

hook.Add("PyritionPlayerStorageLoadMeta", "pyrition_player_time", function(ply, data_loaded)
	local time_data = data_loaded.time
	local visited = time_data.visited * 60
	
	total_times[ply] = time_data.total * 60
	
	print(ply, "Last visited " .. visited)
end)

hook.Add("PyritionPlayerStorageSaveMeta", "pyrition_player_time", function(path, ply)
	PLAYER_STORAGE_META.time = {
		total = math.floor(total_times[ply] / 60),
		visited = math.floor(os.time() / 60)
	}
end)

hook.Add("ShutDown", "pyrition_player_time", function(...)
	print("shutdown args:", ...)
	
	local time_table = {}
	
	for index, ply in ipairs(player.GetHumans()) do
		time_table[ply:SteamID()] = hook.Call("PyritionPlayerTimeGetSession", PYRITION, ply)
	end
end)