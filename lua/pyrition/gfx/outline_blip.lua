--locals
local eye_trace = {}
local aim_entity_old
local aim_entity_old_index = 0
local render_target_art = render.GetScreenEffectTexture(0)
local render_target_outline = render.GetScreenEffectTexture(1)
local trace = {mask = MASK_SHOT, output = eye_trace}

--render parameters
local blip_period = 2
local outline_scale = 4
local outline_step = 1
local outline_min = -outline_scale
local outline_max = outline_scale

--materials
local material_art = CreateMaterial("pyrition/outline_blip/art", "UnlitGeneric", {
	["$basetexture"] = render_target_art:GetName(),
	["$vertexalpha"] = 1,
	["$vertexcolor"] = 1,
	["$translucent"] = 1
})

local material_outline = CreateMaterial("pyrition/outline_blip/outline", "UnlitGeneric", {
	["$basetexture"] = render_target_outline:GetName(),
	["$vertexalpha"] = 1,
	["$vertexcolor"] = 1,
	["$translucent"] = 1
})

----localized functions
	local entity_meta = FindMetaTable("Entity")
	
	local fl_cam_End2D = cam.End2D
	local fl_cam_End3D = cam.End3D
	local fl_cam_Start2D = cam.Start2D
	local fl_cam_Start3D = cam.Start3D
	local fl_Entity_DrawModel = entity_meta.DrawModel
	local fl_Entity_GetNoDraw = entity_meta.GetNoDraw
	local fl_render_Clear = render.Clear
	local fl_render_PopFilterMag = render.PopFilterMag
	local fl_render_PopFilterMin = render.PopFilterMin
	local fl_render_PopRenderTarget = render.PopRenderTarget
	local fl_render_PushFilterMag = render.PushFilterMag
	local fl_render_PushFilterMin = render.PushFilterMin
	local fl_render_PushRenderTarget = render.PushRenderTarget
	local fl_render_SetStencilEnable = render.SetStencilEnable
	local fl_render_SetStencilCompareFunction = render.SetStencilCompareFunction
	local fl_render_SetStencilFailOperation = render.SetStencilFailOperation
	local fl_render_SetStencilPassOperation = render.SetStencilPassOperation
	local fl_render_SetStencilReferenceValue = render.SetStencilReferenceValue
	local fl_render_SetStencilTestMask = render.SetStencilTestMask
	local fl_render_SetStencilWriteMask = render.SetStencilWriteMask
	local fl_render_SetStencilZFailOperation = render.SetStencilZFailOperation
	local fl_render_SuppressEngineLighting = render.SuppressEngineLighting
	local fl_surface_DrawRect = surface.DrawRect
	local fl_surface_DrawTexturedRect = surface.DrawTexturedRect
	local fl_surface_SetDrawColor = surface.SetDrawColor
	local fl_surface_SetMaterial = surface.SetMaterial
--

