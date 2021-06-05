--locals
local eye_trace = {}
local aim_entity_old
local aim_entity_old_index = 0
local render_target_art = render.GetScreenEffectTexture(0)
local trace = {mask = MASK_SHOT, output = eye_trace}

--render parameters
local outline_scale = 4
local outline_step = 2
local outline_min = -outline_scale
local outline_max = outline_scale

----localized functions
	local entity_meta = FindMetaTable("Entity")
	
	local fl_cam_End2D = cam.End2D
	local fl_cam_End3D = cam.End3D
	local fl_cam_Start2D = cam.Start2D
	local fl_cam_Start3D = cam.Start3D
	local fl_Entity_DrawModel = entity_meta.DrawModel
	local fl_Entity_GetNoDraw = entity_meta.GetNoDraw
	local fl_render_Clear = render.Clear
	local fl_render_ClearStencil = render.ClearStencil
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

--materials
local material_art = CreateMaterial("pyrition/outline/art", "UnlitGeneric", {
	["$basetexture"] = render_target_art:GetName(),
	["$vertexalpha"] = 1,
	["$vertexcolor"] = 1,
	["$translucent"] = 1
})

local function draw_blip(entity, r, g, b, a, scr_w, scr_h)
	--anti alias is making this shit draw dark edges which looks gross and weird
	--so we disable it
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
	
	--start fresh
	fl_render_ClearStencil()
	
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
		
		fl_surface_SetDrawColor(r, g, b, a)
		fl_surface_SetMaterial(material_art)
		
		for x = outline_min, outline_max, outline_step do
			if x == 0 then continue end
			
			for y = outline_min, outline_max, outline_step do
				if y == 0 then continue end
				
				fl_surface_DrawTexturedRect(x, y, scr_w, scr_h)
			end
		end
	fl_cam_End2D()
	
	fl_render_PopFilterMag()
	fl_render_PopFilterMin()
	fl_render_SetStencilEnable(false)
	fl_render_SuppressEngineLighting(false)
end

--hooks
hook.Add("PostDrawEffects", "pyrition_outline_blip", function()
	local entities = PYRITION.GFX.Outline
	local scr_w, scr_h = ScrW(), ScrH()
	
	for index, data in ipairs(entities) do
		local entity = data.entity
		
		if IsValid(entity) then
			if fl_Entity_GetNoDraw(entity) then continue end
			
			draw_blip(entity, data.r, data.g, data.b, data.a, scr_w, scr_h)
		end
	end
end)