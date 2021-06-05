local delay = 3

COMMAND.Realm = PYRITION_MEDIATED
COMMAND.Tree = {
	cleanup = {
		function(self, ply, arguments, arguments_string)
			local players = hook.Call("PyritionPlayersFind", PYRITION, arguments_string, ply)
			
			if players then for index, ply in ipairs(players) do ply:SendLua("game.CleanUpMap()") end
			else self:Fail("No targets.") end
		end,
		
		map = function(self, ply, arguments, arguments_string) game.CleanUpMap() end
	},
	
	reload = {
		instance = function(self, ply, arguments, arguments_string)
			hook.Call("PyritionLanguageSend", PYRITION, nil, HUD_PRINTTALK, "pyrition.bakse_confirmation.instance")
			
			timer.Simple(delay, function() engine.CloseServer() end)
		end,
		
		map = {
			function(self, ply, arguments, arguments_string)
				hook.Call("PyritionLanguageSend", PYRITION, nil, HUD_PRINTTALK, "pyrition.bakse_confirmation.map")
				
				timer.Simple(delay, function() RunConsoleCommand("changelevel", game.GetMap()) end)
			end,
			
			force = function(self, ply, arguments, arguments_string)
				hook.Call("PyritionLanguageSend", PYRITION, nil, HUD_PRINTTALK, "pyrition.bakse_confirmation.map.force")
				
				timer.Simple(delay, function() RunConsoleCommand("map", game.GetMap()) end)
			end
		}
	}
}