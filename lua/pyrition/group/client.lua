--locals
local groups = PYRITION.Groups
local groups_precedence = PYRITION.GroupsPrecedence
local rgba_to_digital, digital_to_rgba = include("pyrition/includes/digital_color.lua")

--pyrtion functions

--net
net.Receive("pyrition_group", function()
	repeat
		local group = net.ReadString()
		
		print("group sync! " .. group)
		
		if net.ReadBool() then
			local group_info = {
				Color = Color(digital_to_rgba(net.ReadUInt(32))),
				Authority = net.ReadUInt(16) --65535
			}
			
			if net.ReadBool() then --super admin?
				group_info.Administrator = true
				group_info.SuperAdministrator = true
			else group_info.Administrator = net.ReadBool() or nil end --admin?
			if net.ReadBool() then group_info.Parent = net.ReadString() end --parent?
			
			groups[group] = group_info
		else groups[group] = nil end
	until not net.ReadBool()
end)