--local variables
local enumerated_message_functions = {MsgC}

--setup
for hud_enum = 2, 4 do enumerated_message_functions[hud_enum] = function(text) LocalPlayer():PrintMessage(hud_enum, text) end end

--gamemode functions
function PYRITION:PyritionLanguageFormat(key, phrases)
	local text
	
	if phrases then text = language.GetPhrase(key)
	elseif istable(key) then
		text = language.GetPhrase(key.key)
		phrases.text = nil
	else return language.GetPhrase(key) end
	
	return string.gsub(text, "%[%:(.-)%]", phrases)
end

function PYRITION:PyritionLanguageMessage(enumeration, key, phrases, ...)
	local text = phrases and hook.Call("LanguageFormat", self, key, phrases) or language.GetPhrase(key)
	
	return enumerated_message_functions[enumeration](text, ...)
end

--net
net.Receive("pyrition_message", function()
	local enumeration = net.ReadUInt(2) + 1
	local key = net.ReadString()
	
	if net.ReadBool() then 
		local phrases = {}
		
		repeat phrases[net.ReadString()] = net.ReadString()
		until not net.ReadBool()
		
		hook.Call("LanguageMessage", GAMEMODE, enumeration, key, phrases)
	else hook.Call("LanguageMessage", GAMEMODE, enumeration, key) end
end)