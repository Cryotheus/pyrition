COMMAND.Realm = PYRITION_SHARED

COMMAND.Tree = {
	get = function(self, ply, arguments, arguments_string)
		if #arguments == 2 then
			local command, variable = unpack(arguments)
			local command_data = PYRITION.Commands[command]
			
			if command_data == nil then return self:Fail(ply, "Command specified does not exist, therefore we cannot fetch any value.\n") end
			if command_data.VariableMeta[variable] == nil then return self:Fail(ply, "Variable does not exist for the specified command.\n") end
			
			local value = hook.Call("PyritionConsoleVariableGet", PYRITION, command, variable)
			
			self:Success(ply, command .. "." .. variable .. " = " .. (isstring(value) and '"' .. value .. '"' or "[ " .. tostring(value) .. " ]\n"))
		else self:Fail(ply, "Exactly 2 arguments are required.\n") end
	end,
	
	reload = function(self, ply, arguments, arguments_string) hook.Call("PyritionConsoleVariableLoad", PYRITION) end,
	save = function(self, ply, arguments, arguments_string) hook.Call("PyritionConsoleVariableSave", PYRITION) end,
	
	set = function(self, ply, arguments, arguments_string)
		if #arguments == 3 then
			local command, variable, value = unpack(arguments)
			local command_data = PYRITION.Commands[command]
			
			if command_data == nil then return self:Fail(ply, "Command specified does not exist, therefore we cannot give it a value.\n") end
			if command_data.VariableMeta[variable] == nil then return self:Fail(ply, "Variable does not exist for the specified command.\n") end
			
			hook.Call("PyritionConsoleVariableSet", PYRITION, command, command_data, variable, value)
		else self:Fail(ply, "Exactly 3 arguments are required.\n") end
	end,
}