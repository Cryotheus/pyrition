--locals
local color_generic = Color(255, 255, 255)
local color_significant = Color(255, 191, 0)

local page_defaults = {
	DeployTab = function(old_page, old_tab, new_tab) end, --doesn't get called if its the current tab's first time, instead, PAGE:Init is called
	HolsterTab = function(new_page, old_tab, new_tab) end,
	Initialize = function(self) return true end
}

--pyrition functions
function PYRITION:PyritionMenuLoadPages(path)
	local files = file.Find(path .. "*.lua", "LUA")
	
	self.Pages = {}
	
	for index, file_name in ipairs(files) do
		local page = string.StripExtension(file_name)
		local page_error = "pyrition did not find an error"
		local page_path = path .. file_name
		local page_script
		local valid_page
		
		PAGE = table.Copy(page_defaults)
		PAGE.Page = page
		PAGE.ID = index
		
		local page_script = CompileFile(page_path)
		
		PAGE.Function = page_script
		
		if page_script then valid_page = xpcall(page_script, function(error_message) page_error = error_message end) end
		
		if valid_page then
			if PAGE:Initialize() then
				local base = PAGE.Base or "DPanel"
				local new_name = string.StartWith(PAGE.Name, "PyritionMenuPage") and PAGE.Name or "PyritionMenuPage" .. PAGE.Name
				
				derma.DefineControl(new_name, "Panel automatically loaded by Pyrition.", PAGE, base)
				MsgC(color_generic, " ]        page " .. page .. "\n")
				
				PAGE.Base = base
				PAGE.Name = new_name
				self.Pages[page] = PAGE
				
				continue
			end
			
			MsgC(color_generic, " ]        page " .. page .. " (skipped)\n")
		else MsgC(color_generic, " ]        page " .. page .. " (erred: [" .. page_error .. "])\n") end
	end
	
	PAGE = nil
end

--commands
concommand.Add("pyrition_reload_pages", function() hook.Call("PyritionMenuLoadPages", PYRITION, "pyrition/menu/pages/") end)

--post
hook.Call("PyritionMenuLoadPages", PYRITION, "pyrition/menu/pages/")