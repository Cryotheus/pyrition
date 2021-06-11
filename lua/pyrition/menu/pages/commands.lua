PAGE.Base = "DCategoryList"
PAGE.Name = "Commands" --just used for the panel's class name
PAGE.TabTooltip = "List of all executable commands."

--local functions
local function explore_commands(panel, key, data, depth)
	panel:Add(string.rep("        ", depth) .. key)
	
	if istable(data) then
		--what!
		for sub_key, sub_data in pairs(data) do if isstring(sub_key) then explore_commands(panel, sub_key, sub_data, depth + 1) end end
	end
end

--page functions
function PAGE:Init()
	local other_category = self:Add("Other")
	
	for command, command_data in pairs(PYRITION.Commands) do
		if istable(command_data) and command_data.Tree then explore_commands(other_category, command, command_data.Tree, 0)
		else other_category:Add(command) end
	end
end