extends SceneTree

const Model = preload("res://game/whispering_forest/art/city/building_model.gd")
const EnvironmentModel = preload("res://game/whispering_forest/art/city/environment_model.gd")
const CivicModel = preload("res://game/whispering_forest/art/city/civic_model.gd")
const Shadow = preload("res://game/whispering_forest/art/city/shadow_geometry.gd")
const BlenderSource = preload("res://game/whispering_forest/art/city/blender_source.gd")
const Stage = preload("res://game/whispering_forest/art/city/render_stage.gd")
const SOURCE := "res://game/whispering_forest/art/city/models"
const OUTPUT := "res://game/whispering_forest/assets/city-built"

func _initialize() -> void:
	bake.call_deferred()

func bake() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SOURCE))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	var viewport := SubViewport.new()
	viewport.name="AssetRenderViewport"
	viewport.size=Vector2i(Stage.CANVAS,Stage.CANVAS)
	viewport.transparent_bg=Stage.SETTINGS.transparent
	viewport.own_world_3d=true
	viewport.msaa_3d={2:Viewport.MSAA_2X,4:Viewport.MSAA_4X,8:Viewport.MSAA_8X}[Stage.SETTINGS.msaa]
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var stage := Stage.new()
	viewport.add_child(stage)
	stage.build()
	await process_frame
	if not stage.verify_projection():
		push_error("WF_CITY_BAKE: projection does not match the gameplay grid")
		quit(1)
		return
	var stage_scene := PackedScene.new()
	stage_scene.pack(stage)
	ResourceSaver.save(stage_scene,"res://game/whispering_forest/art/city/render_stage.tscn")
	var selected := ""
	var rebuild_models := false
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--asset="): selected=arg.trim_prefix("--asset=")
		if arg=="--rebuild-models": rebuild_models=true
	var frames := {}
	var metadata := OUTPUT+"/frames.json"
	if FileAccess.file_exists(metadata): frames=JSON.parse_string(FileAccess.get_file_as_string(metadata))
	var civic_catalog := CivicModel.catalog()
	var optimized_models := BlenderSource.registry()
	# Track external paint/shader files as well as model geometry. A shader
	# edit must invalidate old pixels even when its .tscn path did not change.
	var surface_dependencies := {}
	for directory in ["res://game/whispering_forest/art/city/","res://game/whispering_forest/art/city/materials/"]:
		for file_name in DirAccess.get_files_at(directory):
			if file_name.ends_with(".gdshader") or file_name.ends_with(".png"):
				surface_dependencies[directory+file_name]=FileAccess.get_sha256(directory+file_name)
	var legacy_stone := "res://game/whispering_forest/assets/city-v2/masonry.png"
	surface_dependencies[legacy_stone]=FileAccess.get_sha256(legacy_stone)
	var surface_path := OUTPUT+"/surface-dependencies.json"
	var surface_file := FileAccess.open(surface_path,FileAccess.WRITE)
	surface_file.store_string(JSON.stringify(surface_dependencies,"\t")+"\n")
	surface_file.close()
	var surface_signature := FileAccess.get_sha256(surface_path)
	for kind in Model.SPECS.keys()+Model.VARIANTS.keys()+EnvironmentModel.KINDS+civic_catalog.keys():
		if not selected.is_empty() and not kind in selected.split(","): continue
		var model_path := SOURCE+"/%s.tscn" % kind
		var model: Node3D
		if FileAccess.file_exists(model_path) and not rebuild_models:
			model=load(model_path).instantiate()
		else:
			model=Model.new() if Model.SPECS.has(kind) or Model.VARIANTS.has(kind) else (CivicModel.new() if civic_catalog.has(kind) else EnvironmentModel.new())
			model.build(kind)
			var packed := PackedScene.new()
			packed.pack(model)
			if ResourceSaver.save(packed,model_path)!=OK:
				push_error("Cannot save building source: "+kind)
				quit(1)
				return
		if optimized_models.has(kind): model=BlenderSource.instantiate(model,optimized_models[kind])
		stage.add_child(model)
		var is_building: bool = Model.SPECS.has(kind) or Model.VARIANTS.has(kind)
		for degrees in ([0,90,180,270] if is_building or civic_catalog.has(kind) else [0]):
			model.rotation.y=deg_to_rad(degrees)
			await process_frame
			await process_frame
			await RenderingServer.frame_post_draw
			var rendered := viewport.get_texture().get_image()
			var rect := rendered.get_used_rect().grow(4).intersection(Rect2i(0,0,Stage.CANVAS,Stage.CANVAS))
			var export_id: String = kind if degrees==0 else "%s_r%d" % [kind,degrees]
			if rect.position.x<4 or rect.position.y<4 or rect.end.x>Stage.CANVAS-4 or rect.end.y>Stage.CANVAS-4:
				push_error("Asset touches canvas border: "+export_id)
				quit(1)
				return
			var image := rendered.get_region(rect)
			if image.save_png(OUTPUT+"/%s.png" % export_id)!=OK:
				push_error("Cannot write render: "+export_id)
				quit(1)
				return
			var size: Vector2 = model.get_meta("ground_size")
			if degrees in [90,270]: size=Vector2(size.y,size.x)
			var anchor := Vector3(size.x,0,size.y)/(2.0*Stage.LOGICAL_UNITS_PER_METRE) if is_building else Vector3.ZERO
			var origin := stage.camera.unproject_position(anchor)-Vector2(rect.position)
			var normal := model.basis*Vector3.BACK
			var entry: Vector3 = model.basis*model.get_meta("door_ground",Vector3.ZERO)
			var door := (entry-anchor)*Stage.LOGICAL_UNITS_PER_METRE+normal*24.0
			frames[export_id]={"pivot":[origin.x,origin.y],"region":[0,0,rect.size.x,rect.size.y],"crop_origin":[rect.position.x,rect.position.y],"footprint":[size.x,size.y],"scale":1.0/Stage.SUPERSAMPLE,"door":[snappedf(door.x,0.001),snappedf(door.z,0.001)],"door_normal":[snappedf(normal.x,0.001),snappedf(normal.z,0.001)],"source":model_path,"source_sha256":FileAccess.get_sha256(model_path),"rotation_degrees":degrees,"render_config":Stage.profile_record(),"height_metres":model.get_meta("height",0.0),"category":"building" if is_building else "environment","baked_ground_shadow":false,"ground_shadow":Stage.SETTINGS.ground_shadow}
			frames[export_id].shadow_outline=Shadow.outline(model,anchor)
			frames[export_id].surface_signature=surface_signature
			if optimized_models.has(kind):
				var refinement: Dictionary = optimized_models[kind]
				frames[export_id].editable_source=refinement.blend
				frames[export_id].geometry_source=refinement.geometry
				frames[export_id].blend_sha256=FileAccess.get_sha256(refinement.blend)
				frames[export_id].geometry_sha256=FileAccess.get_sha256(refinement.geometry)
				frames[export_id].blender_version=refinement.blender_version
			if civic_catalog.has(kind):
				frames[export_id].category="civic"
				frames[export_id].module_spec=model.get_meta("module_spec")
				frames[export_id].connectors=[]
				for connector in model.get_meta("connectors",[]):
					var p: Vector3 = model.basis*connector*Stage.LOGICAL_UNITS_PER_METRE
					frames[export_id].connectors.append([p.x,p.y,p.z])
				if model.has_meta("aperture"): frames[export_id].aperture=model.get_meta("aperture")
			print("WF_CITY_BAKED: %s %dx%d; footprint=%s; config=%s" % [export_id,image.get_width(),image.get_height(),size,Stage.PROFILE_VERSION])
		stage.remove_child(model)
		model.queue_free()
		await process_frame
	var profile_file := FileAccess.open(OUTPUT+"/render-profile.json",FileAccess.WRITE)
	profile_file.store_string(JSON.stringify(Stage.profile_record(),"\t")+"\n")
	profile_file.close()
	var json_file := FileAccess.open(metadata,FileAccess.WRITE)
	json_file.store_string(JSON.stringify(frames,"\t")+"\n")
	json_file.close()
	var gd_file := FileAccess.open(OUTPUT+"/frames.gd",FileAccess.WRITE)
	gd_file.store_string("extends RefCounted\n\nconst FRAMES := "+JSON.stringify(frames,"\t")+"\n")
	gd_file.close()
	viewport.queue_free()
	await process_frame
	await process_frame
	print("WF_CITY_BAKE_OK: orthographic basis, source scenes, alpha bounds, pivots and footprints verified")
	quit()
