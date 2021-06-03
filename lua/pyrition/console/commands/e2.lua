local custom_default_code
local editor_control_table
local template_load

--sources
--local functions
local function global_panel_update(class, updater)
	--runs the function provided on the panel's table and all panels active under the world panel 
	updater(false, editor_control_table)
	
	for index, panel in ipairs(vgui.GetWorldPanel():GetChildren()) do if panel:GetName() == class then updater(true, panel) end end
end

local function template_disable(self)
	global_panel_update("Expression2EditorFrame", function(is_panel, panel)
		if editor_control_table.NewScriptX then
			editor_control_table.NewScript = editor_control_table.NewScriptX
			editor_control_table.NewScriptX = nil
		end
	end)
end

local function template_enable(self)
	--we can't do the same with shutdown save ;-;
	--its too hard to expose
	local function auto_save(self, ...)
		--don't save default code dingus
		if self:GetCode() == custom_default_code then return end
		
		self:AutoSaveX(...)
	end
	
	local function new_script(self, in_current, ...)
		if not in_current and self.NewTabOnOpen:GetBool() then self:NewTab() --this will call NewScript if we have a new tab on open
		else
			self:AutoSave()
			self:ChosenFile()
			
			self:GetActiveTab():SetText("generic")
			self.C.TabHolder:InvalidateLayout()
			
			if self.E2 then
				if not custom_default_code then template_load() end
				
				if custom_default_code then
					self:SetCode(custom_default_code)
					
					local current_editor = self:GetCurrentEditor()
					
					current_editor.Start = current_editor:MovePosition({1, 1}, 0)
					current_editor.Caret = current_editor:MovePosition({1, 1}, 0)
				else
					self:NewScriptX(true, ...)
					self:SetCode(self:GetCode() .. "\n\n#note from Pyrition\n#the custom new file script was not found\n#please make sure you have a file named _new_.txt")
				end
			else self:SetCode("") end
		end
	end
	
	global_panel_update("Expression2EditorFrame", function(is_panel, panel)
		if not panel.AutoSaveX then panel.AutoSaveX = panel.AutoSave end
		if not panel.NewScriptX then panel.NewScriptX = panel.NewScript end
		
		panel.NewScript = new_script
	end)
end

function template_load() custom_default_code = file.Read("expression2/_new_.txt", "DATA") end

local function template_path() end

--command structure
COMMAND.Description = "All commands related to Expression 2."
COMMAND.Realm = PYRITION_CLIENT

COMMAND.Tree = {
	--branch table
	editor = {
		--branch function, called by running "pyrition e2 editor test"
		template = {
			{Description = "Commands for controlling the template used for new scripts in the editor."},
			disable = template_disable,
			enable = template_enable,
			
			path = {
				function(self, arguments)
					
				end,
				
				{Description = "Set the file path relative to data/expression2/ for the template used by new scripts."}
			},
			
			reload = {
				template_load,
				{Description = "Reload the template file."}
			}
		}
	}
}

function COMMAND:Initialize()
	editor_control_table = vgui.GetControlTable("Expression2EditorFrame")
	
	if editor_control_table then template_enable() end
	
	return editor_control_table and true or false
end