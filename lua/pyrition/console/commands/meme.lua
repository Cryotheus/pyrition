COMMAND.Realm = PYRITION_CLIENT

if SERVER then return end

local meme_active
local meme_props = {}
local meme_rate = 1
local meme_text = {"First text", "Second Text"}

local meme_enjoyer_header = 0.15
local meme_enjoyer_squeeze = 0.8
local meme_enjoyer_materials = {
	Material("pyrition/memes/enjoyer/contemplate.png"), --scroll to the left
	Material("pyrition/memes/enjoyer/standing.png"), --scroll down
	Material("pyrition/memes/enjoyer/smile.png"), --scroll to the right
	Material("pyrition/memes/enjoyer/joker.png"), --scroll up
	nil
}

local meme_enjoyer_material_scrolls = {
	{1.2,	{0, 0},		{-0.1, 0}}, --scroll to the left
	{3,		{0, 0.2},	{0, 0.15}}, --scroll down
	{1,		{0, 0},		{0.1, 0}}, --scroll to the right
	{1.4,	{0, 0},		{0, 0.1}} --scroll up
}

----localized functions
	local fl_cam_End2D = cam.End2D
	local fl_cam_Start2D = cam.Start2D
	local fl_draw_SimpleText = draw.SimpleText
	local fl_math_ceil = math.ceil
	local fl_math_floor = math.floor
	local fl_math_max = math.max
	local fl_math_min = math.min
	local fl_render_ClearDepth = render.ClearDepth
	local fl_render_ClearStencil = render.ClearStencil
	local fl_render_RenderView = render.RenderView
	local fl_render_SetStencilCompareFunction = render.SetStencilCompareFunction
	local fl_render_SetStencilEnable = render.SetStencilEnable
	local fl_render_SetStencilFailOperation = render.SetStencilFailOperation
	local fl_render_SetStencilPassOperation = render.SetStencilPassOperation
	local fl_render_SetStencilReferenceValue = render.SetStencilReferenceValue
	local fl_render_SetStencilTestMask = render.SetStencilTestMask
	local fl_render_SetStencilWriteMask = render.SetStencilWriteMask
	local fl_render_SetStencilZFailOperation = render.SetStencilZFailOperation
	local fl_surface_DrawRect = surface.DrawRect
	local fl_surface_DrawTexturedRect = surface.DrawTexturedRect
	local fl_surface_SetDrawColor = surface.SetDrawColor

--local functions
local function disable_meme()
	meme_active = false
	
	--remove all hooks identified by "pyrition_meme"
	for event, hooks in pairs(hook.GetTable()) do if hooks.pyrition_meme then hook.Remove(event, "pyrition_meme") end end
	
	--remove all client side props 
	for key, meme_prop in pairs(meme_props) do meme_prop:Remove() end
end

local function draw_enjoyer(offset_x, offset_y, size, index, percentage)
	local data = meme_enjoyer_material_scrolls[index]
	local percentage_inverted = 1 - percentage
	local scroll_end = data[3]
	local scroll_start = data[2]
	size = size * data[1]
	
	local scroll_x = scroll_start[1] * percentage_inverted + scroll_end[1] * percentage - 0.5
	local scroll_y = scroll_start[2] * percentage_inverted + scroll_end[2] * percentage - 0.5
	
	surface.SetMaterial(meme_enjoyer_materials[index])
	fl_surface_DrawTexturedRect(scroll_x * size + offset_x, scroll_y * size + offset_y, size, size)
end

--[[custom font?
surface.CreateFont("string fontName", {
	
})
--]]

--command structure
COMMAND.Description = "Post process effects for memes"

