--locals
local broadcast_bytes_spent = 0
local max_bytes = 256
local syncs_queued

--colors
local color_generic = Color(255, 255, 255)
local color_significant = Color(255, 128, 0)

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
	net.Start("pyrition_" .. self.SyncHooks[key].NewtorkString)
	
	if self.SyncHooks[key].Iterative then
		local passes = 0
		
		--update the passes if we have a number return
		local function call_sync_hook()
			local hook_return = hook.Call("PyritionSyncHook" .. key, self, data, passes)
			
			if isnumber(hook_return) then passes = hook_return end
			
			return hook_return
		end
		
		--call it until we write enough or reached the max iterations
		while call_sync_hook() and data.Iteration < data.Max do
			if net.BytesWritten() > max_bytes then return false, true end
			
			data.Iteration = data.Iteration + 1
			passes = passes + 1
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
	local target = data.Target
	
	--if there is nothing, don't queue a sync
	if data.Iterative and data.Iteration > data.Max or data.Max == 0 then return end
	
	if istable(target) then --convert target tables into filters
		local filter = RecipientFilter()
		
		for index, ply in ipairs(target) do filter:AddPlayer(ply) end
		
		data.Target = filter
		target = filter
	end
	
	if syncs_queued then
		if sync_info.Merge then --merge targets of the two, and then their data
			--queued_sync_data.Target
			for index, queued_sync_data in ipairs(syncs_queued) do
				if key == queued_sync_data.Key then
					if target == queued_sync_data.Target then syncs_queued[index] = data
					else
						--this can only be a player or a CRecipientFilter
						local queued_target = queued_sync_data.Target
						
						if type(queued_target) == "CRecipientFilter" then --it's already a filter, merge that shit
							if type(target) == "CRecipientFilter" then for index, ply in ipairs(target:GetPlayers()) do queued_target:AddPlayer(ply) end
							elseif istable(target) then for index, ply in ipairs(target) do queued_target:AddPlayer(ply) end
							else queued_target:AddPlayer(target) end
						else --its a player, change it to a filter now
							local filter
							
							if type(target) == "CRecipientFilter" then --just add the existing target to the provided filter
								filter = target
								
								target:AddPlayer(queued_target)
								
								for index, ply in ipairs(target:GetPlayers()) do filter:AddPlayer(ply) end
							elseif istable(target) then --add all players in table to filter
								filter = RecipientFilter()
								
								filter:AddPlayer(queued_target)
								
								for index, ply in ipairs(target) do filter:AddPlayer(ply) end
							else --create a filter with both players
								filter = RecipientFilter()
								
								filter:AddPlayer(queued_target)
								filter:AddPlayer(target)
							end
							
							queued_sync_data.Target = filter
						end
						
						data.Target = nil
						syncs_queued[index] = table.Merge(queued_sync_data, data)
					end
					
					return
				end
			end
			
			--we should do priorities
			table.insert(syncs_queued, data)
		else --update an existing sync
			local target = data.Target
			
			for index, queued_sync_data in ipairs(syncs_queued) do
				if key == queued_sync_data.Key and target == queued_sync_data.Target then
					syncs_queued[index] = data
					
					return
				end
			end
			
			--we should do priorities
			table.insert(syncs_queued, data)
		end
	else syncs_queued = {data} end --start the sync think
end

function PYRITION:PyritionSyncThink()
	while syncs_queued do
		local sync_queued = syncs_queued[1]
		local completed_hook, bytes_remain = hook.Call("PyritionSyncHook", self, sync_queued.Key, sync_queued)
		
		if completed_hook then --if we are done with this sync hook, remove it from the queue
			table.remove(syncs_queued, 1)
			
			if table.IsEmpty(syncs_queued) then
				syncs_queued = nil
				
				break
			end
		end
		
		--if we run out of bytes, wait for the next think
		if not bytes_remain then break end
	end
end

--hooks
hook.Add("Initialize", "pyrition_sync", function()
	MsgC(color_significant, "\nGenerating network strings...\n")
	
	for key, sync_info in pairs(PYRITION.SyncHooks) do
		local network_string = sync_info.NewtorkString
		
		util.AddNetworkString("pyrition_" .. network_string)
		MsgC(color_generic, " ]    ", key, ": pyrition_", network_string, "\n")
	end
	
	MsgC(color_significant, "\nSync hook network strings added.\n\n")
end)

hook.Add("PyritionPlayerInitialized", "pyrition_sync", function(ply, emulated)
	for key, sync_info in pairs(PYRITION.SyncHooks) do
		local initial_sync = sync_info.Initial
		
		print("checking for initial sync on " .. key .. ", found", initial_sync)
		
		if initial_sync then
			initial_sync = table.Copy(initial_sync)
			initial_sync.Target = ply
			
			hook.Call("PyritionSyncInitial" .. key, PYRITION, initial_sync)
			hook.Call("PyritionSyncQueue", PYRITION, initial_sync)
		end
	end
end)

hook.Add("Think", "pyrition_sync", function() if syncs_queued then hook.Call("PyritionSyncThink", PYRITION) end end)