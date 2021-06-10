COMMAND.Realm = PYRITION_MEDIATED

COMMAND.Tree = {
	save = function(self, ply, arguments, arguments_string)
		local targets = hook.Call("PyritionPlayerFind", arguments_string, ply)
		
		if targets then
			for index, target in ipairs(targets) do hook.Call("PyritionPlayerStorageSave", PYRITION, target) end
			
			self:Success(ply, "Save player storage data.")
		else self:Fail(ply, "No targets found.") end
	end
}