--[[ entry structure
{
	r = number,
	g = number,
	b = number,
	a = number,
	entities = table
}
]]


--locals
local render_target_first = render.GetScreenEffectTexture(0)
local render_target_second = render.GetScreenEffectTexture(1)

--render parameters
local outline_scale = 2
local outline_step = 1
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
	local fl_render_ClearDepth = render.ClearDepth
	local fl_render_ClearStencil = render.ClearStencil
	local fl_render_CopyRenderTargetToTexture = render.CopyRenderTargetToTexture
	local fl_render_DrawScreenQuad = render.DrawScreenQuad
	local fl_render_GetRenderTarget = render.GetRenderTarget
	local fl_render_PopFilterMag = render.PopFilterMag
	local fl_render_PopFilterMin = render.PopFilterMin
	local fl_render_PopRenderTarget = render.PopRenderTarget
	local fl_render_PushFilterMag = render.PushFilterMag
	local fl_render_PushFilterMin = render.PushFilterMin
	local fl_render_PushRenderTarget = render.PushRenderTarget
	local fl_render_SetBlend = render.SetBlend
	local fl_render_SetMaterial = render.SetMaterial
	local fl_render_SetRenderTarget = render.SetRenderTarget
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
local material_copy = Material("pp/copy")
local material_first = CreateMaterial("pyrition/outline/first", "UnlitGeneric", {
	["$basetexture"] = render_target_first:GetName(),
	["$vertexalpha"] = 1,
	["$vertexcolor"] = 1,
	["$translucent"] = 1
})

local material_second = CreateMaterial("pyrition/outline/second", "UnlitGeneric", {
	["$basetexture"] = render_target_second:GetName(),
	["$vertexalpha"] = 1,
	["$vertexcolor"] = 1,
	["$translucent"] = 1
})

--local functions
local function draw_entities(entities)
	for index, entity in ipairs(entities) do
		if IsValid(entity) then
			if fl_Entity_GetNoDraw(entity) then continue end
			
			fl_Entity_DrawModel(entity)
		end
	end
end

local function draw_outlines(entities, r, g, b, a, scr_w, scr_h)
	--with a control of 404 fps
	--with 70 props of the same group got ~265 fps
	
	--with a control of 380 fps (GPU started getting hot)
	--with 41 props of 4 different groups got ~103 fps
	
	--anti alias is making this shit draw dark edges which looks gross and weird
	--so we disable it
	fl_render_PushFilterMag(TEXFILTER.POINT)
	fl_render_PushFilterMin(TEXFILTER.POINT)
	
	--we need stencils, and we won't need lighting
	fl_render_SetStencilEnable(true)
	fl_render_SuppressEngineLighting(true)
	
	--this draws a colored shape of the model
	fl_render_PushRenderTarget(render_target_first)
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
			
			draw_entities(entities)
		fl_cam_End3D()
		
		fl_render_SetStencilCompareFunction(STENCIL_EQUAL)
		fl_render_SetStencilFailOperation(STENCIL_KEEP)
		render.ClearBuffersObeyStencil(255, 255, 255, 255, true)
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
		
		draw_entities(entities)
	fl_cam_End3D()
	
	--draw the shape in several offsetted positions, but not where the stencil buffer is 1
	fl_cam_Start2D()
		--if the compare function does not pass, it will not render what you attempt to draw
		--by setting the fail operation to replace and purposefully faliling to draw the pixels of the model we can write to the stencil buffer without actually drawing the model
		fl_render_SetStencilCompareFunction(STENCIL_NOTEQUAL)
		
		fl_surface_SetDrawColor(r, g, b, a)
		fl_surface_SetMaterial(material_first)
		
		for x = outline_min, outline_max, outline_step do
			local x_zero = x == 0
			
			for y = outline_min, outline_max, outline_step do
				if x_zero and y == 0 then continue end
				
				fl_surface_DrawTexturedRect(x, y, scr_w, scr_h)
			end
		end
	fl_cam_End2D()
	
	fl_render_PopFilterMag()
	fl_render_PopFilterMin()
	fl_render_SetStencilEnable(false)
	fl_render_SuppressEngineLighting(false)
end

