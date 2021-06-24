util.AddNetworkString("pyrition_console")

--locals
local color_generic = Color(255, 255, 255)
local color_significant = Color(255, 191, 0)
local mediated_commands = {}

--globals
PYRITION.SyncHooks.Console = {
	--create a sync when a player loads in
	Initial = {
		Iteration = 1,
		Key = "Console",
		Max = 2,
		MediatedCommands = {}
	},
	
	--call the hook multiple times until it does not return true
	--this does not send multiple net messages
	Iterative = true,
	
	--merge the sync data creating a CRecipientFilter for all players targetted
	Merge = false,
	
	--prefixed by pyrition_
	NewtorkString = "console",
	
	--importance of this sync over others
	--console is 10
	--group is 20
	Priority = 10,
}

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
function PYRITION:PyritionConsoleExecuteCommand(ply, command_data, command, arguments, arguments_string)
	--check permissions
	command_data:Execute(ply, arguments, arguments_string)
end

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

function PYRITION:PyritionSyncHookConsole(data, first)
	--first is true if it is the first time this hook has been called since the net message has started
	local command = data.MediatedCommands[data.Iteration]
	local command_data = self.Commands[command]
	local command_tree = command_data.Tree
	
	if not first then net.WriteBool(true) end
	if write_media_command(command, command_tree) then write_media_commands(command_tree) end
	
	--with iterative sync hooks, return true to keep going
	return true
end

function PYRITION:PyritionSyncInitialConsole(data)
	--find commands that they have permissions to use, and put the data.MediatedCommands table
	--instead of this, which is temporary
	data.MediatedCommands = mediated_commands
	
	--return false if you don't want to make an initial sync
	return true
end

function PYRITION:PyritionSyncSendingConsole(data, bytes_written) net.WriteBool(false) end

--commands
concommand.Add("pyrition", function(...) hook.Call("PyritionConsoleRunCommand", PYRITION, ...) end)

concommand.Add("pyrition_reload_media", function(ply, command, arguments, arguments_string)
	if IsValid(ply) then
		local sync_data = {
			Iteration = 1,
			Key = "Console",
			Max = #mediated_commands,
			MediatedCommands = mediated_commands,
			Target = ply
		}
		
		hook.Call("PyritionSyncQueue", PYRITION, sync_data)
	else print("I'm sorry John, you can't sync the server to itself.") end
end)

--hooks
hook.Add("PyritionConsoleLoadCommands", "pyrition_console", function(path) mediated_commands = {} end)

--net
net.Receive("pyrition_console", function(length, ply)
	local command = net.ReadString()
	local command_data = PYRITION.Commands[command]
	
	--we gotta make sure this is actually a mediated command, we don't want server-only commands getting run by clients
	--unless we make an rcon or something
	if command_data and has_flag(command_data.Realm, PYRITION_MEDIATED) then
		local arguments = {}
		local arguments_string = ""
		
		if net.ReadBool() then
			arguments_string = net.ReadString()
			
			repeat table.insert(arguments, net.ReadString()) until not net.ReadBool()
		end
		
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