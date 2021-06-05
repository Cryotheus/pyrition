--pyrition functions
function PYRITION:PyritionClientInitialized(ply)
	print("PyritionClientInitialized ran")
	
	timer.Simple(0.2, function()
		print("PyritionClientInitialized timer ran")
		
		net.Start("pyrition_initialize")
		net.SendToServer()
	end)
end

--hooks
hook.Add("InitPostEntity", "pyrition", function()
	--
	print("InitPostEntity ran")
	
	hook.Call("PyritionClientInitialized", PYRITION, LocalPlayer())
end)