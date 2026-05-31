class_name Blackboard
extends RefCounted

var _data: Dictionary = {}


func set_value(key: String, value) -> void:
	_data[key] = value


func get_value(key: String, default_value = null):
	if _data.has(key):
		return _data[key]
	return default_value


func has_value(key: String) -> bool:
	return _data.has(key)


func erase_value(key: String) -> void:
	_data.erase(key)


func clear() -> void:
	_data.clear()


func to_debug_dict() -> Dictionary:
	return _data.duplicate(true)
