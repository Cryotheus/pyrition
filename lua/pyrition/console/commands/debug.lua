COMMAND.Realm = PYRITION_SHARED

COMMAND.Tree = {
	function(self, ply, arguments, arguments_string)
		print("ran the absolute root: [" .. arguments_string .. "]")
		print(self, ply, arguments, arguments_string)
		PrintTable(arguments, 1)
	end,
	
	mirage = {
		function(self, ply, arguments, arguments_string)
			print("ran the mirage root: [" .. arguments_string .. "]")
			print(self, ply, arguments, arguments_string)
			PrintTable(arguments, 1)
		end,
		
		dust = function(self, ply, arguments, arguments_string)
			print("ran the dust command: [" .. arguments_string .. "]")
			print(self, ply, arguments, arguments_string)
			PrintTable(arguments, 1)
		end
	}
}