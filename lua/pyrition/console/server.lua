--pyrition functions
function PYRITION:PyritionCommandInitialized(command)
    if bit.band(command.Realm, PYRITION_CLIENT) > 0 then AddCSLuaFile(file_path) end
    if bit.band(command.Realm, PYRITION_SERVER) > 0 then return true end
    
    return false
end

--commands
concommand.Add("pyrition", function(...) hook.Call("PyritionCommandRun", PYRITION, ...) end)