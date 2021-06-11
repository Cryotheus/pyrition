COMMAND.Description = "Open a VGUI menu for Pyrition."
COMMAND.Realm = PYRITION_CLIENT

--command functions
function COMMAND:Execute(ply, arguments, arguments_string)
	local menu_panel = vgui.Create("PyritionMenu")
	
	menu_panel:SetSize(640, 480)
	
	menu_panel:Center()
	menu_panel:MakePopup()
end

function COMMAND:Initialize()
	local files = file.Find("lua/pyrition/menus/*", "garrysmod")
	
	for index, script in ipairs(files) do
		
		
	end
	
	return true
end