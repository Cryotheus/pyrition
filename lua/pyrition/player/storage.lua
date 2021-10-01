--locals
local absolute_path = "pyrition/"
local current_meta_data_version = 2
local player_storages = PYRITION.Player.Storage
local pretty_print = true
local user_path = absolute_path .. "players/"

local meta_data_updates = {
	[2] = function(ply, player_storage, meta_data, path, meta_version) meta_data.group = "guest" end
}

--pyrition functions 
function PYRITION:PyritionPlayerStorageCreateMeta(ply, player_storage, path)
	return {
		group = "guest",
		name = ply:Name(), --need to update this when they change their name
		steam_id_64 = "S" .. ply:SteamID64(),
		version = current_meta_version --in case we change how things are saved, we know how we're going to have to change this player's data
	}
end

function PYRITION:PyritionPlayerStorageGetPath(steam_id)
	if string.StartWith(steam_id, "STEAM_0:") then steam_id = string.sub(steam_id, 9) end
	
	--remove the : between the binary number and the decimal number
	--split it into a table of digits
	--concatenate the table with a / between each digit
	return user_path .. table.concat(string.Split(string.Left(steam_id, 1) .. string.sub(steam_id, 3), ""), "/")
end

function PYRITION:PyritionPlayerStorageLoad(ply)
	if ply:IsBot() then return end
	
	local player_storage = player_storages[ply] or {}
	local steam_id = ply:SteamID()
	local storage_path = hook.Call("PyritionPlayerStorageGetPath", self, steam_id)
	
	--maintain the references!
	table.Empty(player_storage)
	
	--call load hooks
	hook.Call("PyritionPlayerStorageLoadMeta", self, ply, player_storage, storage_path .. "/meta.json")
	hook.Call("PyritionPlayerStorageLoadTailored", self, ply, player_storage, storage_path .. "/")
	
	player_storages[ply] = player_storage
	
	return player_storage
end

function PYRITION:PyritionPlayerStorageLoaded(ply, player_storage) end

function PYRITION:PyritionPlayerStorageLoadMeta(ply, player_storage, path)
	local json_read = file.Read(path, "DATA")
	local meta_data
	
	if json_read then meta_data = util.JSONToTable(json_read) or false end
	if not meta_data then meta_data = hook.Call("PyritionPlayerStorageCreateMeta", self, ply, player_storage, path) end
	
	local version = meta_data.version or 0
	
	if version ~= current_meta_data_version then hook.Call("PyritionPlayerStorageUpdateMeta", self, ply, player_storage, meta_data, path, version) end
	
	player_storage.meta = meta_data
	
	return meta_data
end

function PYRITION:PyritionPlayerStorageLoadTailored(ply, player_storage, path)
	for key, file_full_name in pairs(self.Player.StorageTailored) do
		local file_name = string.StripExtension(file_full_name)
		local file_path = path .. file_full_name
		local json_read = file.Read(file_path, "DATA")
		local tailored_data
		
		if json_read then tailored_data = util.JSONToTable(json_read) end
		if tailored_data then hook.Call("PyritionPlayerStorageLoadTailored" .. key, self, ply, tailored_data, file_path)
		else tailored_data = hook.Call("PyritionPlayerStorageCreatedTailored" .. key, self, ply) or {} end
		
		player_storage[file_name] = tailored_data
	end
end

function PYRITION:PyritionPlayerStorageSave(ply)
	--rule with saving: DO NOT use any digits from 0-9 for folders, those are other players folders
	--you may do this iff you override the PyritionPlayerStorageGetPath function
	if ply:IsBot() then return end
	
	local player_storage = player_storages[ply]
	local steam_id = ply:SteamID()
	local storage_path = hook.Call("PyritionPlayerStorageGetPath", self, steam_id)
	
	--almost forgot
	file.CreateDir(storage_path)
	
	--call save hooks
	hook.Call("PyritionPlayerStorageSaveMeta", self, ply, player_storage.meta, storage_path .. "/meta.json")
	hook.Call("PyritionPlayerStorageSaveTailored", self, ply, player_storage, storage_path .. "/")
end

function PYRITION:PyritionPlayerStorageSaveMeta(ply, meta_data, path)
	meta_data.group = hook.Call("PyritionGroupPlayerGet", self, ply)
	meta_data.name = ply:Name()
	
	local json_data = util.TableToJSON(meta_data, pretty_print)
	
	if json_data then file.Write(path, json_data)
	else ErrorNoHaltWithStack("Failed to save player meta! ", ply, " :: [" .. path .. "] :: ", meta_data) end
end

function PYRITION:PyritionPlayerStorageSaveTailored(ply, player_storage, path)
	for key, file_full_name in pairs(self.Player.StorageTailored) do
		local file_name = string.StripExtension(file_full_name)
		local file_path = path .. file_full_name
		local tailored_data = player_storage[file_name]
		
		hook.Call("PyritionPlayerStorageSaveTailored" .. key, self, ply, tailored_data, file_path)
		
		local json_data = util.TableToJSON(tailored_data, pretty_print)
		
		if json_data then file.Write(file_path, json_data)
		else ErrorNoHaltWithStack("Failed to save tailored player data! ", ply, " :: [" .. file_path .. "] :: ", tailored_data) end
	end
end

function PYRITION:PyritionPlayerStorageUpdateMeta(ply, player_storage, meta_data, path, meta_version)
	print("outdated meta data! (version " .. meta_version .. " when it should be version " .. current_meta_data_version .. ")\nupdating...")
	
	for version_index = meta_version + 1, current_meta_data_version do
		local update_function = meta_data_updates[version_index]
		
		if update_function then
			print("applying update #" .. version_index)
			update_function(ply, player_storage, meta_data, path, meta_version)
		end
	end
	
	meta_data.version = current_meta_data_version
end

--hooks
hook.Add("PlayerDisconnected", "pyrition_player_storage", function(ply)
	hook.Call("PyritionPlayerStorageSave", PYRITION, ply)
	
	--reset them AFTER we use them
	timer.Simple(0, function() player_storages[ply] = nil end)
end)

hook.Add("PlayerInitialSpawn", "pyrition_player_storage", function(ply) hook.Call("PyritionPlayerStorageLoad", PYRITION, ply) end)
hook.Add("ShutDown", "pyrition_player_storage", function() for index, ply in ipairs(player.GetHumans()) do hook.Call("PyritionPlayerStorageSave", PYRITION, ply) end end)