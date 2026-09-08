extends RefCounted

const REGISTRY := "res://game/whispering_forest/art/city/blender/optimized-models.json"

static func registry() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(REGISTRY)) if FileAccess.file_exists(REGISTRY) else {}

static func instantiate(base: Node3D,record: Dictionary) -> Node3D:
	var optimized: Node3D = load(record.geometry).instantiate()
	for key in base.get_meta_list(): optimized.set_meta(key,base.get_meta(key))
	restore_surface_materials(optimized,base,record)
	base.free()
	return optimized

static func restore_surface_materials(node: Node,base: Node3D,record: Dictionary) -> void:
	if node is MeshInstance3D:
		var id := String(node.name)
		if record.material_source_paths.has(id) and id not in record.overridden_materials:
			var original: MeshInstance3D = base.get_node(record.material_source_paths[id])
			node.material_override=original.material_override
	for child in node.get_children(): restore_surface_materials(child,base,record)
