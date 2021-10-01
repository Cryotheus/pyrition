--local functions
local function get_world_clicker_entity(eye_position, direction, range)
	local local_player = LocalPlayer()
	local eye_position = EyePos()
	local filter = local_player:GetViewEntity()
	
	if filter == local_player then
		local vehicle = local_player:GetVehicle()
		
		--we can directly use the method for IsValid as the GetVehicle method always returns an entity userdata
		if vehicle:IsValid() and not vehicle:GetThirdPersonMode() then
			--phys_bone_follower filter is a dirty hack for prop_vehicle_crane
			filter = {filter, vehicle, unpack(ents.FindByClass("phys_bone_follower"))}
		end
	end
	
	return util.TraceLine{
		endpos = eye_position + direction * range,
		filter = filter,
		start = eye_position
	}.Entity
end

--pyrition functions
function PYRITION:PyritionPanelScoreboardCreate(show)
	if g_Scoreboard then g_Scoreboard:Remove() end
	
	local scoreboard = vgui.Create("PyritionScoreboard", GetHUDPanel())
	
	if show then
		scoreboard:MakePopup()
		scoreboard:SetKeyboardInputEnabled(false)
	else scoreboard:Hide() end
	
	g_Scoreboard = scoreboard
end

function PYRITION:PyritionPanelScoreboardMousePressed(code)
	local direction = gui.ScreenToVector(gui.MousePos())
	
	print("PyritionPanelScoreboardMousePressed: " .. tostring(get_world_clicker_entity(EyePos(), direction, 1024)))
end

function PYRITION:PyritionPanelScoreboardMouseReleased(code)
	local direction = gui.ScreenToVector(gui.MousePos())
	
	print("PyritionPanelScoreboardMouseReleased: " .. tostring(get_world_clicker_entity(EyePos(), direction, 1024)))
end

--hooks
hook.Add("PreventScreenClicks", "PyritionPanelScoreboard", function()
	if g_Scoreboard:IsVisible() then
		local panel = vgui.GetHoveredPanel()
		
		if IsValid(panel) then
			if panel == g_Scoreboard then return true end

			while IsValid(panel:GetParent()) do
				panel = panel:GetParent()
				
				if panel == g_Scoreboard then return true end
			end
		else return true end --for when the cursor is outside of the game's window, there can be potential edge cases here
	end
end)

hook.Add("ScoreboardShow", "PyritionPanelScoreboard", function()
	local scoreboard = g_Scoreboard
	
	if IsValid(scoreboard) then
		scoreboard:MakePopup()
		scoreboard:SetKeyboardInputEnabled(false)
		scoreboard:Show()
	else hook.Call("PyritionPanelScoreboardCreate", PYRITION, true) end
	
	return true
end)

--post
if g_Scoreboard then hook.Call("PyritionPanelScoreboardCreate", PYRITION) end