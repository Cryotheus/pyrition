function PANEL:Init()
	self.PerformLayoutFrame = vgui.GetControlTable("DFrame").PerformLayout
	local parent = self:GetParent()
	local menu_bar = parent:Find("DMenuBar")
	
	if menu_bar then self:SetPos(parent:GetWide() - 160, menu_bar.y + menu_bar:GetTall())
	else self:SetPos(parent:GetWide() - 160, parent:GetTall() - 24) end
	
	self:SetSize(160, 24)
	self:SetTitle("Pyrition Menu")
	self.btnMaxim:SetEnabled(true)
	self.btnMinim:SetVisible(false)
	
	function self.btnMaxim:DoClick()
		local frame = self:GetParent()
		local menu_panel = frame.Menu
		frame.Menu = nil
		menu_panel.MenuMinimized = nil
		
		menu_panel:SetVisible(true)
		menu_panel:MakeContextMenuAttachedClickable()
		
		frame:Remove()
	end
end

function PANEL:OnRemove() if self.Menu then self.Menu:Remove() end end

--post
return "PyritionMenuMinimized", "!!!INTERNAL!!! Don't touch unless you know what you're doing!", "DFrame"