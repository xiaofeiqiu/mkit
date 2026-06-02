class_name CloudSaveService
extends Node
signal cloud_save_completed(slot: String)
signal cloud_save_failed(slot: String, reason: String)
signal cloud_load_completed(slot: String, data: Dictionary)
signal cloud_load_failed(slot: String, reason: String)


func is_available() -> bool:
	return false


func save_to_cloud(slot: String, data: Dictionary) -> void:
	cloud_save_failed.emit(slot, "not_implemented")


func load_from_cloud(slot: String) -> void:
	cloud_load_failed.emit(slot, "not_implemented")
