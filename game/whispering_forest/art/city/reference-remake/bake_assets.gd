extends SceneTree

const Stage = preload("res://game/whispering_forest/art/city/render_stage.gd")
const Shadow = preload("res://game/whispering_forest/art/city/shadow_geometry.gd")
const ProjectedShadow = preload("res://game/whispering_forest/art/city/reference-remake/projected_shadow.gd")
const SOURCE := "res://game/whispering_forest/art/city/reference-remake/"
const OUTPUT := "res://game/whispering_forest/assets/city-reference-remake/"
var paint_cache := {}
var texture_means := {}

func _initialize() -> void:
	bake.call_deferred()

func paint(role: String,spec: Dictionary) -> Material:
	var key := str([role,spec])
	if paint_cache.has(key): return paint_cache[key]
	var material := ShaderMaterial.new()
	material.shader=load(SOURCE+"painted_surface.gdshader")
	material.set_shader_parameter("base_color",Color(spec.color))
	var texture_name: String=spec.get("texture","") if spec.get("texture")!=null else ""
	if not texture_name.is_empty():
		material.set_shader_parameter("has_paint",true)
		material.set_shader_parameter("paint",load(SOURCE+"materials/"+texture_name))
		if not texture_means.has(texture_name):
			var pixels := Image.load_from_file(SOURCE+"materials/"+texture_name)
			pixels.resize(32,32,Image.INTERPOLATE_LANCZOS)
			var total := Vector3.ZERO
			for y in range(32):
				for x in range(32):
					var c := pixels.get_pixel(x,y).srgb_to_linear()
					total+=Vector3(c.r,c.g,c.b)
			texture_means[texture_name]=total/1024.0
		material.set_shader_parameter("paint_mean",texture_means[texture_name])
		material.set_shader_parameter("paint_strength",0.94 if role=="roof" else 0.74 if role=="plaster" else 0.72 if role.begins_with("limestone") or role=="exposed_stone" else 0.65 if role.begins_with("oak") else 0.48)
	var kind := 0.0
	if role.begins_with("oak"): kind=1.0
	elif role.begins_with("roof"): kind=2.0
	elif role.begins_with("plaster"): kind=3.0
	elif role=="exposed_stone": kind=0.0
	elif role.begins_with("leaf") or role=="flower": kind=4.0
	elif role not in ["limestone","limestone_light","limestone_dark","mortar"]: kind=5.0
	material.set_shader_parameter("surface_kind",kind)
	paint_cache[key]=material
	return material

func restore_small_materials(node: Node) -> void:
	if node is MeshInstance3D:
		for index in range(node.mesh.get_surface_count()):
			var original: Material=node.get_active_material(index)
			var tint := Color("a9b1ad")
			if original is StandardMaterial3D:tint=original.albedo_color
			elif original is ShaderMaterial:
				var stone_color=original.get_shader_parameter("stone_color")
				if stone_color is Color:tint=stone_color
			var role := "iron"
			var texture_name := ""
			if tint.v>0.67 and tint.s<0.26:role="limestone";texture_name="limestone.png"
			elif tint.g>tint.r*1.1 and tint.g>tint.b*1.05:role="leaf"
			elif tint.r>tint.b*1.25 and tint.r>tint.g*1.06:
				role="oak";texture_name="oak.png"
			elif tint.b>tint.r*1.12:role="glass"
			node.set_surface_override_material(index,paint(role,{"color":tint.to_html(false),"texture":texture_name}))
	for child in node.get_children():restore_small_materials(child)

func apply_materials(node: Node,materials: Dictionary) -> void:
	if node is MeshInstance3D:
		for index in range(node.mesh.get_surface_count()):
			var original: Material=node.mesh.surface_get_material(index)
			var role: String=String(node.get_meta("material_role",original.resource_name if original!=null else ""))
			if materials.has(role): node.set_surface_override_material(index,paint(role,materials[role]))
	for child in node.get_children(): apply_materials(child,materials)

