--todo: make this scoreboard a gamemode extension when we the extension loader
local closed_context_menu = false
local context_menu_button

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
	
	--scoreboard:InvalidateLayout(true)
	
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
hook.Add("OnContextMenuClose", "PyritionPanelScoreboard", function()
	if closed_context_menu then return end
	
	context_menu_button = nil
end)

hook.Add("ContextMenuOpen", "PyritionPanelScoreboard", function()
	if IsValid(g_Scoreboard) and g_Scoreboard:IsVisible() and not (closed_context_menu and context_menu_button and input.IsKeyDown(context_menu_button)) then
		closed_context_menu = true
		
		return false
	end
end)

hook.Add("PlayerBindPress", "PyritionPanelScoreboard", function(ply, bind, pressed, code) if bind == "+menu_context" then context_menu_button = code end end)

hook.Add("PreventScreenClicks", "PyritionPanelScoreboard", function()
	if IsValid(g_Scoreboard) and g_Scoreboard:IsVisible() then
		local panel = vgui.GetHoveredPanel()
		
		if IsValid(panel) then
			if panel == g_Scoreboard then return true end

			while IsValid(panel:GetParent()) do
				panel = panel:GetParent()
				
				if panel == g_Scoreboard then return true end
			end
		else return true end --for when the cursor is outside of the game's window
	end
end)

hook.Add("ScoreboardHide", "PyritionPanelScoreboard", function()
	if closed_context_menu then
		if context_menu_button and input.IsKeyDown(context_menu_button) then
			RememberCursorPosition()
			hook.Call("OnContextMenuOpen", GAMEMODE)
		else context_menu_button = nil end
		
		closed_context_menu = false
	end
end)

hook.Add("ScoreboardShow", "PyritionPanelScoreboard", function()
	local scoreboard = g_Scoreboard
	
	--create the scoreboard if there isn't one
	if IsValid(scoreboard) then
		scoreboard:MakePopup()
		scoreboard:SetKeyboardInputEnabled(false)
		scoreboard:Show()
	else hook.Call("PyritionPanelScoreboardCreate", PYRITION, true) end
	
	--we don't want to have both the scoreboard and context menu at the same time
	--the system I have set up will make the scoreboard take precedence
	if g_ContextMenu:IsVisible() then
		closed_context_menu = true
		
		hook.Call("OnContextMenuClose", GAMEMODE)
	end
	
	--we don't want the old scoreboard
	return true
end)

hook.Remove("HUDPaint", "PyritionPanelScoreboard")
--[[
hook.Add("HUDPaint", "PyritionPanelScoreboard", function()
	draw.SimpleText(context_menu_button and tostring(context_menu_button) or ".", "DermaLarge", ScrW() * 0.5, ScrH() * 0.25, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end) --]]

--post
if g_Scoreboard then hook.Call("PyritionPanelScoreboardCreate", PYRITION) end