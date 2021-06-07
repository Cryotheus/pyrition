--locals
local absolute_path = "pyrition/"
local user_path = absolute_path .. "players/"

--pyrition functions 
function PYRITION:PyritionPlayerStorageGetPath(steam_id)
	if string.StartWith(steam_id, "STEAM_0:") then steam_id = string.sub(steam_id, 9) end
	
	--remove the : between the binary number and the decimal number
	--split it into a table of digits
	--concatenate the table with a / between each digit
	return user_path .. table.concat(string.Split(string.Left(steam_id, 1) .. string.sub(steam_id, 3), ""), "/")
end

function PYRITION:PyritionPlayerStorageLoad(ply)
	
end

function PYRITION:PyritionPlayerStorageLoadMeta(ply, data_loaded)
	
end

function PYRITION:PyritionPlayerStorageSave(ply)
	if IsValid(ply) then
		if ply:IsBot() then return false end
		
		local steam_id = ply:SteamID()
		
		--lets no allow special ids
		--shortest possible is 11 characters
		if #steam_id < 11 then return false end
		
		local storage_path = hook.Call("PyritionPlayerStorageGetPath", self, steam_id)
		
		PLAYER_STORAGE_META = {
			name = ply:Name(),
			steam_64 = ply:SteamID64(),
			version = 1
		}
		
		file.CreateDir(path)
		hook.Call("PyritionPlayerStorageSaveMeta", PYRITION, storage_path .. "/meta.txt", ply)
		
		return true
	end
	
	return false
end

function PYRITION:PyritionPlayerStorageSaveMeta(path, ply)
	local data = util.TableToJSON(PLAYER_STORAGE_META, true)
	
	file.Write(path, data)
end

--hooks
hook.Add("PlayerDisconnected", "pyrition_player_storage", function(ply)
	
	
	
end)