--locals
local command_triggers = {
	["/"] = true,
	["!"] = false
}

--globals
PYRITION.ChatCommandTriggers = command_triggers

--pyrition function
function PYRITION:PyritionConsoleChatExecuteCommand(...) return hook.Call("PyritionConsoleChatExecuteCommand", PYRITION, ...) end --for overriding purposes

function PYRITION:PyritionConsoleChatGetArguments(arguments_string)
	--parse a chat message that we know is a command
	local building
	local arguments = {}
	
	--Lua's patterns are too limited, so we make our own matcher
	for index, word in ipairs(string.Explode("%s", arguments_string, true)) do
		if building then --we're creating a string with spaces in it so we can add it to the list
			if string.EndsWith(word, '"') then
				table.insert(arguments, building .. " " .. string.sub(word, 1, -2))
				
				building = nil
			else building = building .. " " .. word end
		elseif word == '"' then building = "" --we need to build a string with spaces in it
		elseif string.StartWith(word, '"') then --we need to build a string with spaces in it starting with this word, unless it ends at this word
			if string.EndsWith(word, '"') then table.insert(arguments, string.sub(word, 2, -2))
			else building = string.sub(word, 2) end
		elseif word ~= "" then  table.insert(arguments, word) end --we should add the word to the list
	end
	
	return arguments
end

function PYRITION:PyritionConsoleChatHook(ply, text, team_chat)
	print(ply, text, team_chat)
	
	local command_trigger = command_triggers[string.Left(text, 1)]
	
	if command_trigger == nil then return end
	
	local arguments = hook.Call("PyritionConsoleChatGetArguments", PYRITION, string.sub(text, 2))
	local command = arguments[1]
	
	if command then
		local command_data = PYRITION.Commands[command]
		
		if command_data then
			local arguments_string = string.sub(text, #text + 3)
			
			table.remove(arguments, 1)
			hook.Call("PyritionConsoleChatExecuteCommand", PYRITION, ply, command_data, command, arguments, arguments_string)
		end
	end
	
	if command_trigger then return CLIENT and true or "" end
end

--hooks
hook.Add("OnPlayerChat", "PyritionConsoleChat", function(...) return hook.Call("PyritionConsoleChatHook", PYRITION, ...) end)