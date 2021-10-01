local groups = PYRITION.Groups
local groups_precedence = PYRITION.GroupsPrecedence

--pyrtion functions
function PYRITION:PyritionGroupCalculatePrecedence()
	local count = 0
	
	--mantain the same reference
	table.Empty(groups_precedence)
	
	--first make them a sequential table
	for key, group_info in pairs(groups) do
		count = count + 1
		
		table.insert(groups_precedence, key)
	end
	
	--sort by authority
	table.sort(groups_precedence, function(a, b) return groups[a].Authority > groups[b].Authority end)
	
	if SERVER then
		--make sure the initial sync is correct
		self.SyncHooks.Group.Initial.Groups = groups_precedence
		self.SyncHooks.Group.Initial.Max = count
	end
end

function PYRITION:PyritionGroupPlayerGet(ply)
	if IsValid(ply) then return ply:GetNWString("UserGroup")
	else return false end
end