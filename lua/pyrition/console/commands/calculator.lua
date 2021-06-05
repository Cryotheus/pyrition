--local variables
local color_algebra = Color(192, 192, 192)
local color_solution = Color(224, 224, 224)
local max_depth = 10
local unsolved = false

local operations_layers = {
	{
		["%^"] = function(left, right) return left ^ right end
	},
	
	{
		["%*"] = function(left, right) return left * right end,
		["%/"] = function(left, right) return left / right end,
		["%%"] = function(left, right) return left % right end
	},
	
	{
		["%+"] = function(left, right) return left + right end,
		["%-"] = function(left, right) return left - right end
	}
}

--local functions
local function calculate(expression, depth)
	if depth > max_depth then return false end
	
	local ok = true
	
	if string.find(expression, "%b()") then
		expression = string.gsub(expression, "%b()", function(text)
			local calculation = calculate(string.sub(text, 2, #text - 1), depth + 1)
			
			if calculation then return calculation end
			
			ok = calculation
			
			return "?"
		end)
		
		if not ok then goto sick_call end
	end
	
	for layer, operations in ipairs(operations_layers) do
		for operator_match, operation in pairs(operations) do
			local matcher = "%d+[%s" .. operator_match .. "]+%d+"
			
			while string.find(expression, matcher) do
				expression = string.gsub(expression, matcher, function(text)
					--matches here
					return tostring(operation(tonumber(string.match(text, "^%d+")), tonumber(string.match(text, "%d+$"))))
				end)
			end
		end
	end
	
	::sick_call::
	
	return ok and expression or ok
end

local function parse(text)
	--remove duplicate spaces
	text = string.gsub(text, "%s+", " ")
	
	--trim the spaces at start and end
	--should be replaced with the built in trim c functions in glua
	local text_from = string.match(text, "^%s*()")
	
	return text_from > #text and "" or string.match(text, ".*%S", text_from)
end

local function toggle(state)
	if state then
		hook.Add("OnPlayerChat", "chat_calculator", function(ply, text, team, dead)
			print(ply, text, team, dead)
			
			if string.Left(text, 1) == "=" then
				local algebra = parse(string.sub(text, 2))
				local calculation = calculate(algebra, 0)
				
				if calculation then
					timer.Simple(0, function()
						if unsolved then chat.AddText(color_algebra, "? " .. algebra) end
						
						chat.AddText(color_solution, "= " .. calculation)
					end)
				elseif calculation == false then
					timer.Simple(0, function()
						if unsolved then chat.AddText(color_algebra, "? " .. algebra) end
						
						chat.AddText(color_solution, "= an error: max parenthesis depth reached")
					end)
				end
			end
		end)
	else hook.Remove("OnPlayerChat", "chat_calculator") end
end

--command structure
COMMAND.Realm = PYRITION_CLIENT

COMMAND.Tree = {
	function(self, ply, arguments, arguments_string)
		local algebra = parse(arguments_string)
		
		if unsolved then MsgC(color_algebra, "? " .. algebra .. "\n") end
		
		MsgC(color_solution, calculate(algebra, 0) .. "\n")
	end,
	
	chat = {
		disable = function(self, ply, arguments, arguments_string) toggle(false) end,
		enable = function(self, ply, arguments, arguments_string) toggle(true) end,
		unsolved = function(self, ply, arguments, arguments_string) end
	}
}