COMMAND.Tree = {
	disable = disable_meme,
	
	enable = {
		enjoyer = {
			function(self, arguments)
				if meme_active then return self:Fail("A meme is already active.")
				else
					meme_active = true
					meme_text = {"average gmod fan", "average gmod enjoyer"}
				end
				
				surface.PlaySound("pyrition/memes/ejoyer.mp3")
				
				--settings
				local slide_duration = 5
				local slide_fade_duration = 2
				
				--cached
				local screen_height, screen_width = ScrH(), ScrW()
				local total_slides = #meme_enjoyer_materials
				local total_slide_show_duration = total_slides * slide_duration
				
				--calculated sizes
				local header_size = fl_math_ceil(screen_height * meme_enjoyer_header)
				local image_size = screen_height - header_size
				
				local image_center_y = image_size * 0.5 + header_size
				local image_x = (screen_width - image_size) * 0.5
				local screen_center_x = fl_math_floor(screen_width * 0.5)
				
				local enjoyer_text_x = image_x + image_size * 0.75
				local enjoyer_width = screen_center_x - image_x
				local enjoyer_x = screen_center_x - image_size * 0.25
				local fan_text_x = image_x + image_size * 0.25
				local view_clip_width = screen_width - screen_center_x
				local view_scaled_width = fl_math_ceil(image_size * screen_width / screen_height * meme_enjoyer_squeeze)
				local view_true_x = (screen_width - view_scaled_width - image_size * 0.5) * 0.5
				
				local view = {
					w = view_scaled_width,
					h = image_size,
					
					x = fl_math_max(view_true_x, 0), --unfortunately, the view port won't render if the x is negative, even though it should be in some cases
					y = header_size
				}
				
				hook.Add("RenderScene", "pyrition_meme", function(origin, angles, fov)
					view.angles = angles
					view.origin = origin
					
					fl_render_RenderView(view)
					fl_render_ClearDepth()
					
					fl_cam_Start2D()
						local real_time = RealTime() * meme_rate
						
						local current_time = real_time % total_slide_show_duration
						local current_time_index = current_time / slide_duration
						local future_time = (real_time + slide_fade_duration) % total_slide_show_duration
						local time_difference = fl_math_max(current_time % slide_duration - slide_duration + slide_fade_duration, 0) / slide_fade_duration
						
						fl_surface_SetDrawColor(0, 0, 0)
						fl_surface_DrawRect(0, 0, image_x, screen_height)
						
						fl_surface_SetDrawColor(0, 0, 0)
						fl_surface_DrawRect(screen_center_x, 0, view_clip_width, screen_height)
						
						fl_surface_SetDrawColor(255, 255, 255)
						fl_surface_DrawRect(image_x, 0, image_size, header_size)
						
						fl_draw_SimpleText(meme_text[1] or "<no first text>", "DermaLarge", fan_text_x, header_size * 0.5, color_black, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
						fl_draw_SimpleText(meme_text[2] or "<no second text>", "DermaLarge", enjoyer_text_x, header_size * 0.5, color_black, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
						
						fl_render_ClearStencil() --we don't want to rely on the bug that fl_render_ClearDepth also clears the stencil buffer
						fl_render_SetStencilEnable(true)
						
						fl_render_SetStencilCompareFunction(STENCIL_ALWAYS)
						fl_render_SetStencilFailOperation(STENCIL_KEEP)
						fl_render_SetStencilZFailOperation(STENCIL_KEEP)
						fl_render_SetStencilPassOperation(STENCIL_REPLACE)
						fl_render_SetStencilReferenceValue(1)
						fl_render_SetStencilTestMask(0xFF)
						fl_render_SetStencilWriteMask(0xFF)
						
						fl_surface_SetDrawColor(255, 255, 255)
						fl_surface_DrawRect(screen_center_x, header_size, enjoyer_width, image_size)
						
						fl_render_SetStencilCompareFunction(STENCIL_EQUAL)
						
						
						draw_enjoyer(enjoyer_text_x, image_center_y, image_size, fl_math_min(fl_math_ceil(current_time_index), total_slides), (current_time - fl_math_floor(current_time_index) * slide_duration) / slide_duration)
						
						if time_difference > 0 then
							local future_time_index = future_time / slide_duration
							
							fl_surface_SetDrawColor(255, 255, 255, time_difference ^ 2 * 255)
							
							draw_enjoyer(enjoyer_text_x, image_center_y, image_size, fl_math_min(fl_math_ceil(future_time_index), total_slides), (future_time - fl_math_floor(future_time_index) * slide_duration - slide_fade_duration) / slide_duration)
						end
						
						fl_render_SetStencilEnable(false)
					fl_cam_End2D()
					
					return true
				end)
			end,
			
			header = function(self, arguments) meme_enjoyer_header = math.Clamp(tonumber(arguments[1]) or meme_rate, 0, 1) end,
			squeeze = function(self, arguments) meme_enjoyer_squeeze = math.Clamp(tonumber(arguments[1]) or meme_rate, 0.1, 1) end,
		},
		
		stare = function(self, arguments)
			hook.Add("PrePlayerDraw", "pyrition_meme", function(ply)
				local bone_id = ply:LookupBone("ValveBiped.Bip01_Head1")
				
				if bone_id then
					local bone_matrix = ply:GetBoneMatrix(bone_id)
					
					if bone_matrix then
						local end_position = LocalPlayer():GetShootPos()
						local start_position = bone_matrix:GetTranslation()
						
						local direction = (end_position - start_position):GetNormalized()
						local direction_angles = select(2, LocalToWorld(vector_origin, Angle(-90, 90, 0), vector_origin, direction:Angle()))
						
						bone_matrix:SetAngles(direction_angles)
						
						ply:SetBoneMatrix(bone_id, bone_matrix)
					end
				end
			end)
		end
	},
	
	rate = function(self, arguments) meme_rate = math.Clamp(tonumber(arguments[1]) or meme_rate, 0.1, 10) end,
	
	text = function(self, arguments) meme_text = arguments end
}