local function draw_blip(entity, r, g, b, a, real_time, scr_w, scr_h, blip_modulo, blip_alpha, blip_modulo_scale)
	--anti alias is making this shit draw dark edges which looks gross and weird, so we disable it
	fl_render_PushFilterMag(TEXFILTER.POINT)
	fl_render_PushFilterMin(TEXFILTER.POINT)
	
	--we need stencils, and we won't need lighting
	fl_render_SetStencilEnable(true)
	fl_render_SuppressEngineLighting(true)
	
	--this draws a colored shape of the model
	fl_render_PushRenderTarget(render_target_art)
		fl_render_Clear(0, 0, 0, 0, true, true)
		
		--write 1 to the stencil buffer where the model is
		--we purposely fail so the model isn't rendered
		fl_cam_Start3D()
			fl_render_SetStencilCompareFunction(STENCIL_NEVER)
			fl_render_SetStencilFailOperation(STENCIL_REPLACE)
			fl_render_SetStencilPassOperation(STENCIL_KEEP)
			fl_render_SetStencilReferenceValue(1)
			fl_render_SetStencilTestMask(0xFF)
			fl_render_SetStencilWriteMask(0xFF)
			fl_render_SetStencilZFailOperation(STENCIL_KEEP)
			
			fl_Entity_DrawModel(entity)
		fl_cam_End3D()
		
		--draw a white rect over the entire screen where the stencil is equal to 1
		fl_cam_Start2D()
			fl_render_SetStencilCompareFunction(STENCIL_EQUAL)
			fl_render_SetStencilFailOperation(STENCIL_KEEP)
			
			fl_surface_SetDrawColor(255, 255, 255)
			fl_surface_DrawRect(0, 0, scr_w, scr_h)
		fl_cam_End2D()
	fl_render_PopRenderTarget()
	
	--this draws an outline with that shape
	fl_render_PushRenderTarget(render_target_outline)
		fl_render_Clear(255, 0, 0, 0, true, true)
		
		--fail to draw the model and write to the stencil buffer 
		fl_cam_Start3D()
			fl_render_SetStencilCompareFunction(STENCIL_NEVER)
			fl_render_SetStencilFailOperation(STENCIL_REPLACE)
			fl_render_SetStencilPassOperation(STENCIL_KEEP)
			fl_render_SetStencilReferenceValue(1)
			fl_render_SetStencilTestMask(0xFF)
			fl_render_SetStencilWriteMask(0xFF)
			fl_render_SetStencilZFailOperation(STENCIL_KEEP)
			
			fl_Entity_DrawModel(entity)
		fl_cam_End3D()
		
		--draw the shape in several offsetted positions, but not where the stencil buffer is 1
		fl_cam_Start2D()
			--if the compare function does not pass, it will not render what you attempt to draw
			--by setting the fail operation to replace and purposefully faliling to draw the pixels of the model we can write to the stencil buffer without actually drawing the model
			fl_render_SetStencilCompareFunction(STENCIL_NOTEQUAL)
			
			fl_surface_SetDrawColor(255, 255, 255, 255)
			fl_surface_SetMaterial(material_art)
			
			for x = outline_min, outline_max, outline_step do
				if x == 0 then continue end
				
				for y = outline_min, outline_max, outline_step do
					if y == 0 then continue end
					
					fl_surface_DrawTexturedRect(x, y, scr_w, scr_h)
				end
			end
		fl_cam_End2D()
	fl_render_PopRenderTarget()
	
	--we're done with the stencil
	fl_render_SetStencilEnable(false)
	fl_render_SuppressEngineLighting(false)
	
	--this draws the outline we made with different translations
	fl_cam_Start2D()
		local blip_w, blip_h = scr_w * blip_modulo_scale, scr_h * blip_modulo_scale
		
		--draw the outline
		fl_surface_SetDrawColor(r, g, b, a)
		fl_surface_SetMaterial(material_outline)
		fl_surface_DrawTexturedRect(0, 0, scr_w, scr_h)
		
		--draw the scaled blipping outline
		fl_surface_SetDrawColor(r, g, b, blip_alpha * a)
		fl_surface_DrawTexturedRect((scr_w - blip_w) * 0.5, (scr_h - blip_h) * 0.5, blip_w, blip_h)
	fl_cam_End2D()
	
	fl_render_PopFilterMag()
	fl_render_PopFilterMin()
end

--hooks
hook.Add("PostDrawEffects", "pyrition_outline_blip", function()
	local entities = PYRITION.GFX.BlipOutline
	local real_time = RealTime()
	local scr_w, scr_h = ScrW(), ScrH()
	
	local blip_modulo = (real_time / blip_period) % 1
	local blip_module_alpha = 1 - blip_modulo
	local blip_modulo_scale = blip_modulo ^ 0.9 * 0.2 + 1
	
	for index, data in ipairs(entities) do
		local entity = data.entity
		
		if IsValid(entity) then
			if fl_Entity_GetNoDraw(entity) then continue end
			
			draw_blip(entity, data.r, data.g, data.b, data.a, real_time, scr_w, scr_h, blip_modulo, blip_module_alpha, blip_modulo_scale)
		end
	end
end)