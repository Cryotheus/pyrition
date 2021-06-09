local prefix_functions = {
	--player you're looking at
	["@"] = function(needle, supplicant)
		--more!
		return false
	end,
	
	--user id
	["#"] = function(...) return hook.Call("PyritionPlayerFindByUserID", PYRITION, ...) end,
	
	--steam id
	["$"] = function(...) return hook.Call("PyritionPlayerFindBySteamID", PYRITION, ...) end,
	
	--everyone in your user group and above
	["%"] = function(needle, supplicant) return false end,
	
	--yourself, everyone in your user group, or everyone in a user group
	["^"] = function(needle, supplicant)
		if #needle > 0 then
			--if they typed ^^ we want to get everyone in their group
			--find players of the specified user group
			local first_character = string.Left(needle, 1)
			
			if first_character == "^" then
				if IsValid(supplicant) then return hook.Call("PyritionPlayerFindByUserGroup", PYRITION, supplicant:GetUserGroup(), supplicant)
				else return false end
			end
			
			return hook.Call("PyritionPlayerFindByUserGroup", PYRITION, needle, supplicant)
		else
			local ply = ply or LocalPlayer and LocalPlayer() or false
			
			if ply then return {ply}
			else return false end
		end
	end,
	
	--everyone
	["*"] = function(needle, supplicant) return player.GetAll() end
}

function PYRITION:PyritionPlayerFind(needle, supplicant, ...)
	local first_character = string.Left(needle, 1)
	local invert = false
	local players
	
	if first_character == "!" then
		first_character = string.sub(needle, 2, 2)
		invert = true
		needle = string.sub(needle, 3)
	else first_character = string.sub(needle, 1, 1) end
	
	local prefix_function = prefix_functions[first_character]
	
	if prefix_function then players = prefix_function(string.sub(needle, 2), supplicant, ...)
	else --find by name
		local all_players = player.GetAll()
		needle = string.lower(needle)
		local player_count = #all_players
		players = {}
		
		for index, ply in ipairs(all_players) do
			local name = string.lower(ply:Name())
			
			if string.StartWith(name, needle) then table.insert(players, 1, ply) print(name, "started with", needle)
			elseif string.find(name, needle, 1, true) then table.insert(players, ply) print(name, "contained", needle) end
		end
		
		if table.IsEmpty(players) then players = false end
	end
	
	if invert then
		if players then
			local players_map = {}
			
			for index, ply in ipairs(players) do players_map[ply] = index end
			
			players = {}
			
			for index, ply in ipairs(player.GetAll()) do if not players_map[ply] then table.insert(players, ply) end end
		else players = player.GetAll() end
	end
	
	return players
end

function PYRITION:PyritionPlayerFindByUserGroup(user_group, supplicant)
	local players = {}
	
	for index, ply in ipairs(player.GetAll()) do if ply:IsUserGroup(user_group) then table.insert(players, ply) end end
	
	if table.IsEmpty(players) then return false end
	
	return players
end

function PYRITION:PyritionPlayerFindBySteamID(needle, supplicant)
	local all_players = player.GetAll()
	local players = false
	
	if string.StartWith(needle, "STEAM_0:") then --STEAM_0 ID
		--more?
		for index, ply in ipairs(all_players) do if ply:SteamID() == needle then return {ply} end end
	elseif tonumber(needle) then --steam ID 64
		--more?
		for index, ply in ipairs(all_players) do if ply:SteamID64() == needle then return {ply} end end
	else --special IDs
		local players = {}
		
		for index, ply in ipairs(all_players) do
			local steam_id = ply:SteamID()
			
			if string.sub(steam_id, 9) == needle or steam_id == needle then
				print("needle: " .. needle .. ", steamid: " .. steam_id .. ", sub: " .. string.sub(steam_id, 9))
				
				table.insert(players, ply)
			end
		end
		
		if table.IsEmpty(players) then return false
		else return players end
	end
	
	return players
end

function PYRITION:PyritionPlayerFindByUserID(user_id, supplicant)
	user_id = tonumber(user_id)
	
	if user_id then
		local ply = Player(user_id)
		
		if IsValid(ply) then return {ply} end
	end
	
	return false
end