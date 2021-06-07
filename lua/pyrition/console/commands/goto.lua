COMMAND.Realm = PYRITION_MEDIATED

function COMMAND:Execute(ply, arguments, arguments_string)
	if #arguments > 0 then
		local players = hook.Call("PyritionPlayerFind", PYRITION, arguments_string, ply)
		
		if players then
			local player_count = #players
			
			if player_count > 1 then self:Fail(ply, "Too many targets.\n")
			elseif player_count == 0 then self:Fail(ply, "No targets.\n")
			else
				local destinations, destination_count = hook.Call("PyritionPlayerFindLanding", PYRITION, players[1], {ply})
				
				if destination_count == 1 then ply:SetPos(destinations[1])
				else self:Fail(ply, "Destination count is not 1. (" .. destination_count .. ")\n") end
			end
		else self:Fail(ply, "Failed to find a target.\n") end
	else self:Fail(ply, "You must specify a player.\n") end
end