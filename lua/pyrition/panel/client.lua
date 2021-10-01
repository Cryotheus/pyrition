--locals
local color_generic = Color(255, 255, 255)
local color_significant = Color(255, 191, 0)

--pyrition functions
function PYRITION:PyritionPanelLoad(path)
	local files, folders = file.Find(path .. "*.lua", "LUA")
	
	for index, file_name in ipairs(files) do
		local base_name, description, name
		local panel = string.StripExtension(file_name)
		local panel_error = "pyrition did not find an error"
		local file_path = path .. file_name
		local valid_script
		
		PANEL = {}
		
		local compiled_script = CompileFile(file_path)
		
		PANEL.Function = compiled_script
		
		if compiled_script then valid_script = xpcall(function() name, description, base_name = compiled_script() end, function(error_message) panel_error = error_message end) end
		
		if valid_script then
			derma.DefineControl("Pyrition" .. name, description, PANEL, base_name or "DPanel")
			MsgC(color_generic, " ]        panel " .. panel .. "\n")
		else
			ErrorNoHaltWithStack(file_path .. " had an script error before the panel could be registered.\n" .. panel_error)
			MsgC(color_generic, " ]        panel " .. panel .. " (erred: [" .. panel_error .. "])\n")
		end
		
		PANEL = nil
	end
end