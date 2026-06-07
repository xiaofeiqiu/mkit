extends Saveable


const RESTORE_ORDER: Array[String] = [
	"StatsComponent",
	"StatusEffectController",
	"EquipmentController",
	"HealthComponent",
	"ResourcePoolComponent",
	"AbilityController",
	"InventoryController"
]

@export var target_path: NodePath = NodePath("")


func to_save_data() -> Dictionary:
	var target := _target()
	if target == null:
		return {}
	var components: Dictionary = {}
	_collect_saveable_components(target.get_node_or_null("Components"), components)
	_collect_saveable_components(target.get_node_or_null("Controllers"), components)
	_filter_equipment_modifiers(components)
	return {
		"position": _serialize_position(target),
		"components": components
	}


func from_save_data(data: Dictionary) -> void:
	var target := _target()
	if target == null:
		return
	_restore_position(target, data.get("position", {}))
	var components: Dictionary = data.get("components", {})
	for component_key in RESTORE_ORDER:
		_restore_component(target, component_key, components)
	for component_key in components.keys():
		var key := str(component_key)
		if not RESTORE_ORDER.has(key):
			_restore_component(target, key, components)


func _target() -> Node:
	if target_path != NodePath("") and has_node(target_path):
		return get_node(target_path)
	return owner


func _serialize_position(target: Node) -> Dictionary:
	if target is Node2D:
		return {
			"x": (target as Node2D).global_position.x,
			"y": (target as Node2D).global_position.y
		}
	return {}


func _restore_position(target: Node, raw_position: Variant) -> void:
	if not (target is Node2D) or not (raw_position is Dictionary):
		return
	var position: Dictionary = raw_position
	var node := target as Node2D
	node.global_position = Vector2(
		float(position.get("x", node.global_position.x)),
		float(position.get("y", node.global_position.y))
	)


func _collect_saveable_components(container: Node, components: Dictionary) -> void:
	if container == null:
		return
	for child in container.get_children():
		if child is SaveableComponent:
			var component := child as SaveableComponent
			components[component.get_save_key()] = component.to_save_data()


func _filter_equipment_modifiers(components: Dictionary) -> void:
	if not components.has("StatsComponent") or not components.has("EquipmentController"):
		return
	var stats_data: Dictionary = components["StatsComponent"]
	var equipment_data: Dictionary = components["EquipmentController"]
	var equipment_sources := _equipment_source_ids(equipment_data)
	if equipment_sources.is_empty():
		return
	var filtered: Array = []
	for raw in stats_data.get("persistent_modifiers", []):
		if raw is Dictionary and equipment_sources.has(str(raw.get("source_id", ""))):
			continue
		filtered.append(raw)
	stats_data["persistent_modifiers"] = filtered
	components["StatsComponent"] = stats_data


func _equipment_source_ids(equipment_data: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	var slots: Dictionary = equipment_data.get("slots", {})
	for raw in slots.values():
		if raw is Dictionary:
			var instance_id := str(raw.get("instance_id", ""))
			if instance_id != "":
				result[instance_id] = true
	return result


func _restore_component(target: Node, component_key: String, components: Dictionary) -> void:
	if not components.has(component_key):
		return
	var component := _find_component(target, component_key)
	if component == null:
		return
	var data: Variant = components[component_key]
	if data is Dictionary:
		component.from_save_data(data)


func _find_component(target: Node, component_key: String) -> SaveableComponent:
	var component := (
		target.get_node_or_null("Components/%s" % component_key) as SaveableComponent
	)
	if component != null:
		return component
	return target.get_node_or_null("Controllers/%s" % component_key) as SaveableComponent
