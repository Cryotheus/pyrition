COMMAND.Realm = PYRITION_SHARED

local color_command = Color(255, 224, 64)
local color_command_mediated = Color(96, 96, 255)
local color_command_mediated_executable = Color(128, 255, 128)
local color_command_tree = Color(255, 96, 96)
local color_command_tree_executable = Color(255, 128, 64)
local color_description = Color(255, 255, 128)
local color_error = Color(64, 0, 0)
local describe
local description_insult

if SERVER then function describe() return ": Function descriptions are not available to the server realm.\n" end
else
	description_insult = language.GetPhrase("pyrition.insults.description")
	
	function describe(translation_key, no_concatenations)
		local translation = language.GetPhrase(translation_key)
		
		if translation == translation_key then
			if no_concatenations then return "" end
			
			return "\n"
		else
			if no_concatenations then return translation end
			
			return ": " .. translation .. "\n"
		end
	end
end

local function get_color_tree(first) return isbool(first) and (first and color_command_mediated_executable or color_command_mediated) or (isfunction(first) and color_command_tree_executable or color_command_tree) end

local function explore_tree(tree, translation_key, depth)
	local prefix = string.rep("    ", depth)
	
	for command, data in pairs(tree) do
		--ignore root commands
		if isnumber(command) then continue end
		
		local new_translation_key = translation_key .. "." .. command
		local description = describe(new_translation_key)
		
		--bool: server side
		--function: command exists on client
		--table: more data to explore
		--else: error
		
		if isbool(data) then MsgC(data and color_command_mediated_executable or color_command_mediated, prefix .. command, color_description, description)
		elseif isfunction(data) then MsgC(color_command, prefix .. command, color_description, description)
		elseif istable(data) then
			--numerical indices are for metadata
			local first = data[1]
			local has_depth = table.Count(data) - #data > 0
			
			if has_depth then
				MsgC(get_color_tree(first), prefix .. command, color_description, description)
				explore_tree(data, new_translation_key, depth + 1)
			else MsgC(isbool(first) and color_command_mediated_executable or color_command, prefix .. command, color_description, description) end
		else MsgC(color_error, 'An error occured. Dump:\n    "' .. tostring(command) .. '" values: "' .. tostring(data) .. '" @ depth ' .. depth .. "\n") end
	end
end

--command functions
function COMMAND:Execute(ply, arguments, arguments_string)
	MsgC(
		color_command, hook.Call("PyritionLanguageAttemptFormat", PYRITION, "pyrition.commands.help_info.header", "\n  Pyrition Commands\n\n"),
		color_description, hook.Call("PyritionLanguageAttemptFormat", PYRITION, "pyrition.commands.help_info", "Commands that are indented are sub commands of the preceding command. In order to run the command, all previous commands must be typed to access the desired sub command.\n\n"),
		color_command_mediated, hook.Call("PyritionLanguageAttemptFormat", PYRITION, "pyrition.commands.help_info.command_mediated", "This color represents a server side namespace and cannot be executed.\n"),
		color_command_mediated_executable, hook.Call("PyritionLanguageAttemptFormat", PYRITION, "pyrition.commands.help_info.command_mediated_executable", "This color represents a server side command that you can execute.\n"),
		color_description, hook.Call("PyritionLanguageAttemptFormat", PYRITION, "pyrition.commands.help_info.description", "This color represents an annotation or description.\n"),
		color_command, hook.Call("PyritionLanguageAttemptFormat", PYRITION, "pyrition.commands.help_info.command", "This color means the entry is an executable command.\n"),
		color_command_tree_executable, hook.Call("PyritionLanguageAttemptFormat", PYRITION, "pyrition.commands.help_info.command_tree_executable", "This color means the entry is both an executable command and a name space for more commands.\n"),
		color_command_tree, hook.Call("PyritionLanguageAttemptFormat", PYRITION, "pyrition.commands.help_info.command_tree", "This color means the entry is just a name space and cannot be executed.\n\n")
	)
	
	for command, command_data in pairs(PYRITION.Commands) do
		if isbool(command_data) then MsgC(command_data and color_command_mediated_executable or color_command_mediated, command, color_description, describe("pyrition.commands." .. command))
		else
			local command_tree = command_data.Tree or false
			local command_tree_executable = command_tree and command_tree[1] or false
			local print_color = command_tree and get_color_tree(command_tree[1]) or color_command
			--local print_color = command_tree and (command_tree_executable and color_command_tree_executable or color_command_tree) or color_command
			local translation_key = "pyrition.commands." .. command
			
			MsgC(print_color, command, color_description, describe(translation_key))
			
			if command_tree then explore_tree(command_tree, translation_key, 1) end
			
			MsgC(color_description, "\n")
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