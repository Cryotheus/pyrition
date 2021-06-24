--locals
local groups = {}

--globals
PYRITION.SyncHooks.Group = {
	--create a sync when a player loads in
	--[[
	Initial = {
		Iteration = 1,
		Key = "Group",
		Max = table.Count(groups)
	}, --]]
	
	--call the hook multiple times until it does not return true
	--this does not send multiple net messages
	Iterative = true,
	
	--merge the sync data creating a CRecipientFilter for all players targetted
	Merge = true,
	
	--prefixed by pyrition_
	NewtorkString = "group",
	
	--importance of this sync over others
	--console is 10
	--group is 20
	Priority = 20,
}

--pyrition functions
function PYRITION:PyritionSyncHookGroup(data, first) end
function PYRITION:PyritionSyncInitialGroup(data) end
function PYRITION:PyritionSyncSendingGroup(data, bytes_written) end

--hooks
--we'll take care of it ourselves
--also, we don't want to waste a network string
hook.Remove("PlayerInitialSpawn", "PlayerAuthSpawn")