if g_Scoreboard then --debug
	g_Scoreboard:Remove()
	g_Scoreboard = nil
end

--panel functions
function PANEL:Init()
	self:SetSize(ScrW(), ScrH())
	self:SetWorldClicker(true)
	
	--contents
	do --player list
		local player_list = vgui.Create("PyritionScoreboardList", self)
		
		self.PlayerList = player_list
	end
end

function PANEL:OnMousePressed(...) hook.Call("PyritionPanelScoreboardMousePressed", PYRITION, ...) end
function PANEL:OnMouseReleased(...) hook.Call("PyritionPanelScoreboardMouseReleased", PYRITION, ...) end

function PANEL:Paint(width, height)
	surface.SetDrawColor(255, 0, 0, 32)
	surface.DrawRect(0, 0, width, height)
end

function PANEL:PerformLayout(width, height)
	local player_list = self.PlayerList
	
	--set to a quarter of the screen's width and round down to an even number
	player_list:SetWide(math.floor(width * 0.125) * 2)
	player_list:Center()
end

function PANEL:Think() end

return "Scoreboard", "Scoreboard with a list of all players on the server.", "DPanel"