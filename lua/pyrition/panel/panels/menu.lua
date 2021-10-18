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
		
		function self.btnMaxim:DoClick()
			local parent = self:GetParent()
			
			if parent.Anchored then parent:DetachFromContextMenu()
			else
				parent.PreMaximizedX, parent.PreMaximizedY, parent.PreMaximizedWidth, parent.PreMaximizedHeight = parent:GetBounds()
				parent.Maximized = true
				
				parent:SetPos(0, 0)
				parent:SetDraggable(false)
				parent:SetSizable(false)
				parent:SetSize(ScrW(), ScrH())
			end
		end
		
		function self.btnMinim:DoClick()
			local parent = self:GetParent()
			
			if parent.Maximized then
				parent:SetPos(parent.PreMaximizedX, parent.PreMaximizedY)
				parent:SetDraggable(true)
				parent:SetSizable(true)
				parent:SetSize(parent.PreMaximizedWidth, parent.PreMaximizedHeight)
				
				parent.Maximized, parent.PreMaximizedX, parent.PreMaximizedY, parent.PreMaximizedWidth, parent.PreMaximizedHeight = false, nil, nil, nil, nil
			else
				if parent.Anchored then parent:MinimizeInContextMenu()
				else parent:AttachToContextMenu() end
			end
		end
	else
		self.btnMaxim:SetVisible(false)
		self.btnMinim:SetVisible(false)
	end
	
	do --property sheet
		local sheet = vgui.Create("DPropertySheet", self)
		
		sheet:Dock(FILL)
		--sheet:DockMargin(0, 0, 0, 0)
		
		--create a parent dpanel for all pages we will have
		--we do this so we only create the page panel if we open the tab, since some pages are $$$
		for page, page_data in pairs(PYRITION.Pages) do
			local panel = vgui.Create("DPanel", sheet)
			
			print(panel)
			print(sheet:AddSheet("#pyrition.menu.pages." .. page, panel, page_data.TabIcon, false, false, page_data.TabTooltip))
			
			panel.Page = page
			panel.PageName = page_data.Name
		end
		
		function sheet:OnActiveTabChanged(old_tab, new_tab)
			local old_panel, new_panel = old_tab:GetPanel(), new_tab:GetPanel()
			
			if old_panel and old_panel.PagePanel then old_panel.PagePanel:HolsterTab(new_panel, old_tab, new_tab) end
			
			if new_panel.PagePanel then
				new_panel.PagePanel:DeployTab(old_panel.PagePanel, old_tab, new_tab)
				
				return
			end
			
			print(old_panel, new_panel)
			print(new_panel.Page, new_panel.PageName)
			
			local page = vgui.Create(new_panel.PageName, new_panel)
			
			page:Dock(FILL)
			
			new_panel.PagePanel = page
		end
		
		do --create the first page
			local active_panel = sheet:GetActiveTab():GetPanel()
			local page = vgui.Create(active_panel.PageName, active_panel)
			
			page:Dock(FILL)
			
			active_panel.PagePanel = page
		end
		
		self.PropertySheet = sheet
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

function PANEL:OnRemove() hook.Remove("ContextMenuOpened", self) end
function PANEL:PerformLayout(width, height) self:PerformLayoutFrame(width, height) end

--post
return "PyritionMenu", "Menu for Pyrition.", "DFrame"