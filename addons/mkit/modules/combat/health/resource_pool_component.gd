class_name ResourcePoolComponent
extends SaveableComponent
signal resource_changed(resource_id: String, current: float, max_value: float)
signal resource_spent(resource_id: String, amount: float)
signal resource_restored(resource_id: String, amount: float)
@export var starting_values: Dictionary = {}
var resources: ResourceSet = null
var stats: StatsComponent = null


func _ready() -> void:
	stats = EntityContract.get_component(owner, "StatsComponent") as StatsComponent
	resources = ResourceSet.new()
	resources.set_max_provider(_resolve_max_resource)
	resources.from_save_data(starting_values)


func get_current(resource_id: String) -> float:
	if resources == null:
		return get_max_resource(resource_id)
	return resources.get_current(resource_id)


func get_max_resource(resource_id: String) -> float:
	if stats == null:
		return 0.0
	return stats.get_stat_value("max_%s" % resource_id, 0.0)


func has_resource(resource_id: String, amount: float) -> bool:
	if resources == null:
		return amount <= 0.0
	return resources.has(resource_id, amount)


func spend(resource_id: String, amount: float) -> bool:
	if resources == null:
		return false
	if not resources.spend(resource_id, amount):
		return false
	set_current(resource_id, resources.get_current(resource_id))
	resource_spent.emit(resource_id, amount)
	return true


func restore(resource_id: String, amount: float) -> void:
	if resources == null:
		return
	var before := resources.get_current(resource_id)
	resources.restore(resource_id, amount)
	var after := resources.get_current(resource_id)
	set_current(resource_id, after)
	resource_restored.emit(resource_id, after - before)


func set_current(resource_id: String, value: float) -> void:
	var max_value := get_max_resource(resource_id)
	if resources == null:
		resources = ResourceSet.new()
		resources.set_max_provider(_resolve_max_resource)
	resources.set_current(resource_id, value)
	resource_changed.emit(resource_id, resources.get_current(resource_id), max_value)


func to_save_data() -> Dictionary:
	if resources == null:
		return {}
	return resources.to_save_data()


func from_save_data(data: Dictionary) -> void:
	if resources == null:
		resources = ResourceSet.new()
		resources.set_max_provider(_resolve_max_resource)
	resources.from_save_data(data)


func _resolve_max_resource(resource_id: String) -> float:
	return get_max_resource(resource_id)
