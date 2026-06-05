class_name SaveableComponent
extends Node


func get_save_key() -> String:
	return name


func to_save_data() -> Dictionary:
	return {}


func from_save_data(data: Dictionary) -> void:
	pass
