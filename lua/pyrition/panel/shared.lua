--concommands
concommand.Add("pyrition_reload_panels", function(ply, command, arguments, arguments_string) hook.Call("PyritionPanelLoad", PYRITION, "pyrition/panel/panels/") end, nil, "Reload all Pyrition panels.")

--hooks
hook.Call("PyritionPanelLoad", PYRITION, "pyrition/panel/panels/")