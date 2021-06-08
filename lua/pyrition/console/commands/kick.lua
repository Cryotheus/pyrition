COMMAND.Realm = PYRITION_MEDIATED

function COMMAND:Execute(ply, arguments, arguments_string)
	if #arguments > 0 then
		print("mmm", ply, arguments_string, 1)
		PrintTable(arguments)
		
		local players = hook.Call("PyritionPlayerFind", PYRITION, arguments[1], ply)
		local reason = arguments[2]
		
		if players then for index, ply in ipairs(players) do ply:Kick(reason) end
		else self:Fail(ply, "No targets.") end
	else self:Fail(ply, "You must specify a player.") end
end