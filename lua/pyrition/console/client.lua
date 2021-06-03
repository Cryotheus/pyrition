function PYRITION:PyritionCommandComplete(command, arguments)
	local arguments = arguments and string.Split(string.TrimLeft(arguments), " ") or false
	local partial = arguments[1] or ""
	local root_command = PYRITION.Commands[partial] or false
	
	if root_command and root_command.Tree then
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
	
	return self:PyritionLanguageFormat("pyrition.insult.autocomplete")
end

--commands
concommand.Add("pyrition", function(...) hook.Call("PyritionCommandRun", PYRITION, ...) end, function(...) hook.Call("PyritionCommandComplete", PYRITION, ...) end, PYRITION:PyritionLanguageFormat("pyrition.command.help"))