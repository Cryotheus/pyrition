COMMAND.Realm = PYRITION_MEDIATED

function COMMAND:Execute(ply, arguments, arguments_string)
	if #arguments > 0 then
		local players = hook.Call("PyritionPlayerFind", PYRITION, arguments[1], ply)
		local reason = arguments[2]
		
		if players then for index, ply in ipairs(players) do ply:Kick(reason) end
		else self:Fail("No targets.") end
	else self:Fail("You must specify a player.") end
end