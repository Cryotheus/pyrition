TOOL.Category = "Pyrition"
TOOL.Name = "Zone Designator"

--[[
	local function sign_triangle(alpha, bravo, charlie) return (alpha.x - charlie.x) * (bravo.y - charlie.y) - (bravo.x - charlie.x) * (alpha.y - charlie.y) end

	local function triangle_contains(point, alpha, bravo, charlie)
		local sign_echo = sign_triangle(point, alpha, bravo)
		local sign_foxtrot = sign_triangle(point, bravo, charlie)
		local sign_golf = sign_triangle(point, charlie, alpha)
		
		local negativity = sign_echo < 0 or sign_foxtrot < 0 or sign_golf < 0
		local positivity = sign_echo > 0 or sign_foxtrot > 0 or sign_golf > 0
		
		return not (negativity and positivity)
	end
]]

function TOOL:LeftClick(trace)
	if not trace.HitPos or IsValid(trace.Entity) and trace.Entity:IsPlayer() then return false end
	if CLIENT then return true end
	
	local ply = self:GetOwner()
	
	return true
end

function TOOL:Think() end
function TOOL.BuildCPanel(panel) print("Pyrition Zone Designator panel is", panel) end