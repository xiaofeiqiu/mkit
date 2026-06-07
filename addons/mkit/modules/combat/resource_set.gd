class_name ResourceSet
extends RefCounted
var current: Dictionary = {}
var max_value_provider: Callable = Callable()


func set_max_provider(value: Callable) -> void:
	max_value_provider = value


func get_current(resource_id: String) -> float:
	return float(current.get(resource_id, get_max(resource_id)))


func get_max(resource_id: String) -> float:
	if max_value_provider == null or not max_value_provider.is_valid():
		return 0.0
	return float(max_value_provider.call(resource_id))


func has(resource_id: String, amount: float) -> bool:
	if amount <= 0.0:
		return true
	return get_current(resource_id) >= amount


func set_current(resource_id: String, value: float) -> void:
	var max_value := get_max(resource_id)
	current[resource_id] = clamp(value, 0.0, max_value)


func spend(resource_id: String, amount: float) -> bool:
	if amount <= 0.0:
		return true
	if not has(resource_id, amount):
		return false
	set_current(resource_id, get_current(resource_id) - amount)
	return true


func restore(resource_id: String, amount: float) -> void:
	if amount <= 0.0:
		return
	set_current(resource_id, get_current(resource_id) + amount)


func clear() -> void:
	current.clear()


func to_save_data() -> Dictionary:
	return current.duplicate(true)


func from_save_data(data: Dictionary) -> void:
	current = {}
	for key in data.keys():
		current[str(key)] = float(data.get(key))
