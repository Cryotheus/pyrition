local path = "pyrition/console_variables"
local pretty_print = true
local console_variables_changes

--[[
PYRITION_VARIABLE_ANY = 0
PYRITION_VARIABLE_NUMBER = 1
PYRITION_VARIABLE_INTEGER = 2
PYRITION_VARIABLE_STRING = 3
]]

local variable_type_functions = {
	function(meta, value) --PYRITION_VARIABLE_NUMBER
		local value = tonumber(value)
		
		--clamp the value if so desired
		if value then return math.max(math.min(value, meta.Maximum or value), meta.Minimum or value) end
		
		return meta.Default
	end,
	
	function(meta, value) --PYRITION_VARIABLE_INTEGER
		local value = tonumber(value)
		
		--round, and if asked of us, clamp the value
		if value then return math.max(math.min(math.Round(value), meta.Maximum or value), meta.Minimum or value) end
		
		return meta.Default
	end,
	
	function(meta, value) --PYRITION_VARIABLE_STRING
		if value == nil then return meta.Default end
		
		local maximum = meta.Maximum
		value = tostring(value)
		
		--clamp or empty the string, however desired
		if maximum then value = string.sub(value, 1, maximum) end
		if #value < meta.Minimum then return meta.Default end
		
		return value
	end,
	
	function(meta, value) if value == nil then return meta.Default else return tobool(value) end end --PYRITION_VARIABLE_BOOL
}

--local functions
local function add_change(command, variable, value)
	if console_variables_changes then
		if console_variables_changes[command] then console_variables_changes[command][variable] = value
		else console_variables_changes[command] = {[variable] = value} end
	else console_variables_changes = {[command] = {[variable] = value}} end
end

--pyrition functions
function PYRITION:PyritionConsoleVariableGet(command, variable)
	local command_variables = self.Variables[command]
	
	if command_variables then return command_variables[variable] end
end

function PYRITION:PyritionConsoleVariableLoad()
	--for reload command maybe, because we already load them when commands initialize
	for command, command_data in pairs(self.Commands) do
		--update all instances!
		local command_variables = hook.Call("PyritionConsoleVariableLoadCommand", self, command, command_data)
		command_data.Variables = command_variables
		
		command_data:VariablesInitialized(command_variables)
	end
end

function PYRITION:PyritionConsoleVariableLoadCommand(command, command_data)
	local command_variables = {}
	local read_json = file.Read(path .. "/" .. command .. ".json", "DATA")
	
	--make sure we at least have the default values in there
	for key, meta in pairs(command_data.VariableMeta) do command_variables[key] = meta.Default end
	
	if read_json then
		local json_table = util.JSONToTable(read_json)
		
		if json_table then
			local command_variable_meta = command_data.VariableMeta
			
			--now update the table with the new values
			for key, value in pairs(json_table) do
				local variable_meta = command_variable_meta[key]
				
				if variable_meta then
					local type_function = variable_type_functions[variable_meta.TypeFlag or 0]
					
					if type_function then command_variables[key] = type_function(variable_meta, value) end
				else command_variables[key] = nil end
			end
		end
	end
	
	if table.IsEmpty(command_variables) then return false end
	
	self.Variables[command] = command_variables
	
	return command_variables
end

function PYRITION:PyritionConsoleVariableSave(changes)
	--this is like PyritionConsoleVariableSet, but it takes a table of the commands' changes and writes them
	--if changes is nil, it will save everything
	--todo: make async!
	--todo: don't save variables with the PYRITION_VARIABLE_REPLICATED flag if we're the client
	console_variables_changes = nil
	local variables = self.Variables
	
	file.CreateDir(path)
	
	if changes then
		local commands = PYRITION.Commands
		
		for command, command_variable_changes in pairs(changes) do
			local command_data = commands[command]
			local command_variables = command_data.Variables
			local command_variable_meta = command_data.VariableMeta
			
			for key, value in pairs(command_variable_changes) do
				local variable_meta = command_variable_meta[key]
				local type_function = variable_type_functions[variable_meta.TypeFlag or 0]
				
				--first, normalize changes
				if type_function then command_variable_changes[key] = type_function(variable_meta, value) end
			end
			
			table.Merge(command_variables, command_variable_changes)
			
			local json = util.TableToJSON(command_variables, pretty_print)
			
			file.Write(path .. "/" .. command .. ".json", json)
		end
	else
		for command, command_variables in pairs(self.Variables) do
			local json = util.TableToJSON(command_variables, pretty_print)
			
			file.Write(path .. "/" .. command .. ".json", json)
		end
	end
end

function PYRITION:PyritionConsoleVariableSet(command, command_data, variable, value, dont_save)
	local command_variable_meta = command_data.VariableMeta
	local command_variables = self.Variables[command]
	
	local type_function = variable_type_functions[command_variable_meta[variable].TypeFlag or 0]
	
	if type_function then command_variables[variable] = type_function(meta, value)
	else command_variables[variable] = value end
	
	if dont_save then return end
	
	add_change(command, variable, value)
end

--hooks
hook.Add("Think", "pyrition_console_variables", function()
	--more?
	if console_variables_changes then hook.Call("PyritionConsoleVariableSave", PYRITION, console_variables_changes) end
end)