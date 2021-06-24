util.AddNetworkString("pyrition_initialize")

--locals
local loading_players = {}
local load_time = 30
local respawn_delay = 0

--pyrition functions
function PYRITION:PyritionPlayerInitialized(ply, emulated) print(ply:Name() .. (map_transition and " fully loaded into the server after the map change." or " fully loaded into the server.")) end

--hooks
hook.Add("PlayerDisconnected", "pyrition", function(ply)
	loading_players[ply] = nil
	
	hook.Remove("PlayerDeathThink", "pyrition_special_" .. ply:EntIndex())
end)

hook.Add("PlayerInitialSpawn", "pyrition", function(ply) loading_players[ply] = ply:TimeConnected() end)

hook.Add("PlayerDeath", "pyrition", function(ply, inflictor, attacker)
	local id = "pyrition_special_" .. ply:EntIndex()
	
	hook.Add("PlayerDeathThink", id, function(ply)
		ply.NextSpawnTime = ply.DeathTime + respawn_delay
		
		hook.Remove("PlayerDeathThink", id)
	end)
end)

hook.Add("Think", "pyrition", function()
	for ply, time_spawned in pairs(loading_players) do
		if time_spawned and ply:TimeConnected() - time_spawned > load_time then
			MsgC(color_red, "A player (" .. tostring(ply) .. ") has exceeded " .. load_time .. " (took " .. ply:TimeConnected() - time_spawned .. ") seconds of spawn time and has yet to send the proper net message. Emulating a response.\n")
			
			loading_players[ply] = false
			
			hook.Call("PyritionPlayerInitialized", PYRITION, ply, true)
		end
	end
end)

--net
net.Receive("pyrition_initialize", function(length, ply)
	if loading_players[ply] == nil and false then --TODO: remove the <and false>
		if sv_allowcslua:GetBool() then return end
		
		MsgC(color_red, "\n!!!\nA player (", ply, ") tried to send a load net message but has yet to be spawned! It is possible that they are hacking.\n!!!\n\n")
	else
		if loading_players[ply] == false then
			MsgC(
				color_red, "A player (" .. tostring(ply) .. ") had a belated load net message, an emulated one has been made.\n",
				color_white, "The above message is not an error, but a sign that clients are taking too long to load your server's content.\n"
			)
		end
		
		loading_players[ply] = nil
		
		hook.Call("PyritionPlayerInitialized", PYRITION, ply, false)
	end
end)