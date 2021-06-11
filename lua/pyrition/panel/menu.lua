local PANEL = {}

--panel functions
function PANEL:AttachToContextMenu()
	self.Anchored = true
	
	self:SetParent(g_ContextMenu)
	
	--if we have the context menu already open, we'll need to do this since we missed the hook
	if g_ContextMenu:IsVisible() then self:MakeContextMenuAttachedClickable() end
	
	hook.Add("ContextMenuOpened", self, function() self:MakeContextMenuAttachedClickable() end)
end

function PANEL:DetachFromContextMenu()
	if self.MenuMinimized then return end
	
	self.Anchored = false
	
	self:SetParent(vgui.GetWorldPanel())
	self:MakePopup()
	
	hook.Remove("ContextMenuOpened", self)
end

function PANEL:Init()
	local frame_table = vgui.GetControlTable("DFrame")
	self.PerformLayoutFrame = frame_table.PerformLayout
	
	self:SetDraggable(true)
	self:SetMinimumSize(512, 288)
	self:SetSizable(true)
	self:SetTitle("Pyrition Menu")
	
	--if we got one of these, then make use of the min and max buttons
	if g_ContextMenu then
		self.btnMaxim:SetEnabled(true)
		self.btnMinim:SetEnabled(true)
		
		function self.btnMaxim:DoClick() self:GetParent():DetachFromContextMenu() end
		
		function self.btnMinim:DoClick()
			local parent = self:GetParent()
			
			if parent.Anchored then parent:MinimizeInContextMenu()
			else parent:AttachToContextMenu() end
		end
	else
		self.btnMaxim:SetVisible(false)
		self.btnMinim:SetVisible(false)
	end
end

function PANEL:MakeContextMenuAttachedClickable()
	--we have to do it like this because of some functionality that is performed inside makepopup that is not in SetMouseInputEnabled
	local panel = self.MenuMinimized or self
	local parent = self:GetParent()
	local x, y = panel:GetPos()
	
	panel:MakePopup()
	panel:SetKeyboardInputEnabled(false)
	panel:SetPos(math.Clamp(x, 0, parent:GetWide() - panel:GetWide()), math.Clamp(y, 0, parent:GetTall() - panel:GetTall()))
end

function PANEL:MinimizeInContextMenu()
	if self.MenuMinimized then print("already got", self.MenuMinimized) return end
	
	local menu_minimized = vgui.Create("PyritionMenuMinimized", g_ContextMenu)
	
	menu_minimized.Menu = self
	self.MenuMinimized = menu_minimized
	
	self:SetMouseInputEnabled(false)
	self:SetVisible(false)
end

function PANEL:PerformLayout(width, height) self:PerformLayoutFrame(width, height) end

--post
derma.DefineControl("PyritionMenu", "Menu for Pyrition.", PANEL, "DFrame")