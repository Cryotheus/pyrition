--locals
local color_generic = Color(255, 255, 255)
local color_significant = Color(255, 191, 0)

--pyrition functions
function PYRITION:PyritionMenuLoadPages(path)
	local files = file.Find(path .. "*.lua", "LUA")
	
	self.Pages = {}
	
	for index, file_name in ipairs(files) do
		AddCSLuaFile(path .. file_name)
		MsgC(color_generic, " ]        page " .. string.StripExtension(file_name) .. "\n")
	end
end

--post
hook.Call("PyritionMenuLoadPages", PYRITION, "pyrition/menu/pages/")