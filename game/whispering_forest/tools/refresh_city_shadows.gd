extends SceneTree

const Shadow = preload("res://game/whispering_forest/art/city/shadow_geometry.gd")
const BlenderSource = preload("res://game/whispering_forest/art/city/blender_source.gd")
const ROOT := "res://game/whispering_forest/assets/city-built/"

func _initialize() -> void:
	var frames: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ROOT+"frames.json"))
	var models := {}
	var optimized := BlenderSource.registry()
	for id in frames:
		var data: Dictionary = frames[id]
		if not models.has(data.source):
			var base_id: String = data.source.get_file().get_basename()
			var model: Node3D = load(data.source).instantiate()
			models[data.source]=BlenderSource.instantiate(model,optimized[base_id]) if optimized.has(base_id) else model
		var model: Node3D = models[data.source]
		model.rotation.y=deg_to_rad(data.rotation_degrees)
		var anchor := Vector3(data.footprint[0],0,data.footprint[1])/64 if data.category=="building" else Vector3.ZERO
		data.shadow_outline=Shadow.outline(model,anchor)
	for model in models.values(): model.free()
	var file := FileAccess.open(ROOT+"frames.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(frames,"\t")+"\n")
	file.close()
	file=FileAccess.open(ROOT+"frames.gd",FileAccess.WRITE)
	file.store_string("extends RefCounted\n\nconst FRAMES := "+JSON.stringify(frames,"\t")+"\n")
	file.close()
	print("WF_CITY_SHADOWS_OK: %d silhouettes projected with shared world sun" % frames.size())
	quit()
