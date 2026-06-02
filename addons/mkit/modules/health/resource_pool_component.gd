class_name ResourcePoolComponent
extends Node
signal resource_changed(resource_id: String, current: float, max_value: float)
signal resource_spent(resource_id: String, amount: float)
signal resource_restored(resource_id: String, amount: float)
@export var starting_values: Dictionary = {}
var current_values: Dictionary = {}
var stats: StatsComponent = null


func _ready() -> void:
	stats = owner.get_node_or_null("Components/StatsComponent") as StatsComponent
	current_values = starting_values.duplicate(true)
	for resource_id in current_values.keys():
		set_current(str(resource_id), float(current_values[resource_id]))


func get_current(resource_id: String) -> float:
	return float(current_values.get(resource_id, get_max_resource(resource_id)))


func get_max_resource(resource_id: String) -> float:
	if stats == null:
		return 0.0
	return stats.get_stat_value("max_%s" % resource_id, 0.0)


func has_resource(resource_id: String, amount: float) -> bool:
	if amount <= 0.0:
		return true
	return get_current(resource_id) >= amount


func spend(resource_id: String, amount: float) -> bool:
	if not has_resource(resource_id, amount):
		return false
	set_current(resource_id, get_current(resource_id) - amount)
	resource_spent.emit(resource_id, amount)
	return true


func restore(resource_id: String, amount: float) -> void:
	if amount <= 0.0:
		return
	set_current(resource_id, get_current(resource_id) + amount)
	resource_restored.emit(resource_id, amount)


func set_current(resource_id: String, value: float) -> void:
	var max_value := get_max_resource(resource_id)
	current_values[resource_id] = clamp(value, 0.0, max_value)
	resource_changed.emit(resource_id, current_values[resource_id], max_value)


func to_save_data() -> Dictionary:
	return current_values.duplicate(true)


func from_save_data(data: Dictionary) -> void:
	current_values = data.duplicate(true)
	for resource_id in current_values.keys():
		set_current(str(resource_id), float(current_values[resource_id]))
