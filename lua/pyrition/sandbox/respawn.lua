local respawn_delay = 0

--hooks
hook.Add("PlayerDeath", "PyritionSandboxRespawn", function(ply, inflictor, attacker)
	local id = "PyritionSandboxRespawn_" .. ply:EntIndex()
	
	hook.Add("PlayerDeathThink", id, function(ply)
		ply.NextSpawnTime = ply.DeathTime + respawn_delay
		
		hook.Remove("PlayerDeathThink", id)
	end)
end)

hook.Add("PlayerDisconnected", "PyritionSandboxRespawn", function(ply) hook.Remove("PlayerDeathThink", "PyritionSandboxRespawn_" .. ply:EntIndex()) end)
