local color_generic = Color(255, 255, 255)
local color_significant = Color(255, 192, 0)

local command_defaults = {
	Execute = function(self, arguments)
		if arguments and not table.IsEmpty(arguments) then
			local current = self.Tree
			local local_arguments = table.Copy(arguments)
			
			for index, branch in ipairs(arguments) do
				local tree = current[branch]
				
				if istable(tree) then
					current = tree
					
					table.remove(local_arguments, 1)
				elseif isfunction(tree) then
					table.remove(local_arguments, 1)
					
					return tree(self, local_arguments)
				else break end
			end
			
			local root_function = current[1]
			
			if isfunction(root_function) then return root_function(self, local_arguments)
			else self:Fail("End of command tree reached with no root function present.") end
		else return self:ExecuteRoot(arguments, arguments_string) end
	end,
	
	ExecuteRoot = function(self, ...)
		local root_function = self.Tree[1]
		
		if root_function then return root_function(self, ...)
		else self:Fail("No root command present.") end
	end,
	
	Fail = function(self, message) print(message or "Unknown command.") end,
	Initialize = function(self) return true end,
	PostInitialize = function(self) return true end,
	Success = function(self, message) print(message or "Success.") end
}

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
function PYRITION:PyritionCommandLoad(path)
	--local files = file.Find("lua/" .. path .. "*.lua", "garrysmod")
	local files = file.Find(path .. "*.lua", "LUA")
	
	for index, file_name in ipairs(files) do
		local command = string.StripExtension(file_name)
		local command_tree = true
		local file_path = path .. file_name
		
		COMMAND = table.Copy(command_defaults)
		COMMAND.ID = index
		
		include(file_path)
		
		PYRITION.Commands[command] = COMMAND
		
		if COMMAND:Initialize() and hook.Call("PyritionCommandInitialized", self, COMMAND) then
			if COMMAND.Tree then
				local function_count = count_functions(COMMAND.Tree, 0)
				COMMAND.TreeCommandCount = function_count
				
				MsgC(color_generic, " ]        command " .. command .. " = " .. function_count .. "\n")
			else MsgC(color_generic, " ]        command " .. command .. "\n") end
		else
			PYRITION.Commands[command] = nil
			PYRITION.CommandTree[command] = true
			
			MsgC(color_generic, " ]        command " .. command .. " (skipped)\n")
		end
		
		COMMAND = nil
	end
end

function PYRITION:PyritionCommandRun(ply, command, arguments, arguments_string)
	arguments = arguments or {}
	local argument_command = arguments[1]
	
	if argument_command then
		local command_data = PYRITION.Commands[argument_command]
		
		if command_data then
			table.remove(arguments, 1)
			
			command_data:Execute(arguments)
		else print("No entry in command table found.") end
	else
		
	end
end