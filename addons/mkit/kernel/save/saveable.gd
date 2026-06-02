class_name Saveable
extends Node
@export var save_id: String = ""


func get_save_id() -> String:
	if save_id == "":
		return owner.name if owner != null else name
	return save_id


func to_save_data() -> Dictionary:
	return {}


func from_save_data(data: Dictionary) -> void:
	pass
