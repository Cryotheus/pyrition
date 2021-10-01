function PANEL:Init()
	self:DockPadding(4, 4, 4, 4)
	
	do --avatar
		local avatar_panel = vgui.Create("PyritionAvatar", self)
		
		avatar_panel:Dock(LEFT)
		
		self.AvatarPanel = avatar_panel
	end
	
	do --name label
		local label = vgui.Create("DLabel", self)
		
		label:Dock(FILL)
		label:DockMargin(4, 0, 0, 0)
		label:SetFont("Trebuchet24")
		label:SetText("unknown")
		
		self.Label = label
	end
end

function PANEL:PerformLayout(width, height)
	local avatar_panel = self.AvatarPanel
	
	--fix the avatar panel to a 1:1 ratio
	--since this panel is docked to the LEFT, it will freely stretch its height but not width
	avatar_panel:SetWide(avatar_panel:GetTall())
end

function PANEL:SetPlayer(ply)
	self.Player = ply
	
	if ply:GetName() == "unconnected" then
		--we need to do something
		print("thats not good!", ply, IsValid(ply), ply:Team(), ply:IsConnected())
	end
	
	self.AvatarPanel:SetPlayer(ply)
	self.Label:SetText(ply:Name())
end

return "ScoreboardEntry", "A player's entry in the scoreboard.", "DPanel"