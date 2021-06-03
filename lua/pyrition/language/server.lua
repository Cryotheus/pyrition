util.AddNetworkString("pyrition_message")

--gamemode functions
function PYRITION:PyritionLanguageSend(target, enumeration, key)
	net.Start("pyrition_message")
	net.WriteUInt(enumeration - 1, 2)
	net.WriteString(key)
	
	if target then net.Send(target)
	else net.Broadcast() end
end

function PYRITION:PyritionLanguageSendFormat(target, enumeration, key, phrases)
	if not phrases then
		phrases = key
		key = key.key
	end
	
	net.Start("pyrition_message")
	net.WriteUInt(enumeration - 1, 2)
	net.WriteString(key)
	
	for tag, phrase in pairs(phrases) do
		net.WriteBool(true)
		net.WriteString(tag)
		net.WriteString(phrase)
	end
	
	if target then net.Send(target)
	else net.Broadcast() end
end