class_name Saveable
extends Node
@export var save_id: String = ""
@export var save_scope: String = ""
@export var restore_order: int = 0


func get_save_scope() -> String:
	var normalized_scope := save_scope.strip_edges()
	if normalized_scope == "":
		return "global"
	return normalized_scope


func get_save_scopes() -> Array[String]:
	return [get_save_scope()]


func get_save_payload_for_scope(scope: String) -> Dictionary:
	if get_save_scope() == scope.strip_edges():
		return to_save_data()
	return {}


func apply_save_payload_for_scope(scope: String, data: Dictionary) -> bool:
	if get_save_scope() != scope.strip_edges():
		return false
	from_save_data(data)
	return true


## Helpers for subclasses that provide multi-scope payloads: call from
## _ready / _exit_tree to keep SaveService scope registration in sync.
func register_save_scopes() -> void:
	var save_service := ServiceRegistry.get_port(ServiceRegistry.SERVICE_SAVE) as SaveService
	if save_service != null:
		save_service.register_saveable_scope(self)


func unregister_save_scopes() -> void:
	var save_service := ServiceRegistry.get_port(ServiceRegistry.SERVICE_SAVE) as SaveService
	if save_service != null:
		save_service.unregister_saveable_scope(self)


func get_save_id() -> String:
	if save_id == "":
		return owner.name if owner != null else name
	return save_id


func to_save_data() -> Dictionary:
	return {}


func from_save_data(data: Dictionary) -> void:
	pass
