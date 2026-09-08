extends RefCounted

const SpriteBase = preload("res://game/whispering_forest/scripts/city_sprite.gd")
const GroundBase = preload("res://game/whispering_forest/scripts/city_ground.gd")
const ArchitectureBase = preload("res://game/whispering_forest/scripts/architecture.gd")
const SpriteDetail = preload("res://game/whispering_forest/scripts/city_detail_sprite.gd")
const GroundDetail = preload("res://game/whispering_forest/scripts/city_detail_ground.gd")
const ArchitectureDetail = preload("res://game/whispering_forest/scripts/city_detail_architecture.gd")
const Catalog = preload("res://game/whispering_forest/scripts/city_detail_catalog.gd")

# Apply before entering the tree. Preserve the current authored layout and
# original scripts; this adapter also works after the base layout is rebuilt.
static func apply(layout: Node2D) -> void:
	for original in layout.get_children():
		var replacement: Node2D
		var fields: Array[String] = []
		if original.get_script()==SpriteBase and not Catalog.key(original.asset,original.building_id,original.ground).is_empty():
			replacement=SpriteDetail.new()
			fields.assign(["asset","ground","width","footprint","radius","building_id","title_zh","title_en","fadeable"])
		elif original.get_script()==GroundBase:
			replacement=GroundDetail.new()
		elif original.get_script()==ArchitectureBase:
			replacement=ArchitectureDetail.new()
			fields.assign(["kind","ground","length","wall_height","variant"])
		else: continue
		var index: int = original.get_index()
		var prop_name: String = original.name
		for field in fields: replacement.set(field,original.get(field))
		replacement.z_index=original.z_index
		layout.remove_child(original)
		original.free()
		replacement.name=prop_name
		layout.add_child(replacement)
		layout.move_child(replacement,index)
		replacement.owner=layout
