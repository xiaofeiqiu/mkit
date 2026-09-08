extends SceneTree

const Building = preload("res://game/whispering_forest/art/city/building_model.gd")
const EnvironmentModel = preload("res://game/whispering_forest/art/city/environment_model.gd")
const Civic = preload("res://game/whispering_forest/art/city/civic_model.gd")
const Stage = preload("res://game/whispering_forest/art/city/render_stage.gd")
const ART := "res://game/whispering_forest/art/city/"
var source_map := {}
var material_roles := {}
var serial := 0

func _initialize() -> void:
	prepare.call_deferred()

func prepare() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(ART+"blender/input"))
	var catalog := Civic.catalog()
	var record := {"render_profile":Stage.profile_record(),"assets":{}}
	for id in Building.SPECS.keys()+Building.VARIANTS.keys()+EnvironmentModel.KINDS+catalog.keys():
		var is_building: bool = Building.SPECS.has(id) or Building.VARIANTS.has(id)
		var model: Node3D = Building.new() if is_building else (Civic.new() if catalog.has(id) else EnvironmentModel.new())
		model.build(id)
		var packed := PackedScene.new()
		packed.pack(model)
		var source_path := ART+"models/%s.tscn" % id
		if ResourceSaver.save(packed,source_path)!=OK: quit(1); return
		if id.begins_with("curb_") or id.begins_with("fence_"):
			model.free()
			continue
		serial=0
		source_map={}
		material_roles={}
		var flat := Node3D.new()
		flat.name="EditableCityModel"
		flatten(model,model,flat,Transform3D.IDENTITY)
		var document := GLTFDocument.new()
		var state := GLTFState.new()
		var error := document.append_from_scene(flat,state)
		if error==OK: error=document.write_to_filesystem(state,ART+"blender/input/%s.glb" % id)
		if error!=OK: push_error("Blender input export failed: "+id); quit(1); return
		var spec: Dictionary = Building.SPECS[Building.VARIANTS[id].model if Building.VARIANTS.has(id) else id] if is_building else {}
		var body_offset: Vector3 = model.get_meta("body_offset",Vector3.ZERO)
		record.assets[id]={"base_source":source_path,"material_source_paths":source_map,"material_roles":material_roles,"module_spec":model.get_meta("module_spec",{}),"type":"building" if is_building else ("civic" if catalog.has(id) else "environment"),"lot_metres":[spec.lot.x,spec.lot.y] if is_building else [0,0],"floors":spec.get("floors",0),"height_metres":model.get_meta("height",0),"body_width":model.get_meta("body_width",0),"body_depth":model.get_meta("body_depth",0),"body_offset":[body_offset.x,body_offset.y,body_offset.z]}
		flat.free()
		model.free()
		print("WF_BLENDER_INPUT: "+id)
	var file := FileAccess.open(ART+"blender/source-map.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(record,"\t")+"\n")
	file.close()
	print("WF_BLENDER_INPUT_OK: %d independent source models" % record.assets.size())
	quit()

func flatten(node: Node3D,source_root: Node3D,target: Node3D,parent_transform: Transform3D) -> void:
	var transform := parent_transform*node.transform
	if node is MeshInstance3D:
		var instance := MeshInstance3D.new()
		instance.name="SourceMesh_%05d" % serial
		serial+=1
		instance.mesh=node.mesh
		instance.transform=transform
		var proxy := StandardMaterial3D.new()
		proxy.roughness=1.0
		proxy.cull_mode=BaseMaterial3D.CULL_DISABLED
		var mat: Material = node.material_override
		for role in source_root.mats:
			if source_root.mats[role]==mat: material_roles[String(instance.name)]=role
		if mat is StandardMaterial3D: proxy.albedo_color=mat.albedo_color
		elif mat is ShaderMaterial:
			for key in ["roof_color","stone_color","leaf_color"]:
				var color = mat.get_shader_parameter(key)
				if color is Color: proxy.albedo_color=color
		proxy.resource_name="Proxy_%05d" % serial
		instance.material_override=proxy
		target.add_child(instance)
		instance.owner=target
		source_map[String(instance.name)]=String(source_root.get_path_to(node))
	for child in node.get_children():
		if child is Node3D: flatten(child,source_root,target,transform)
