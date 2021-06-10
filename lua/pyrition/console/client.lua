--locals
--local functions
local function execute_media(command_data, ply, arguments, arguments_string) hook.Call("PyritionConsoleRunMediatedCommand", PYRITION, ply, command_data.Command, arguments, arguments_string) end
local function has_flag(flags, flag) return bit.band(flags, flag) == flag end

local function read_media_command()
	local command = net.ReadString()
	local command_data
	
	if net.ReadBool() then
		command_data = {net.ReadBool()}
		
		repeat
			local sub_command, sub_command_data = read_media_command()
			command_data[sub_command] = sub_command_data
		until not net.ReadBool()
	else command_data = true end
	
	return command, command_data
end

--pyrition functions
function PYRITION:PyritionConsoleCompleteCommand(command, arguments)
	local arguments = arguments and string.Split(string.TrimLeft(arguments), " ") or false
	local partial = arguments[1] or ""
	local root_command = PYRITION.Commands[partial] or false
	
	if istable(root_command) and root_command.Tree then
		local completes = {}
		local current = root_command.Tree
		partial = ""
		local prefix = "pyrition " .. table.remove(arguments, 1)
		
		for index, branch in ipairs(arguments) do
			local tree = current[branch]
			
			if istable(tree) then
				current = tree
				prefix = prefix .. " " .. branch
			else
				partial = branch
				
				break
			end
		end
		
		for branch, branch_data in pairs(current) do
			if branch == 1 then if isfunction(branch_data) then table.insert(completes, prefix) end
			elseif string.StartWith(branch, partial) then table.insert(completes, prefix .. " " .. branch) end
		end
		
		return completes
	else
		local completes = {}
		
		for root_command, command_data in pairs(PYRITION.Commands) do if string.StartWith(root_command, partial) then table.insert(completes, "pyrition " .. root_command) end end
		
		return completes
	end
	
	return self:PyritionLanguageFormat("pyrition.insults.autocomplete")
end

function PYRITION:PyritionConsoleExecuteCommand(ply, command_data, command, arguments, arguments_string)
	print(ply, command_data, command, arguments, arguments_string)
	
	if isbool(command_data) then hook.Call("PyritionConsoleRunMediatedCommand", PYRITION, ply, argument_command, arguments, arguments_string)
	else command_data:Execute(ply, arguments, arguments_string) end
end

function PYRITION:PyritionConsoleInitializeCommand(file_path, command, command_data) return has_flag(command_data.Realm, PYRITION_CLIENT) end

function PYRITION:PyritionConsoleRunMediatedCommand(ply, command, arguments, arguments_string)
	net.Start("pyrition_console")
	net.WriteString(command)
	
	if #arguments > 0 then
		local passed = false
		
		net.WriteBool(true)
		net.WriteString(arguments_string)
		
		for index, argument in ipairs(arguments) do
			if passed then net.WriteBool(true)
			else passed = true end
			
			net.WriteString(argument)
		end
		
		net.WriteBool(false)
	else net.WriteBool(false) end
	
	net.SendToServer()
end

--commands
concommand.Add("pyrition", function(...)
	--more?
	hook.Call("PyritionConsoleRunCommand", PYRITION, ...)
end, function(...)
	--more
	return hook.Call("PyritionConsoleCompleteCommand", PYRITION, ...)
end, hook.Call(PyritionLanguageFormat, PYRITION, "pyrition.commands"))

--net
net.Receive("pyrition_console", function(length)
	repeat
		local command, command_data = read_media_command(command_data)
		
		if istable(command_data) then
			local has_root_function = command_data[1]
			
			if has_root_function then
				PYRITION.Commands[command] = {
					true,
					Command = command,
					Execute = execute_media,
					Tree = command_data
				}
			else PYRITION.Commands[command] =
				{
					Command = command,
					Execute = execute_media,
					Tree = command_data
				}
			end
		else PYRITION.Commands[command] = command_data end
		
		--PYRITION.MediaCommands[command] = command_data
	until not net.ReadBool()
end)

--post
hook.Call("PyritionConsoleLoadCommands", PYRITION, "pyrition/console/commands/")

--debug
--[[
local function debug_detour(library, key)
	local old_function = library[key .. "X_Pyrition"] or library[key]
	library[key .. "X_Pyrition"] = old_function
	
	library[key] = function(...)
		local returns = {old_function(...)}
		
		print("debug " .. key, unpack(returns))
		
		return unpack(returns)
	end
end

debug_detour(net, "ReadBool")
debug_detour(net, "ReadString")
debug_detour(net, "ReadUInt")
--]]