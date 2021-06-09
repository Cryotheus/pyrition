--locals
local pretty_print = true
local prior_session_count
local prior_session_expire_time = 15
local prior_sessions --stores prior sessions of players who have not yet connected after a map change (and soon, crashes too)
local session_start_times = PYRITION.Player.Time.SessionStarts
local session_times = PYRITION.Player.Time.Sessions --actually stores how long the previous sension has been going
local total_times = PYRITION.Player.Time.Total

PYRITION.Player.StorageTailored.Time = "time.json"

--pyrition functions
function PYRITION:PyritionPlayerStorageCreatedTailoredTime(ply)
	total_times[ply] = 0
	local unix_time = os.time()
	
	return {
		first = unix_time,
		longest = 0,
		total = 0,
		visit = unix_time
	}
end

function PYRITION:PyritionPlayerStorageLoadTailoredTime(ply, tailored_data, path) total_times[ply] = tailored_data.total or 0 end

function PYRITION:PyritionPlayerStorageSaveTailoredTime(ply, tailored_data, path)
	tailored_data.longest = math.max(tailored_data.longest, math.floor(hook.Call("PyritionPlayerTimeGetSession", self, ply) / 60))
	tailored_data.total = hook.Call("PyritionPlayerTimeGetTotalSessions", self, ply)
	tailored_data.visit = os.time()
end

function PYRITION:PyritionPlayerTimeGetSession(ply) return ply:TimeConnected() - session_start_times[ply] + session_times[ply] end

--this is in minutes, not seconds!
function PYRITION:PyritionPlayerTimeGetTotalSessions(ply) 
	local prior_time = hook.Call("PyritionPlayerTimeGetSessionPrior", self, ply)
	local session_time = hook.Call("PyritionPlayerTimeGetSession", self, ply)
	
	--don't save prior session time, otherwise players can repeatedly change maps to rack up total play time
	--also save it as minutes
	return total_times[ply] + math.floor(session_time / 60) - prior_time
end

--this is in minutes, not seconds!
function PYRITION:PyritionPlayerTimeGetSessionPrior(ply) return session_times[ply] end

--hooks
hook.Add("InitPostEntity", "pyrition_player_time", function()
	local player_sessions_json = file.Read("pyrition/players/sessions.json", "DATA")
	
	if player_sessions_json then
		prior_sessions = util.JSONToTable(player_sessions_json)
		
		if prior_sessions then
			prior_sessions.shutdown = nil --not fully implemented, intended for detecting when the server had crashed to be more forgiving on restoring session times
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
	--reset them AFTER we use them
	timer.Simple(0, function()
		session_start_times[ply] = nil
		session_times[ply] = nil
		total_times[ply] = nil
	end)
end)

hook.Add("PyritionPlayerInitialized", "pyrition_player_time", function(ply, map_transition)
	--instead of initial sync, we want a hook that gets called when the player first moves\
	if ply:IsBot() then
		session_start_times[ply] = 0
		session_times[ply] = 0
		
		return
	end
	
	local player_storage = PYRITION.Player.Storage[ply]
	local player_storage_meta = player_storage.meta
	session_start_times[ply] = ply:TimeConnected()
	
	if (map_transition or prior_sessions_always) and prior_sessions then
		local steam_id = ply:SteamID()
		
		prior_session_count = prior_session_count - 1
		session_times[ply] = prior_sessions[steam_id]
		
		if prior_session_count <= 0 or CurTime() / 60 > prior_session_expire_time then
			if prior_session_count > 0 then print("Prior session times expired; reconnecting players will not have their session times resumed.")
			else print("All prior session times resumed.") end
			
			prior_session_count = nil
			prior_sessions = nil
		else prior_sessions[steam_id] = nil end
	else session_times[ply] = 0 end
	
	local name = ply:Nick()
	local old_name = player_storage_meta.name
	local unix_time = os.time()
	
	if old_name then
		if old_name ~= name then PrintMessage(HUD_PRINTTALK, name .. (", formerly know as " .. old_name .. ", has loaded in. (Last visited " .. string.NiceTime(unix_time - player_storage.time.visit) .. " ago)"))
		else PrintMessage(HUD_PRINTTALK, name .. (" has loaded in. (Last visited " .. string.NiceTime(unix_time - player_storage.time.visit) .. " ago)")) end
	else PrintMessage(HUD_PRINTTALK, name .. (" has loaded in for the first time.")) end
	
	player_storage.time.visit = unix_time
end)

hook.Add("ShutDown", "pyrition_player_time", function()
	local time_table = {shutdown = true}
	
	for index, ply in ipairs(player.GetHumans()) do time_table[ply:SteamID()] = hook.Call("PyritionPlayerTimeGetSession", PYRITION, ply) / 60 end
	if table.IsEmpty(time_table) then return end
	
	print("\nSaving player session times...")
	file.CreateDir("pyrition/players")
	file.Write("pyrition/players/sessions.json", util.TableToJSON(time_table, pretty_print))
	print("Saved session times!\n")
end)