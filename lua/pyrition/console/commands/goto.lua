COMMAND.Realm = PYRITION_MEDIATED

function COMMAND:Execute(ply, arguments, arguments_string)
	if #arguments > 0 then
		local players = hook.Call("PyritionPlayerFind", PYRITION, arguments_string, ply)
		
		if #players > 1 then self:Fail("Too many targets.")
		elseif #players == 0 then self:Fail("No targets.")
		else
			
		end
	else self:Fail("You must specify a player.") end
end