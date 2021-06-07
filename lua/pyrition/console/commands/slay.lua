COMMAND.Realm = PYRITION_MEDIATED

function COMMAND:Execute(ply, arguments, arguments_string)
	if #arguments_string > 0 then
		local players = hook.Call("PyritionPlayerFind", PYRITION, arguments_string, ply)
		
		if players then for index, ply in ipairs(players) do ply:Kill() end
		else self:Fail("No targets.") end
	else
		if IsValid(ply) then ply:Kill()
		else self:Fail("Invalid players can't commit suicide.") end
	end
end