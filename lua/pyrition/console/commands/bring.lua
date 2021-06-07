COMMAND.Realm = PYRITION_MEDIATED

function COMMAND:Execute(ply, arguments, arguments_string)
	if #arguments > 0 then
		local targets = hook.Call("PyritionPlayerFind", PYRITION, arguments_string, ply)
		
		if targets then
			local destinations, destination_count = hook.Call("PyritionPlayerFindLanding", PYRITION, ply, targets)
			local target_count = #targets
			
			if destination_count == target_count then for index, target in ipairs(targets) do target:SetPos(destinations[index]) end
			else self:Fail(ply, "Destination count does not match player count. (" .. destination_count .. " ~= " .. target_count .. ")\n") end
		else self:Fail(ply, "Failed to find a target.\n") end
	else self:Fail(ply, "You must specify a player.\n") end
end