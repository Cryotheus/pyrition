COMMAND.Realm = PYRITION_MEDIATED

--local functions
local function valid_health(health)
	health = tonumber(health)
	
	if health then return math.Clamp(math.Round(health), 1, 2147483647) end
	
	return false
end

--command functions
function COMMAND:Execute(ply, arguments, arguments_string)
	if #arguments == 2 then
		local health = valid_health(arguments[2])
		
		if health then
			local players = hook.Call("PyritionPlayerFind", PYRITION, arguments[1], ply)
			
			if players then for index, ply in ipairs(players) do ply:SetHealth(health) end
			else self:Fail(ply, "No targets.\n") end
		else self:Fail(ply, "Invalid health quantity.\n") end
	elseif #arguments == 1 then
		if IsValid(ply) then
			local health = valid_health(arguments[1])
			
			if health then ply:SetHealth(health)
			else self:Fail(ply, "Invalid health quantity.\n") end
		else self:Fail(ply, "Invalid players can't set their health.\n") end
	end
end