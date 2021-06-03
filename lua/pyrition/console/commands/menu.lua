COMMAND.Description = "Open a VGUI menu for Pyrition."

COMMAND.Tree = {
	
}

function COMMAND:Initialize()
	local files = file.Find("lua/pyrition/menus/*", "garrysmod")
	
	for index, script in ipairs(files) do
		
		
	end
	
	return true
end