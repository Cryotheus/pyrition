COMMAND.Description = "Open a VGUI menu for Pyrition."
COMMAND.Realm = PYRITION_CLIENT

COMMAND.Tree = {--self, ply, arguments, arguments_string
	
}

function COMMAND:Initialize()
	local files = file.Find("lua/pyrition/menus/*", "garrysmod")
	
	for index, script in ipairs(files) do
		
		
	end
	
	return true
end