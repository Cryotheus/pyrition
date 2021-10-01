local PLAYER = FindMetaTable("Player")

--locals
local fl_PLAYER_IsAdmin = PLAYER.IsAdminX_Pyrition or PLAYER.IsAdmin
local fl_PLAYER_IsSuperAdmin = PLAYER.IsSuperAdminX_Pyrition or PLAYER.IsSuperAdmin

--globals
PLAYER.IsAdminX_Pyrition = fl_PLAYER_IsAdmin
PLAYER.IsSuperAdminX_Pyrition = fl_PLAYER_IsSuperAdmin

--global functions
function PLAYER:IsAdmin()
	local group_info = PYRITION.Groups[self:GetUserGroup()]
	
	if group_info then return group_info.Administrator or false end
	
	return false
end

function PLAYER:IsSuperAdmin()
	local group_info = PYRITION.Groups[self:GetUserGroup()]
	
	if group_info then return group_info.SuperAdministrator or false end
	
	return false
end