func owner_tree(node: Node,top: Node) -> void:
	for child in node.get_children():
		child.owner=top
		owner_tree(child,top)

func bake() -> void:
	if RenderingServer.get_current_rendering_method()!="forward_plus":
		push_error("Use Forward+ for the shared city render stage");quit(1);return
	var registry: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(SOURCE+"registry.json"))
	# Small civic furniture and precisely fitted curb/fence geometry are retained
	# as editable models and re-rendered with the same new daylight/materials.
	var existing: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://game/whispering_forest/assets/city-built/frames.json"))
	for id in existing:
		var old: Dictionary=existing[id]
		if old.rotation_degrees!=0 or registry.has(id):continue
		var spec: Dictionary=old.duplicate(true)
		spec.geometry=old.get("geometry_source",old.source)
		spec.blend=old.get("editable_source","")
		spec.materials={}
		spec.retained_geometry=true
		registry[id]=spec
	var selected: PackedStringArray=[]
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--assets="):selected=arg.trim_prefix("--assets=").split(",")
	var viewport := SubViewport.new()
	viewport.size=Vector2i(2048,2048)
	viewport.transparent_bg=true
	viewport.own_world_3d=true
	viewport.msaa_3d=Viewport.MSAA_4X
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var stage := Stage.new()
	viewport.add_child(stage)
	stage.build()
	await process_frame
	if not stage.verify_projection(): quit(1);return
	var frames: Dictionary={}
	if FileAccess.file_exists(OUTPUT+"frames.json"):frames=JSON.parse_string(FileAccess.get_file_as_string(OUTPUT+"frames.json"))
	var dependencies := {}
	for directory in [SOURCE,SOURCE+"materials/"]:
		for file in DirAccess.get_files_at(directory):
			if file.ends_with(".png") or file.ends_with(".gdshader") or (directory==SOURCE+"materials/" and file.ends_with(".png.import")):
				dependencies[directory+file]=FileAccess.get_sha256(directory+file)
	dependencies[SOURCE+"projected_shadow.gd"]=FileAccess.get_sha256(SOURCE+"projected_shadow.gd")
	dependencies[SOURCE+"bake_assets.gd"]=FileAccess.get_sha256(SOURCE+"bake_assets.gd")
	FileAccess.open(OUTPUT+"surface-dependencies.json",FileAccess.WRITE).store_string(JSON.stringify(dependencies,"\t")+"\n")
	var surface_signature := FileAccess.get_sha256(OUTPUT+"surface-dependencies.json")
	for kind in registry:
		if not selected.is_empty() and kind not in selected:continue
		var record: Dictionary=registry[kind]
		var model: Node3D=load(record.geometry).instantiate()
		if record.get("retained_geometry",false):restore_small_materials(model)
		else:apply_materials(model,record.materials)
		model.set_meta("ground_size",Vector2(record.footprint[0],record.footprint[1]))
		model.set_meta("height",record.height_metres)
		var entry: Array=record.get("entry_metres",[0,0,0])
		model.set_meta("door_ground",Vector3(entry[0],entry[1],entry[2]))
		stage.add_child(model)
		owner_tree(model,model)
		var packed := PackedScene.new()
		packed.pack(model)
		var model_path: String=SOURCE+"models/"+kind+".tscn"
		ResourceSaver.save(packed,model_path)
		for degrees in ([0,90,180,270] if record.category=="building" or record.category=="civic" else [0]):
			model.rotation.y=deg_to_rad(degrees)
			await process_frame
			await process_frame
			await RenderingServer.frame_post_draw
			var rendered := viewport.get_texture().get_image()
			var rect := rendered.get_used_rect().grow(4).intersection(Rect2i(0,0,2048,2048))
			if rect.position.x<4 or rect.position.y<4 or rect.end.x>2044 or rect.end.y>2044:
				push_error("Clipped model: "+kind);quit(1);return
			var id: String=kind+("_r%d" % degrees if degrees!=0 else "")
			var output := rendered.get_region(rect)
			output.save_png(OUTPUT+id+".png")
			var size: Vector2=model.get_meta("ground_size")
			if degrees in [90,270]:size=Vector2(size.y,size.x)
			var anchor := Vector3(size.x,0,size.y)/64 if record.category=="building" else Vector3.ZERO
			var origin := stage.camera.unproject_position(anchor)-Vector2(rect.position)
			var normal := model.basis*Vector3.BACK
			var approach: float=record.get("entrance_approach_metres",0.75)*32.0
			var threshold: Vector3=(model.basis*model.get_meta("door_ground")-anchor)*32
			var door: Vector3=threshold+normal*approach
			var f: Dictionary=record.duplicate(true)
			f.door_threshold=[threshold.x,threshold.z]
			f.door_approach=approach
			f.surface_signature=surface_signature
			if record.has("connectors"):
				f.connectors=[]
				for connector in record.connectors:
					var c: Vector3=model.basis*Vector3(connector[0],connector[1],connector[2])
					f.connectors.append([c.x,c.y,c.z])
			f.merge({"pivot":[origin.x,origin.y],"region":[0,0,rect.size.x,rect.size.y],"crop_origin":[rect.position.x,rect.position.y],"footprint":[size.x,size.y],"scale":0.5,"door":[door.x,door.z],"door_normal":[normal.x,normal.z],"source":model_path,"source_sha256":FileAccess.get_sha256(model_path),"geometry_source":record.geometry,"geometry_sha256":FileAccess.get_sha256(record.geometry),"rotation_degrees":degrees,"render_config":Stage.profile_record(),"baked_ground_shadow":false,"ground_shadow":"runtime_ground_layer","shadow_outline":Shadow.outline(model,anchor),"png_sha256":FileAccess.get_sha256(OUTPUT+id+".png")},true)
			if not record.blend.is_empty():
				f.editable_source=record.blend
				f.blend_sha256=FileAccess.get_sha256(record.blend)
			var sun: Array=Stage.profile_record().key_rotation
			var ground_shadow := ProjectedShadow.build(model,Vector3(sun[0],sun[1],sun[2]))
			model.hide()
			stage.add_child(ground_shadow)
			for i in range(2):await process_frame
			await RenderingServer.frame_post_draw
			var shadow_pixels := viewport.get_texture().get_image()
			var shadow_rect := shadow_pixels.get_used_rect().grow(4).intersection(Rect2i(0,0,2048,2048))
			shadow_pixels.get_region(shadow_rect).save_png(OUTPUT+id+"_shadow.png")
			var shadow_origin := stage.camera.unproject_position(anchor)-Vector2(shadow_rect.position)
			f.shadow_texture=id+"_shadow.png"
			f.shadow_pivot=[shadow_origin.x,shadow_origin.y]
			f.shadow_size=[shadow_rect.size.x,shadow_rect.size.y]
			f.shadow_sha256=FileAccess.get_sha256(OUTPUT+f.shadow_texture)
			stage.remove_child(ground_shadow)
			ground_shadow.queue_free()
			model.show()
			frames[id]=f
			print("WF_REFERENCE_RENDER_OK ",id," ",rect.size)
		stage.remove_child(model)
		model.queue_free()
		await process_frame
	FileAccess.open(OUTPUT+"frames.json",FileAccess.WRITE).store_string(JSON.stringify(frames,"\t")+"\n")
	FileAccess.open(OUTPUT+"frames.gd",FileAccess.WRITE).store_string("extends RefCounted\nconst FRAMES := "+JSON.stringify(frames,"\t")+"\n")
	FileAccess.open(OUTPUT+"render-profile.json",FileAccess.WRITE).store_string(JSON.stringify(Stage.profile_record(),"\t")+"\n")
	FileAccess.open(SOURCE+"render-profile.json",FileAccess.WRITE).store_string(JSON.stringify(Stage.profile_record(),"\t")+"\n")
	print("WF_REFERENCE_PACK_OK ",frames.size()," assets / directions")
	quit()