local function draw_outlines_depth(entities, r, g, b, a, scr_w, scr_h)
	--with a control of 404 fps
	--with 70 props of the same group got ~260 fps

	--with a control of 380 fps (GPU started getting hot)
	--with 41 props of 4 different groups got ~99 fps
	
	local render_target_scene = fl_render_GetRenderTarget()
	
	--prepare our scene to render in
	fl_render_CopyRenderTargetToTexture(render_target_first)
	fl_render_Clear(r, g, b, 0, false, true)
	fl_render_PushFilterMag(TEXFILTER.POINT)
	fl_render_PushFilterMin(TEXFILTER.POINT)
	fl_render_SetStencilEnable(true)
	fl_render_SuppressEngineLighting(true)
	
	--standard pass stencil
	fl_render_SetStencilCompareFunction(STENCIL_ALWAYS)
	fl_render_SetStencilFailOperation(STENCIL_KEEP)
	fl_render_SetStencilPassOperation(STENCIL_REPLACE)
	fl_render_SetStencilReferenceValue(1)
	fl_render_SetStencilTestMask(0xFF)
	fl_render_SetStencilWriteMask(0xFF)
	fl_render_SetStencilZFailOperation(STENCIL_KEEP)
	
	--draw the models
	fl_cam_Start3D()
		draw_entities(entities)
	fl_cam_End3D()
	
	--change settings to only draw where its 1
	fl_render_SetStencilCompareFunction(STENCIL_EQUAL)
	fl_render_SetStencilPassOperation(STENCIL_KEEP)
	
	--draw the color layer
	fl_cam_Start2D()
		fl_surface_SetDrawColor(255, 255, 255)
		fl_surface_DrawRect(0, 0, scr_w, scr_h)
	fl_cam_End2D()
	
	--done with this stencil
	fl_render_SetStencilEnable(false)
	fl_render_SuppressEngineLighting(false)
	
	--store what we drew to the second render target and set our render target back to what it was
	fl_render_CopyRenderTargetToTexture(render_target_second)
	fl_render_SetRenderTarget(render_target_scene)
	
	--needed to prevent the "flash bang" bug
	--seems that other render libraries can mess with the material's base texture >:(
	material_copy:SetTexture("$basetexture", render_target_first)
	
	--redraw the existing scene
	fl_render_SetMaterial(material_copy)
	fl_render_DrawScreenQuad()
	
	--more stencils!
	fl_render_SetStencilEnable(true)
	fl_render_SetStencilCompareFunction(STENCIL_EQUAL)
	fl_render_SetStencilReferenceValue(0)
	
	--draw the model shapes sever times
	fl_cam_Start2D()
		fl_surface_SetDrawColor(r, g, b, a)
		fl_surface_SetMaterial(material_second)
		
		for x = outline_min, outline_max, outline_step do
			local x_zero = x == 0
			
			for y = outline_min, outline_max, outline_step do
				if x_zero and y == 0 then continue end
				
				fl_surface_DrawTexturedRect(x, y, scr_w, scr_h)
			end
		end
	fl_cam_End2D()
	
	--fl_render_ClearDepth()
	fl_render_PopFilterMag()
	fl_render_PopFilterMin()
	fl_render_SetStencilEnable(false)
end

--hooks
hook.Add("PostDrawEffects", "pyrition_gfx_outline", function()
	local scr_w, scr_h = ScrW(), ScrH()
	
	local groups = PYRITION.GFX.Outline
	
	for index, data in pairs(groups) do
		if data.ignore_z then draw_outlines(data.entities, data.r, data.g, data.b, data.a, scr_w, scr_h)
		else draw_outlines_depth(data.entities, data.r, data.g, data.b, data.a, scr_w, scr_h) end
	end
	
	hook.Call("PyritionGFXOutlineHaloOverride", PYRITION)
end)

--pyrition functions
function PYRITION:PyritionGFXOutlineHaloOverride()
	hook.Run("PreDrawHalos")
	
	local halos = PYRITION.GFX.Halo
	local scr_w, scr_h = ScrW(), ScrH()
	
	--temporary code
	--not if you're trying to under stand how to add outlines:
	--this is not the right way
	--you wouldn't have to add them every frame, instead make this kind of table in PYRITION.GFX.Outline (must be a sequential entry)
	local bots = {}
	
	for index, bot in ipairs(player.GetBots()) do if IsValid(bot) and bot:Alive() then table.insert(bots, bot) end end
	
	table.insert(halos, {
		r = 255,
		g = 0,
		b = 0,
		a = 16,
		
		entities = bots
	})
	
	if #halos == 0 then return end
	
	for index, data in ipairs(halos) do
		if data.ignore_z then draw_outlines(data.entities, data.r, data.g, data.b, data.a, scr_w, scr_h)
		else draw_outlines_depth(data.entities, data.r, data.g, data.b, data.a, scr_w, scr_h) end
	end
	
	PYRITION.GFX.Halo = {}
end