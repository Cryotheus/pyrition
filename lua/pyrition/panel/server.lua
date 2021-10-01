--locals
local color_generic = Color(255, 255, 255)
local color_significant = Color(255, 191, 0)

--pyrition functions
function PYRITION:PyritionPanelLoad(path)
	local files, folders = file.Find(path .. "*.lua", "LUA")
	
	for index, file_name in ipairs(files) do
		AddCSLuaFile(path .. file_name)
		MsgC(color_generic, " ]        panel " .. string.StripExtension(file_name) .. "\n")
	end
end