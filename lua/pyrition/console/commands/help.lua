COMMAND.Description = "List all commands or get specific information about a single command."

local color_command = Color(255, 224, 64)
local color_command_tree = Color(255, 128, 64)
local color_command_tree_executable = Color(255, 96, 96)
local color_description = Color(255, 255, 128)
local color_error = Color(64, 0, 0)
local description_insult = "Description field empty. Nice going nerd."

local function explore_tree(tree, depth)
	local prefix = string.rep("    ", depth)
	
	for command, data in pairs(tree) do
		--ignore root commands
		if isnumber(command) then continue end
		
		if isfunction(data) then MsgC(color_command, prefix .. command .. "\n")
		elseif istable(data) then
			local description = ""
			local first = data[1]
			
			if istable(first) then --support description but no root function
				description = first.Description or description_insult
				
				MsgC(color_command_tree, prefix .. command, color_description, ": " .. description .. "\n")
				explore_tree(data, depth + 1)
			else --default root function and description support
				local meta = data[2]
				
				if meta then description = meta.Description or description_insult end
				
				--only explore the tree if it has content besides numerical entries (which are reserved for the root function and meta data)
				if table.Count(data) - #data > 0 then
					MsgC(first and color_command_tree_executable or color_command_tree, prefix .. command, color_description, ": " .. description .. "\n")
					explore_tree(data, depth + 1)
				else MsgC(color_command, prefix .. command, color_description, ": " .. description .. "\n") end
			end
		else MsgC(color_error, 'An error occured. Dump:\n    "' .. tostring(command) .. '" values: "' .. tostring(data) .. '" @ depth ' .. depth .. "\n") end
	end
end

--command functions
function COMMAND:Execute(arguments)
	MsgC(
		color_command, "\n  Pyrition Commands\n\n",
		color_description, "This color represents an annotation or description.\n",
		color_command, "This color means the entry is an executable command.\n",
		color_command_tree, "This color means the entry is just a name space and cannot be executed.\n",
		color_command_tree_executable, "This color means the entry is both an executable command and a name space for more commands.\n\n"
	)
	
	for command, command_data in pairs(PYRITION.Commands) do
		local command_tree = command_data.Tree or false
		local command_tree_executable = command_tree and command_tree[1] or false
		local print_color = command_tree and (command_tree_executable and color_command_tree_executable or color_command_tree) or color_command
		
		MsgC(print_color, command, color_description, ": " .. (command_data.Description or description_insult) .. "\n")
		
		if command_tree then
			explore_tree(command_tree, 1)
			MsgC("\n")
		else
			--more?
			color = color_command
			MsgC("\n")
		end
	end
end

--overriding this will stop Tree[1] from getting run
--
--automatic
--function COMMAND:ExecuteRoot(...) return self.Tree[1](self, ...) end

--this is run right after the command is added to PYRITION
--if you do not return true, it is assumed that this command is not compatible with the provided environment
--this means it will get immediately removed before any further loading happens
--
--automatic
--function COMMAND:Initialize() return true end

--automatic
--function COMMAND:GetCommandTree() return self.Tree end