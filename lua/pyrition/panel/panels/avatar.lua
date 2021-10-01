local avatar_sizes = {184, 128, 84, 64, 32, 16}
local glint_fraction
local glint_fraction_offset = -0.03
local glint_offset = 3
local glint_offset_half = glint_offset * 0.5
local glint_percent
local glint_period = 2
--local glint_power = 1 --used for a more advanced form of the glint_fraction equation
local glint_speed = 0.75
local last_updated_frame
local PANEL = {}
local pi = math.pi
local tau = 2 * pi

--colors
local associated_colors = PYRITION.Colors.Panel.Avatar
local color_alive = associated_colors.Alive
local color_dead = associated_colors.Dead

--panel functions
function PANEL:CalculateGlintPoly(width, height, fraction, glint_scale)
	local glint_height, glint_width = height * glint_scale, width * glint_scale
	local glint_height_half, glint_width_half = glint_height * 0.5, glint_width * 0.5
	local inverted_fraction = 1 - fraction
	
	local offset_x, offset_y = width * inverted_fraction * glint_offset - width * glint_offset_half, height * fraction * glint_offset - height * glint_offset_half
	
	--we don;t really need the two spiked corners now that I'm using the half sizes to cover the whole square
	local glint_poly = {
		--[[{
			x = offset_x - glint_width_half,
			y = offset_y - glint_height_half
		},]]
		
		{
			x = offset_x + glint_width_half,
			y = offset_y - glint_height_half
		},
		
		{
			x = offset_x + width + glint_width_half,
			y = offset_y + height - glint_height_half
		},
		
		--[[{
			x = offset_x + width + glint_width_half,
			y = offset_y + height + glint_height_half
		},]]
		
		{
			x = offset_x + width - glint_width_half,
			y = offset_y + height + glint_height_half
		},
		
		{
			x = offset_x - glint_width_half,
			y = offset_y + glint_height_half
		}
	}
	
	self.GlintPoly = glint_poly
end

function PANEL:Init()
	self.Glint = false
	self.AliveColor = table.Copy()
	self.DeadColor = table.Copy(color_dead)
	
	do --avatar
		local avatar = vgui.Create("AvatarImage", self)
		
		avatar:Dock(FILL)
		avatar:DockMargin(2, 2, 2, 2)
		
		self.AvatarImage = avatar
	end
	
	do --cover panel
		local cover = vgui.Create("DPanel", self)
		local parent_panel = self
		
		cover:Dock(FILL)
		cover:SetVisible(false)
		
		function cover:Paint(width, height) parent_panel.PaintGlint(self, parent_panel, width, height) end
		
		self.CoverPanel = cover
	end
end

function PANEL:Paint(width, height)
	surface.SetDrawColor(IsValid(self.Player) and self.Player:Alive() and self.AliveColor or self.DeadColor)
	surface.DrawRect(0, 0, width, height)
end

function PANEL:PaintGlint(true_self, width, height)
	if true_self.Glint then
		--only update the glint poly once per frame
		if last_updated_frame ~= FrameNumber() then
			last_updated_frame = FrameNumber()
			glint_percent = math.min((RealTime() * glint_speed + glint_fraction_offset) % glint_period, 1)
			local real_time_tau = glint_percent * tau
			
			--local glint_fraction = 1 - (RealTime() % 1 - 0.5) ^ 2 * 4
			--put that math degree to use
			--glint_fraction = (((math.sin(real_time_tau) + real_time_tau) / tau) ^ glint_power + glint_fraction_offset) % 1
			glint_fraction = ((math.sin(real_time_tau) + real_time_tau) / tau + glint_fraction_offset) % 1
			--glint_fraction = (math.sin(real_time_tau) + real_time_tau) / tau
			
			true_self:CalculateGlintPoly(
				width,
				height,
				glint_fraction,
				0.35 - math.sin(glint_percent * pi) ^ 3 * 0.2
			)
		end
		
		local color = true_self.GlintColor
		
		draw.NoTexture()
		surface.SetDrawColor(color.r, color.g, color.b, math.sin(glint_percent * pi) ^ 5 * 128)
		surface.DrawPoly(true_self.GlintPoly)
	end
end

function PANEL:PerformLayout(width, height) self:UpdateAvatar(math.max(width, height)) end

function PANEL:SetGlint(color)
	self.Glint = true
	self.GlintColor = color
	
	self.CoverPanel:SetVisible(true)
end

function PANEL:SetPlayer(ply)
	local glint_color = hook.Run("PyritionCredationGetGlint", ply)
	self.Player = ply
	
	if glint_color then self:SetGlint(glint_color) end
	--if alive_color then self.AliveColor = alive_color end
	
	self:UpdateAvatar()
end

function PANEL:UpdateAvatar(size)
	size = size or math.max(self:GetSize())
	
	--updates the avatar image to something that won't have large amounts of minification filtering
	if self.Player then
		for index, avatar_size in ipairs(avatar_sizes) do if size <= avatar_size then return self.AvatarImage:SetPlayer(self.Player, avatar_size) end end
		
		self.AvatarImage:SetPlayer(self.Player, 16)
	end
end

--post
return "Avatar", "A player's avatar for general usage.", "DPanel"