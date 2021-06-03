--Cryotheum#4096
--https://github.com/Cryotheus/preconfigured_loader
--intent: replace ulib, ulx, utime, etc.
--status: active
--motivation: pure rage and anger over the sanctuary sandbox server
PYRITION = {
	Commands = {}
}

PYRITION_CLIENT = 1
PYRITION_SERVER = 2
PYRITION_SHARED = bit.band(PYRITION_CLIENT, PYRITION_SERVER)

--config
local config = {
	console = {
		client = 21,	--10 101
		shared = 15,	--01 111
		server = 18		--10 010
	},
	
	language = {
		client = 5,	--0 101
		server = 2		--0 010
	}
}

--what do we say we are when we load up?
local branding = "Pyrition"

--maximum amount of folders it may go down in the config tree
local max_depth = 4

--reload command
local reload_command = "pyrition_reload"

--colors
local color_generic = Color(255, 255, 255)
local color_significant = Color(255, 128, 0)

--end of configurable variables



----local variables, don't change
	local fl_bit_band = bit.band
	local fl_bit_rshift = bit.rshift
	local highest_priority = 0
	local load_order = {}
	local load_functions = {
		[1] = function(path) if CLIENT then include(path) end end,
		[2] = function(path) if SERVER then include(path) end end,
		[4] = function(path) if SERVER then AddCSLuaFile(path) end end
	}
	
	local load_function_shift = table.Count(load_functions)

--local functions
local function construct_order(config_table, depth, path)
	local tabs = " ]" .. string.rep("    ", depth)
	
	for key, value in pairs(config_table) do
		if istable(value) then
			MsgC(color_generic, tabs .. key .. ":\n")
			
			if depth < max_depth then construct_order(value, depth + 1, path .. key .. "/")
			else MsgC(color_significant, tabs .. "    !!! MAX DEPTH !!!\n") end
		else
			MsgC(color_generic, tabs .. key .. " = 0d" .. value .. "\n")
			
			local priority = fl_bit_rshift(value, load_function_shift)
			local script_path = path .. key
			
			if priority > highest_priority then highest_priority = priority end
			if load_order[priority] then load_order[priority][script_path] = fl_bit_band(value, 7)
			else load_order[priority] = {[script_path] = fl_bit_band(value, 7)} end
		end
	end
end

local function load_by_order()
	for priority = 0, highest_priority do
		local script_paths = load_order[priority]
		
		if script_paths then
			if priority == 0 then MsgC(color_generic, " Loading scripts at level 0...\n")
			else MsgC(color_generic, "\n Loading scripts at level " .. priority .. "...\n") end
			
			for script_path, bits in pairs(script_paths) do
				local script_path_extension = script_path .. ".lua"
				
				MsgC(color_generic, " ]    0d" .. bits .. "	" .. script_path_extension .. "\n")
				
				for bit_flag, func in pairs(load_functions) do if fl_bit_band(bits, bit_flag) > 0 then func(script_path_extension) end end
			end
		else MsgC(color_significant, "Skipping level " .. priority .. " as it contains no scripts.\n") end
	end
end

local function load_scripts(command_reload)
	MsgC(color_generic, "\n\\\\\\ ", color_significant, branding, color_generic, " ///\n\n", color_significant, "Constructing load order...\n")
	construct_order(config, 1, "")
	MsgC(color_significant, "\nConstructed load order.\n\nLoading scripts by load order...\n")
	load_by_order()
	MsgC(color_significant, "\nLoaded scripts.\n\n", color_generic, "/// ", color_significant, "All scripts loaded.", color_generic, " \\\\\\\n\n")
end

--concommands
concommand.Add(reload_command, function(ply)
	--is it possible to run a command from client and execute the serverside command when the command is shared?
	if not IsValid(ply) or ply:IsSuperAdmin() or IsValid(LocalPlayer()) and ply == LocalPlayer() then
		--put what you need before reloading here
		load_scripts(true)
		--put what you need after reloading here
	end
end, nil, "Reload all " .. branding .. " scripts.")

--post function setup
load_scripts(false)