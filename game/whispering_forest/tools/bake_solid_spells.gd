extends SceneTree

const Model = preload("res://game/whispering_forest/art/combat/solid_spell_model.gd")
const Stage = preload("res://game/whispering_forest/art/city/render_stage.gd")
const OUTPUT := "res://game/whispering_forest/assets/combat-vfx/solid-8/"
const CELL := 384

func _initialize() -> void:
	bake.call_deferred()

func bake() -> void:
	if RenderingServer.get_current_rendering_method()!=Stage.SETTINGS.renderer:
		push_error("Spell export requires the shared renderer: "+str(Stage.SETTINGS.renderer))
		quit(1); return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	var vp:=SubViewport.new()
	vp.size=Vector2i(CELL,CELL)
	vp.transparent_bg=true
	vp.own_world_3d=true
	vp.msaa_3d=Viewport.MSAA_4X
	vp.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var stage:=Stage.new()
	vp.add_child(stage)
	stage.build()
	var model:=Model.new()
	stage.add_child(model)
	var manifest: Dictionary={"frames":Model.FRAMES,"profile":Stage.profile_record(),"clips":{},"sources":{}}
	for source in ["res://game/whispering_forest/art/combat/solid_spell_model.gd","res://game/whispering_forest/art/combat/stone_weather.gdshader","res://game/whispering_forest/tools/bake_solid_spells.gd"]:
		manifest.sources[source]=FileAccess.get_sha256(source)
	for kind in ["ice","earth","wind"]:
		var target:=Vector3.ZERO if kind=="earth" else Vector3(0,1.35,0)
		stage.frame_canvas(vp.size,target)
		await process_frame
		if not stage.verify_projection():
			push_error("Spell projection differs from the city basis")
			quit(1); return
		var pivot: Vector2=stage.camera.unproject_position(Vector3.ZERO)
		var variants: int=6 if kind=="earth" else 1
		var sheet:=Image.create(CELL*Model.FRAMES,CELL*variants,false,Image.FORMAT_RGBA8)
		var bounds: Array=[]
		for variant in range(variants):
			if kind=="earth": model.build_stone(variant)
			var variant_bounds: Array=[]
			for frame in range(Model.FRAMES):
				if kind=="ice": model.ice_pose(frame)
				elif kind=="wind": model.wind_pose(frame)
				else: model.stone_pose(frame,variant)
				await process_frame
				await process_frame
				await RenderingServer.frame_post_draw
				var rendered:=vp.get_texture().get_image()
				rendered.convert(Image.FORMAT_RGBA8)
				var box:=rendered.get_used_rect()
				if box.size==Vector2i.ZERO or box.position.x<2 or box.position.y<2 or box.end.x>CELL-2 or box.end.y>CELL-2:
					push_error("Clipped/empty spell pose %s %d/%d: %s" % [kind,variant,frame,box])
					quit(1); return
				if stage.camera.unproject_position(Vector3.ZERO).distance_to(pivot)>0.0001:
					push_error("Spell root drifted during export")
					quit(1); return
				sheet.blit_rect(rendered,Rect2i(0,0,CELL,CELL),Vector2i(frame*CELL,variant*CELL))
				variant_bounds.append([box.position.x,box.position.y,box.size.x,box.size.y])
			bounds.append(variant_bounds)
		var path: String=OUTPUT+kind+".png"
		if sheet.save_png(path)!=OK: quit(1); return
		manifest.clips[kind]={"file":path,"frames":Model.FRAMES,"variants":variants,"cell":CELL,"pivot":[pivot.x,pivot.y],"bounds":bounds,"sha256":FileAccess.get_sha256(path),"runtime_scale":1.0/Stage.SUPERSAMPLE,"anchor":"projected model origin; no per-frame centering"}
		if kind=="ice":
			manifest.clips[kind].times=Model.ICE_TIMES
			manifest.clips[kind].heights_metres=Model.ICE_HEIGHTS
		print("WF_SOLID_SPELL_BAKED %s: %d variants x 8 poses; origin %s" % [kind,variants,pivot])
	var file:=FileAccess.open(OUTPUT+"manifest.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(manifest,"\t")+"\n")
	file.close()
	vp.queue_free()
	await process_frame
	print("WF_SOLID_SPELLS_OK: eight poses, shared camera/light/density, fixed model origins, alpha bounds")
	quit()
