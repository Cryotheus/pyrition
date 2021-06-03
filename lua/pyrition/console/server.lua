--pyrition functions
function PYRITION:PyritionCommandInitialized(command) if bit.band(command.Realm, PYRITION_CLIENT) > 0 then AddCSLuaFile(file_path) end end

--commands
concommand.Add("pyrition", function(...) hook.Call("PyritionCommandRun", PYRITION, ...) end, function(...) hook.Call("PyritionCommandComplete", PYRITION, ...) end, PYRITION:PyritionLanguageFormat("pyrition.command.help"))