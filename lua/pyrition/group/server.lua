--locals
local delete_max_depth = 5
local groups = PYRITION.Groups
local groups_precedence = PYRITION.GroupsPrecedence
local pretty_print = true
local rgba_to_digital, digital_to_rgba = include("pyrition/includes/digital_color.lua")

--globals
PYRITION.SyncHooks.Group = {
	--create a sync when a player loads in
	Initial = {
		Groups = groups_precedence,
		Iteration = 1,
		Key = "Group",
		Max = 0
	},
	
	--call the hook multiple times until it does not return true
	--this does not send multiple net messages
	Iterative = true,
	
	--merge the sync data creating a CRecipientFilter for all players targetted
	Merge = true,
	
	--prefixed by pyrition_
	NewtorkString = "group",
	
	--importance of this sync over others
	--console is 10
	--group is 20
	Priority = 20,
}

--local functions
local function delete_directory(path, depth)
	local files, folders = file.Find(path .. "/*", "DATA")
	
	--delete all files
	for index, file_name in ipairs(files) do file.Delete(path .. "/" .. file_name) end
	
	--if we are not max depth run this function on all folders
	if depth < delete_max_depth then for index, folder_name in ipairs(folders) do delete_directory(path .. "/" .. folder_name, depth + 1) end end
	
	--finally delete this folder
	file.Delete(path)
end

--pyrition functions
function PYRITION:PyritionGroupCreate(key, data, save, sync)
	if self.Groups[key] then hook.Call("PyritionGroupRemove", self, key, true, false) end
	if data.SuperAdministrator then data.Administrator = true end
	
	data.Authority = data.Authority or 0
	data.Color = data.Color or color_white
	
	groups[key] = data
	
	if save then hook.Call("PyritionGroupSave", self, key) end
	
	hook.Call("PyritionGroupCalculatePrecedence", self)
	
	if sync then
		hook.Call("PyritionSyncQueue", PYRITION, {
			Groups = {key},
			Iteration = 1,
			Key = "Group",
			Max = 1,
			Target = player.GetAll()
		})
	end
end

function PYRITION:PyritionGroupDelete(key) delete_directory("pyrition/groups/" .. key, 0) end

function PYRITION:PyritionGroupLoadFolders(path)
	local files, folders = file.Find(path .. "*", "DATA")
	
	for index, folder_name in ipairs(folders) do
		local folder_path = path .. folder_name
		local meta_path = folder_path .. "/meta.json"
		
		if file.Exists(meta_path, "DATA") then
			local meta_json = file.Read(meta_path, "DATA")
			
			print("loaded " .. folder_name .. " successfully")
			
			if meta_json then
				local meta_read = util.JSONToTable(meta_json)
				
				if meta_read then hook.Call("PyritionGroupCreate", self, folder_name, meta_read)
				else ErrorNoHaltWithStack("Failed to parse the meta.json of group " .. folder_name .. " into a table") end
			else ErrorNoHaltWithStack("Failed to read the meta.json of group " .. folder_name) end
		else ErrorNoHaltWithStack("Group " .. folder_name .. " did not have a meta.json") end
	end
end

function PYRITION:PyritionGroupPlayerSet(ply, key) self:SetNWString("UserGroup", key) end

function PYRITION:PyritionGroupRemove(key, delete, sync)
	for index, ply in ipairs(player.GetAll()) do if hook.Call("PyritionGroupPlayerGet", self, ply) == key then hook.Call("PyritionGroupPlayerSet", self, ply, "guest") end end
	
	groups[key] = nil
	
	if delete then hook.Call("PyritionGroupDelete", self, key) end
	
	hook.Call("PyritionGroupCalculatePrecedence", self)
	
	if sync then
		hook.Call("PyritionSyncQueue", PYRITION, {
			Groups = groups_precedence,
			Iteration = 1,
			Key = "Group",
			Max = #groups_precedence,
			Target = player.GetAll()
		})
	end
end

function PYRITION:PyritionGroupSave(key)
	local group_info = groups[key]
	
	if group_info then
		local meta_json = util.TableToJSON(key, pretty_print)
		local path = "pyrition/groups/" .. key
		
		file.CreateDir(path)
		file.Write(path .. "meta.json", meta_json)
	end
end

function PYRITION:PyritionSyncHookGroup(data, passes)
	print("PyritionSyncHookGroup, passes: ", passes)
	
	data.Max = table.Count(groups)
	local iteration = data.Iteration
	local sync_groups = data.Groups
	local syncing_group = sync_groups[iteration]
	local group_info = groups[syncing_group]
	
	if passes > 0 then net.WriteBool(true) end
	
	net.WriteString(syncing_group)
	
	if group_info then
		net.WriteBool(true)
		net.WriteUInt(rgba_to_digital(group_info.Color), 32)
		net.WriteUInt(group_info.Authority, 16)
		
		if group_info.SuperAdministrator then net.WriteBool(true)
		else
			net.WriteBool(false)
			net.WriteBool(group_info.Administrator)
		end
		
		if group_info.Parent and groups[group_info.Parent] then
			net.WriteBool(true)
			net.WriteString(group_info.Parent)
		else net.WriteBool(false) end
	else net.WriteBool(false) end
	
	--with iterative sync hooks, return true to keep going or return the new number for passes
	return true
end

function PYRITION:PyritionSyncInitialGroup(data) end

function PYRITION:PyritionSyncSendingGroup(data, bytes_written) net.WriteBool(false) end

--hooks
hook.Add("PyritionPlayerStorageLoaded", "PyritionGroup", function(ply, player_storage) hook.Call("PyritionGroupPlayerSet", ply, player_storage.meta.group) end)
hook.Remove("PlayerInitialSpawn", "PlayerAuthSpawn") --we're making out own, so we don't need this

--post
--[[
hook.Call("PyritionGroupCreate", PYRITION, "guest", {
	Authority = 0, --ranges from 0 to 65535
	Color = Color(151, 239, 255),
	Parent = nil --default for grabbing information if not set
})

hook.Call("PyritionGroupCreate", PYRITION, "member", {
	Authority = 1, --ranges from 0 to 65535
	Color = Color(0, 217, 255),
	Parent = "guest" --default for grabbing information if not set
})

hook.Call("PyritionGroupCreate", PYRITION, "regular", {
	Authority = 2, --ranges from 0 to 65535
	Color = Color(32, 255, 99),
	Parent = "member" --default for grabbing information if not set
})

hook.Call("PyritionGroupCreate", PYRITION, "respected", {
	Authority = 3, --ranges from 0 to 65535
	Color = Color(255, 240, 32),
	Parent = "member" --default for grabbing information if not set
})

hook.Call("PyritionGroupCreate", PYRITION, "moderator", {
	Authority = 4, --ranges from 0 to 65535
	Color = Color(255, 166, 32),
	Parent = "respected" --default for grabbing information if not set
})

hook.Call("PyritionGroupCreate", PYRITION, "administrator", {
	Administrator = true,
	Authority = 5, --ranges from 0 to 65535
	Color = Color(255, 32, 32),
	Parent = "respected" --default for grabbing information if not set
})

hook.Call("PyritionGroupCreate", PYRITION, "developer", {
	Authority = 6, --ranges from 0 to 65535
	Color = Color(192, 0, 0),
	Parent = "administrator", --default for grabbing information if not set
	SuperAdministrator = true
}) --]]


hook.Call("PyritionGroupLoadFolders", PYRITION, "pyrition/groups/")