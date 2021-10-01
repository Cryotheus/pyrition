function PANEL:AddPlayer(ply)
	local entry = vgui.Create("PyritionScoreboardEntry", self)
	
	entry:Dock(TOP)
	entry:DockMargin(4, 4, 4, 0)
	entry:SetPlayer(ply)
	entry:SetTall(96)
	
	return entry
end

function PANEL:Init()
	--add all players
	for index, ply in ipairs(player.GetAll()) do self:AddPlayer(ply) end
end

function PANEL:Paint(width, height)
	
end

function PANEL:PerformLayout(width, height) self:SizeToChildren(false, true) end

function PANEL:Think()
	
end

return "ScoreboardList", "Auto-scaling panel that containers PyritionScoreboardEntry panels.", "DSizeToContents"