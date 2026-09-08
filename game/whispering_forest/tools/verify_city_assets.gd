extends SceneTree

# Read real pixels, sources and scene references. No renderer mocks and no
# synthetic assertion that a successful file write means an accepted picture.
const Art = preload("res://game/whispering_forest/scripts/city_art.gd")
const ART := Art.ROOT
const Config = preload("res://game/whispering_forest/art/city/render_config.gd")
const Building = preload("res://game/whispering_forest/art/city/building_model.gd")
const Civic = preload("res://game/whispering_forest/art/city/civic_model.gd")
const Nature = preload("res://game/whispering_forest/art/city/environment_model.gd")
const City = preload("res://game/whispering_forest/scripts/city.gd")
var failures: Array[String] = []
var verified := 0

func _initialize() -> void:
	verify.call_deferred()

func check(ok: bool,message: String) -> void:
	if not ok: failures.append(message)

func verify() -> void:
	var frames: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ART+"frames.json"))
	var dependencies: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ART+"surface-dependencies.json"))
	var surface_hash := FileAccess.get_sha256(ART+"surface-dependencies.json")
	for path in dependencies:
		check(FileAccess.get_sha256(path)==dependencies[path],"changed surface dependency: "+path)
	var catalog := Building.SPECS.keys()+Building.VARIANTS.keys()+Nature.KINDS+Civic.catalog().keys()
	var blends := {}
	var expected_count := 0
	for id in catalog:
		var rotations := [0] if id in Nature.KINDS else [0,90,180,270]
		for degrees in rotations:
			expected_count+=1
			var key: String = id+("_r%d" % degrees if degrees else "")
			check(frames.has(key),"missing direction: "+key)
			if not frames.has(key): continue
			var f: Dictionary = frames[key]
			var picture := Image.load_from_file(ProjectSettings.globalize_path(ART+key+".png"))
			check(not picture.is_empty(),"unreadable PNG: "+key)
			if picture.is_empty(): continue
			check(picture.get_format()==Image.FORMAT_RGBA8,"missing real RGBA alpha: "+key)
			var used := picture.get_used_rect()
			check(used.position.x>=3 and used.position.y>=3 and used.end.x<=picture.get_width()-3 and used.end.y<=picture.get_height()-3,"clipped silhouette: "+key)
			check(Vector2i(f.region[2],f.region[3])==picture.get_size(),"frame dimensions disagree: "+key)
			check(f.render_config.sha256==Config.digest(),"stale common camera/light profile: "+key)
			check(f.surface_signature==surface_hash,"stale paint/shader pixels: "+key)
			check(f.source_sha256==FileAccess.get_sha256(f.source),"stale source geometry: "+key)
			check(f.rotation_degrees==degrees and is_equal_approx(f.scale,0.5),"unexpected orientation or image scaling: "+key)
			check(not f.baked_ground_shadow and f.ground_shadow=="runtime_ground_layer","duplicate ground shadow policy: "+key)
			if f.has("architecture_source"):
				check(f.architecture_sha256==FileAccess.get_sha256(f.architecture_source),"changed architectural source: "+key)
				check(f.through_opening_count>0 and f.opening_mesh_ray_checks==f.through_opening_count*2,"missing wall opening geometry audit: "+key)
				var landing := Vector2(f.door[0],f.door[1])
				var threshold := Vector2(f.door_threshold[0],f.door_threshold[1])
				var normal := Vector2(f.door_normal[0],f.door_normal[1])
				check(landing.distance_to(threshold+normal*f.door_approach)<0.002,"recessed entrance approach mismatch: "+key)
			if f.has("shadow_texture"):
				var shadow := Image.load_from_file(ART+f.shadow_texture)
				check(not shadow.is_empty() and shadow.get_format()==Image.FORMAT_RGBA8,"invalid projected shadow: "+key)
				check(FileAccess.get_sha256(ART+f.shadow_texture)==f.shadow_sha256,"stale projected shadow: "+key)
				check(shadow.get_size()==Vector2i(f.shadow_size[0],f.shadow_size[1]),"shadow metadata mismatch: "+key)
			if f.has("editable_source"):
				blends[f.editable_source]=true
				check(f.blend_sha256==FileAccess.get_sha256(f.editable_source),"changed Blender source: "+key)
				check(f.geometry_sha256==FileAccess.get_sha256(f.geometry_source),"changed Blender GLB: "+key)
			# Independently project the recorded ground anchor into the original
			# canvas. This catches crop-origin drift across rotated models.
			var expected := Vector2(Config.DATA.canvas,Config.DATA.canvas)*0.5
			expected.y+=Config.DATA.camera_target.y*32.0*sqrt(2.0)*2.0*cos(PI/6)
			if f.category=="building":
				expected+=Vector2(f.footprint[0]-f.footprint[1],(f.footprint[0]+f.footprint[1])*0.5)
				var original: Array = frames[id].footprint
				var footprint := Vector2(original[0],original[1]) if degrees in [0,180] else Vector2(original[1],original[0])
				check(footprint.distance_to(Vector2(f.footprint[0],f.footprint[1]))<0.001,"direction footprint mismatch: "+key)
			var recorded := Vector2(f.pivot[0]+f.crop_origin[0],f.pivot[1]+f.crop_origin[1])
			check(recorded.distance_to(expected)<0.03,"ground pivot/projection mismatch: "+key)
			verified+=1
	check(frames.size()==expected_count,"unexpected or missing active assets")
	check(blends.size()==30,"expected 30 independent editable Blender models")
	var layout: Node2D = load("res://game/whispering_forest/city_layout.tscn").instantiate()
	root.add_child(layout)
	await process_frame
	var placed_assets := {"waystone":true}
	for child in layout.get_children():
		check(child.get_script()!=null,"scene child has no working script: "+str(child.name))
		var asset = child.get("asset")
		if asset is String and frames.has(asset): placed_assets[asset]=true
		if child.name=="RaisedCurbsAndRoundedCorners":
			for piece in child.placements: placed_assets[piece.asset]=true
		if child.has_method("asset_id"):
			check(frames.has(child.asset_id()),"architecture fell back to legacy drawing: "+str(child.name))
			if child.kind in ["wall_u","wall_v","fence_u","fence_v"]:
				var module_spec: Dictionary = frames[child.asset_id()].module_spec
				check(absf(module_spec.length-child.length)<0.002,"stretched module or endpoint mismatch: "+str(child.name))
	for b in City.BUILDINGS:
		var node := layout.get_node(NodePath(b.id))
		check(node.asset==b.asset and node.ground==b.at,"layout not rebuilt: "+b.id)
		check(node.footprint.distance_to(City.footprint(b).size)<0.01,"collision disagrees with render footprint: "+b.id)
	var report := {"checked_frames":verified,"independent_models":catalog.size(),"blender_sources":blends.size(),"layout_objects":layout.get_child_count(),"profile":Config.VERSION,"profile_sha256":Config.digest(),"surface_signature":surface_hash,"failures":failures,"visual_review":"Separate real-engine screenshots; technical checks do not assert concept-quality acceptance."}
	report.placed_asset_ids=placed_assets.keys()
	var file := FileAccess.open("res://game/whispering_forest/preview/city-asset-verification.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t")+"\n")
	file.close()
	for failure in failures: push_error("WF_CITY_ASSET_FAILED: "+failure)
	print("WF_CITY_ASSETS_OK: %d frames, %d editable Blender sources, %d scene objects" % [verified,blends.size(),layout.get_child_count()] if failures.is_empty() else "WF_CITY_ASSET_FAILED: %d" % failures.size())
	layout.queue_free()
	quit(0 if failures.is_empty() else 1)
