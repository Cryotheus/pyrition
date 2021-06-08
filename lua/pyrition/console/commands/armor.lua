COMMAND.Realm = PYRITION_MEDIATED

--local functions
local function valid_armor(armor)
	armor = tonumber(armor)
	
	if armor then return math.Clamp(math.Round(armor), 1, 2147483647) end
	
	return false
end

--command functions
function COMMAND:Execute(ply, arguments, arguments_string)
	if #arguments == 2 then
		local armor = valid_armor(arguments[2])
		
		if armor then
			local players = hook.Call("PyritionPlayerFind", PYRITION, arguments[1], ply)
			
			if players then for index, ply in ipairs(players) do ply:SetArmor(armor) end
			else self:Fail(ply, "No targets.\n") end
		else self:Fail(ply, "Invalid armor quantity.\n") end
	elseif #arguments == 1 then
		if IsValid(ply) then
			local armor = valid_armor(arguments[1])
			
			if armor then ply:SetArmor(armor)
			else self:Fail(ply, "Invalid armor quantity.\n") end
		else self:Fail(ply, "Invalid players can't set their armor.\n") end
	end
end