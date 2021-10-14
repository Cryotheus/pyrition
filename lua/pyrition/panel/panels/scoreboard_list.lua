function PANEL:AddPlayer(ply)
	local entry = vgui.Create("PyritionScoreboardEntry", self)
	
	entry:Dock(TOP)
	entry:DockMargin(4, 4, 4, 0)
	entry:SetPlayer(ply)
	entry:SetTall(96)
	
	self.PlayerCount = self.PlayerCount + 1
	self.Players[ply] = entry
	
	return entry
end

function PANEL:CleanupPlayers()
	--remove players that are not connected
	local new_player_count = 0
	local players = self.Players
	
	for ply, entry in pairs(players) do
		if not IsValid(ply) then
			players[ply] = nil
			
			entry:Remove()
		else new_player_count = new_player_count + 1 end
	end
	
	self.PlayerCount = new_player_count
end

function PANEL:Init()
	self.PlayerCount = 0
	self.Players = {}
	
	--add all players
	for index, ply in ipairs(player.GetAll()) do self:AddPlayer(ply) end
	
	--do the layout now so we dont look like shit the first frame
	self:InvalidateLayout(true)
end

function PANEL:Paint(width, height)
	
end

function PANEL:PerformLayout(width, height) self:SizeToChildren(false, true) end

function PANEL:Think()
	local player_count = player.GetCount()
	
	if player_count ~= self.PlayerCount then
		local players = self.Players
		
		self:CleanupPlayers()
		
		--add missing players
		for index, ply in ipairs(player.GetAll()) do if not players[ply] then self:AddPlayer(ply) end end
	end
end

return "ScoreboardList", "Auto-scaling panel that containers PyritionScoreboardEntry panels.", "DSizeToContents"