util.AddNetworkString("pyrition_console")
resource.AddSingleFile("resource/localization/en/pyrition.properties")

--locals
local color_generic = Color(255, 255, 255)
local color_significant = Color(255, 191, 0)
local mediated_commands = {}
local syncing_players = {}

--local functions
local function has_flag(flags, flag) return bit.band(flags, flag) == flag end

local function write_media_command(command, command_tree)
	net.WriteString(command)

	if istable(command_tree) then
		net.WriteBool(true)
		net.WriteBool(command_tree[1] and true or false)
		
		return true
	else net.WriteBool(false) end
	
	return false
end

local function write_media_commands(command_tree)
	local passed = false
	
	for command, command_data in pairs(command_tree) do
		if isnumber(command) then continue end
		if passed then net.WriteBool(true)
		else passed = true end
		
		if write_media_command(command, command_data) then write_media_commands(command_data) end
	end
	
	net.WriteBool(false)
end

--pyrition functions
function PYRITION:PyritionConsoleInitializeCommand(file_path, command, command_data)
    if has_flag(command_data.Realm, PYRITION_CLIENT) then AddCSLuaFile(file_path) end
    if has_flag(command_data.Realm, PYRITION_MEDIATED) then table.insert(mediated_commands, command) end
	if has_flag(command_data.Realm, PYRITION_SERVER) then return true end
    
    return false
end

function PYRITION:PyritionConsoleRunMediatedCommand(ply, command, arguments, arguments_string)
	MsgC(color_significant, "[Pyrition] ", color_generic, " Mediated command [" .. command .. "] has been run by " .. (IsValid(ply) and ("[" .. ply:Name() .. "]") or "<Invalid>") .. " with the following argument string: ", arguments_string, "\n")
	table.insert(arguments, 1, command)
	hook.Call("PyritionConsoleRunCommand", PYRITION, ply, "pyrition_media", arguments, command .. " " .. arguments_string)
end

--commands
concommand.Add("pyrition", function(...) hook.Call("PyritionConsoleRunCommand", PYRITION, ...) end)

--hooks
hook.Add("PlayerDisconnected", "pyrition_console", function(ply) syncing_players[ply] = nil end)

hook.Add("PyritionPlayerInitialized", "pyrition_console", function(ply, emulated)
	print("adding player to sync", ply, emulated)
	
	syncing_players[ply] = 0
end)

hook.Add("Think", "pyrition_console", function()
	local commands = PYRITION.Commands
	local mediated_amount = #mediated_commands
	
	for ply, commands_synced in pairs(syncing_players) do
		local passed = false
		
		net.Start("pyrition_console")
		
		repeat
			commands_synced = commands_synced + 1
			
			local command = mediated_commands[commands_synced]
			local command_data = commands[command]
			local command_tree = command_data.Tree
			
			if passed then net.WriteBool(true)
			else passed = true end
			
			if write_media_command(command, command_tree) then write_media_commands(command_tree) end
		until commands_synced >= mediated_amount or net.BytesWritten() > 100
		
		net.WriteBool(false)
		net.Send(ply)
		 
		if commands_synced >= mediated_amount then print("done with", ply) syncing_players[ply] = nil end
	end
end)

--net
net.Receive("pyrition_console", function(length, ply)
	local command = net.ReadString()
	local command_data = PYRITION.Commands[command]
	
	if command_data and has_flag(command_data.Realm, PYRITION_MEDIATED) then
		local arguments = {}
		local arguments_string = net.ReadString()
		
		while net.ReadBool() do table.insert(arguments, net.ReadString()) end
		
		hook.Call("PyritionConsoleRunMediatedCommand", PYRITION, ply, command, arguments, arguments_string)
	end
end)

--post
hook.Call("PyritionConsoleLoadCommands", PYRITION, "pyrition/console/commands/")

--debug
--[[
local function debug_detour(library, key)
	local old_function = library[key .. "X_Pyrition"] or library[key]
	library[key .. "X_Pyrition"] = old_function
	
	library[key] = function(...)
		print("debug " .. key .. " with", ...)
		
		return old_function(...)
	end
end

debug_detour(net, "WriteBool")
debug_detour(net, "WriteString")
debug_detour(net, "WriteUInt")
--]]