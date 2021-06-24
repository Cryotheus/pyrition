--locals
local broadcast_bytes_spent = 0
local max_bytes = 256
local syncs_queued

--local functions

--post function set up

--[[
Console = {
	--create a sync when a player loads in
	Initial = true,
	
	--call the hook multiple times until it does not return true
	Iterative = true,
	
	--prefixed by pyrition_
	NewtorkString = "console",
	
	--should we create a sync per player or merge them all into one filter
	Single = true,
}
]]

--pyrition functions
function PYRITION:PyritionSyncHook(key, data)
	--returns two bools: completed, writable bytes remain
	print("PyritionSyncHook", key)
	PrintTable(data, 1)
	
	net.Start("pyrition_" .. self.SyncHooks[key].NewtorkString)
	
	if self.SyncHooks[key].Iterative then
		local first = true
		
		while hook.Call("PyritionSyncHook" .. key, self, data, first) and data.Iteration < data.Max do
			if net.BytesWritten() > max_bytes then return false, true end
			
			data.Iteration = data.Iteration + 1
			first = false
		end
	else
		print("odd sync perfomed as there is no non-iterative sync hook code")
		
		local returns = {hook.Call("PyritionSyncHook" .. key, self, data)}
		
		if returns[1] ~= nil then
			if returns[2] == nil then returns[2] = net.BytesWritten() end
			
			return unpack(returns)
		end
	end
	
	local bytes_written = net.BytesWritten()
	
	hook.Call("PyritionSyncSending" .. key, self, data, bytes_written)
	net.Send(data.Target)
	
	return true, bytes_written <= max_bytes
end

function PYRITION:PyritionSyncQueue(data)
	local key = data.Key
	local sync_info = self.SyncHooks[key]
	
	print("ITS ALL ABOUT HUMANITY")
	PrintTable(data, 1)
	
	if syncs_queued then
		if sync_info.Merge then --merge data of the two
			
		else --update an existing sync
			local target = data.Target
			
			for index, queued_sync_data in ipairs(syncs_queued) do
				if key == queued_sync_data.Key and target == queued_sync_data.Target then
					syncs_queued[index] = data
					
					break
				end
			end
		end
	else syncs_queued = {data} end --start the sync think
end

function PYRITION:PyritionSyncThink()
	while syncs_queued do
		local sync_queued = syncs_queued[1]
		local completed_hook, bytes_remain = hook.Call("PyritionSyncHook", self, sync_queued.Key, sync_queued)
		
		if completed_hook then
			table.remove(syncs_queued, 1)
			
			if table.IsEmpty(syncs_queued) then
				syncs_queued = nil
				
				break
			end
		end
		
		if not bytes_remain then break end
	end
end

--hooks
hook.Add("PyritionPlayerInitialized", "pyrition_sync", function(ply, emulated)
	for key, sync_info in pairs(PYRITION.SyncHooks) do
		local initial_sync = sync_info.Initial
		
		if initial_sync then
			local sync_hook = "PyritionSyncInitial" .. key
			
			initial_sync = table.Copy(initial_sync)
			initial_sync.Target = ply
			
			if PYRITION[sync_hook] and hook.Call(sync_hook, PYRITION, initial_sync) then hook.Call("PyritionSyncQueue", PYRITION, initial_sync) end
		end
	end
end)

hook.Add("Think", "pyrition_sync", function()
	if syncs_queued then hook.Call("PyritionSyncThink", PYRITION) end
end)