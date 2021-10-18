COMMAND.Realm = PYRITION_CLIENT

if SERVER then return end

local add_function = PYRITION.Backup.halo_add or halo.Add
local hook_function = PYRITION.Backup.halo_hook or hook.GetTable().PostDrawEffects.RenderHalos
local halo_overriden = false

--localized functions
local istable = istable
local fl_math_Clamp = math.Clamp
local fl_table_insert = table.insert

--globals
PYRITION.Backup.halo_add = add_function
PYRITION.Backup.halo_hook = hook_function

--local functions
local function disable_halo_override(self)
	halo_overriden = false
	
	--global functions
	halo.Add = add_function
	
	--hooks
	hook.Add("PostDrawEffects", "RenderHalos", hook_function)
	hook.Call("PyritionConsoleVariableSet", PYRITION, self.Command, self, "halo_override", false)
end

local function enable_halo_override(self)
	halo_overriden = true
	
	--global functions
	function halo.Add(entities, color, blur_x, blur_y, passes, additive, ignore_z)
		if istable(entities) and #entities == 0 then
			local new_entities = {}
			
			for key, entity in pairs(entities) do fl_table_insert(new_entities, entity) end
			
			entities = new_entities
		end
		
		fl_table_insert(PYRITION.GFX.Halo, {
			r = fl_math_Clamp(color.r, 0, 255),
			g = fl_math_Clamp(color.g, 0, 255),
			b = fl_math_Clamp(color.b, 0, 255),
			a = fl_math_Clamp(color.a or 255, 0, 255),
			
			entities = istable(entities) and entities or {entities},
			ignore_z = ignore_z or nil
		})
	end
	
	--hooks
	hook.Call("PyritionConsoleVariableSet", PYRITION, self.Command, self, "halo_override", true)
	hook.Remove("PostDrawEffects", "RenderHalos")
end

--command structure
COMMAND.Tree = {
	override = {
		halo = {
			disable = disable_halo_override,
			enable = enable_halo_override
		}
	}
}

COMMAND.VariableMeta = {
	halo_override = {
		Default = true,
		TypeFlag = PYRITION_VARIABLE_BOOL
	}
}

--command functions
function COMMAND:VariablesInitialized(command_variables) if command_variables.halo_override then enable_halo_override(self) end end

--hooks
hook.Add("PyritionGFXOutlineHaloOverride", "PyritionConsoleCommandsOutline", function() if not halo_overriden then return true end end)