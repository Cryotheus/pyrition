local color_generic = Color(255, 255, 255)
local color_significant = Color(255, 191, 0)

local command_defaults = {
	Execute = function(self, ply, arguments, arguments_string)
		if arguments and not table.IsEmpty(arguments) then
			local current = self.Tree
			local local_arguments = table.Copy(arguments)
			
			for index, branch in ipairs(arguments) do
				--force argument tells us that we prefixed with ? and that this is an argument, not a sub command or namespace
				local force_argument = string.StartWith(branch, "?") and string.TrimLeft(branch, "?") ~= "?"
				local tree = current[force_argument and string.sub(branch, 2) or branch]
				
				if force_argument and tree then
					arguments_string = string.sub(arguments_string, 2)
					local_arguments[1] = string.sub(local_arguments[1], 2)
					
					break
				end
				
				if istable(tree) then --we hit another tree of sub commands
					arguments_string = string.sub(arguments_string, #branch + 2)
					current = tree
					
					table.remove(local_arguments, 1)
				elseif isfunction(tree) then --we hit a sub command
					table.remove(local_arguments, 1)
					
					return tree(self, ply, local_arguments, string.sub(arguments_string, #branch + 2))
				else break end --we are now just parameters for the root function of the current
			end
			
			local root_function = current[1]
			
			if isfunction(root_function) then return root_function(self, ply, local_arguments, arguments_string)
			else self:Fail("End of command tree reached with no root function present.") end
		else return self:ExecuteRoot(ply, arguments, arguments_string) end
	end,
	
	ExecuteRoot = function(self, ...)
		local root_function = self.Tree[1]
		
		if root_function then return root_function(self, ...)
		else self:Fail("No root command present.") end
	end,
	
	Initialize = function(self) return true end,
	PostInitialize = function(self) return true end,
	Success = function(self, ply, key, phrases) print(key or "Success.") end,
	VariablesInitialized = function(self, command_variables) end,
	VariableMeta = {}
}

if SERVER then
	command_defaults.Fail = function(self, ply, key, phrases)
		print(self, ply, key, phrases)
		
		if IsValid(ply) then
			if phrases then hook.Call("PyritionLanguageSendFormat", PYRITION, ply, HUD_PRINTCONSOLE, key, phrases)
			else hook.Call("PyritionLanguageSend", PYRITION, ply, HUD_PRINTCONSOLE, key) end
		else MsgC(color_significant, "[Pyrition] ", color_generic, key) end
	end
else command_defaults.Fail = function(self, ply, key, phrases) hook.Call("PyritionLanguageMessage", PYRITION, ply, HUD_PRINTCONSOLE, key or "Failed.", phrases) end end

--local functions
local function count_functions(field, depth)
	local count = 0
	
	for key, value in pairs(field) do
		if istable(value) then count = count + count_functions(value, depth + 1)
		elseif isfunction(value) then count = count + 1 end
	end
	
	return count
end

--pyrition functions
function PYRITION:PyritionConsoleLoadCommands(path)
	--local files = file.Find("lua/" .. path .. "*.lua", "garrysmod")
	local files = file.Find(path .. "*.lua", "LUA")
	
	PYRITION.Commands = {}
	
	for index, file_name in ipairs(files) do
		local command = string.StripExtension(file_name)
		local command_error = "pyrition did not find an error"
		local command_script
		local command_tree = true
		local file_path = path .. file_name
		local valid_command
		
		COMMAND = table.Copy(command_defaults)
		COMMAND.Command = command
		COMMAND.ID = index
		
		local command_script = CompileFile(file_path)
		
		COMMAND.Function = command_script
		
		if command_script then valid_command = xpcall(command_script, function(error_message) command_error = error_message end) end
		
		if valid_command then
			if COMMAND:Initialize() and hook.Call("PyritionConsoleInitializeCommand", self, file_path, command, COMMAND) then
				local command_variables = hook.Call("PyritionConsoleVariableLoadCommand", self, command, COMMAND)
				COMMAND.Variables = command_variables
				
				COMMAND:VariablesInitialized(command_variables)
				
				if COMMAND.Tree then
					local function_count = count_functions(COMMAND.Tree, 0)
					COMMAND.TreeCommandCount = function_count
					
					MsgC(color_generic, " ]        command " .. command .. " = " .. function_count .. "\n")
				else MsgC(color_generic, " ]        command " .. command .. "\n") end
				
				PYRITION.Commands[command] = COMMAND
				
				COMMAND:PostInitialize()
				
				continue
			end
			
			MsgC(color_generic, " ]        command " .. command .. " (skipped)\n")
		else MsgC(color_generic, " ]        command " .. command .. " (erred: [" .. command_error .. "])\n") end
	end
	
	COMMAND = nil
end

function PYRITION:PyritionConsoleRunCommand(ply, command, arguments, arguments_string)
	arguments = arguments or {}
	local argument_command = arguments[1]
	
	if argument_command then
		local command_data = PYRITION.Commands[argument_command]
		
		if command_data then
			table.remove(arguments, 1)
			
			if isbool(command_data) then hook.Call("PyritionConsoleRunMediatedCommand", PYRITION, ply, argument_command, arguments, string.sub(arguments_string, #argument_command + 2))
			else command_data:Execute(ply, arguments, string.sub(arguments_string, #argument_command + 2)) end
		else print("No entry in command table found.\n") end
	else hook.Call("PyritionLanguageMessage", PYRITION, ply, 0, "pyrition.insults.unknown_command") end
end

--commands
concommand.Add("pyrition_reload_commands", function() hook.Call("PyritionConsoleLoadCommands", PYRITION, "pyrition/console/commands/") end, nil, "Reload all Pyrition commands.")