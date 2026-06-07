class_name SaveService
extends Node
signal save_completed(path: String)
signal load_completed(path: String)
signal save_failed(path: String, reason: String)
signal load_failed(path: String, reason: String)
const DEFAULT_SCOPE: String = "global"
@export var save_path: String = "user://save.json"
@export var save_version: int = 1
@export var game_version: String = "0.1.0"
var _registered_scopes: Dictionary = {}


func save_game(root: Node) -> bool:
	var payload := {}
	var saveables := _collect_saveables(root)
	var scope_data: Dictionary = {}
	var scope_manifest: Dictionary = {}
	for saveable in saveables:
		var save_id := saveable.get_save_id()
		if save_id == "":
			continue
		payload[save_id] = saveable.to_save_data()
		for scope in saveable.get_save_scopes():
			var normalized_scope := _normalize_scope(scope)
			var scoped_data: Dictionary = scope_data.get(normalized_scope, {})
			scoped_data[save_id] = saveable.get_save_payload_for_scope(normalized_scope)
			scope_data[normalized_scope] = scoped_data
			var scope_members: Array = scope_manifest.get(normalized_scope, [])
			if not scope_members.has(save_id):
				scope_members.append(save_id)
			scope_manifest[normalized_scope] = scope_members
	for scope_name in scope_manifest.keys():
		var ids: Array = scope_manifest[scope_name]
		ids.sort()
		scope_manifest[scope_name] = ids
	var scope_names: Array = scope_data.keys()
	scope_names.sort()
	var data := {
		"save_version": save_version,
		"game_version": game_version,
		"timestamp": Time.get_datetime_string_from_system(true),
		"profile_id": "profile_001",
		"payload": payload,
		"scopes": scope_data,
		"scope_manifest": scope_manifest,
		"save_scopes": scope_names,
	}
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		save_failed.emit(save_path, "Cannot open file for write")
		return false
	file.store_string(JSON.stringify(data, "  "))
	file.close()
	save_completed.emit(save_path)
	return true


func load_game(root: Node) -> bool:
	if not FileAccess.file_exists(save_path):
		load_failed.emit(save_path, "Save file does not exist")
		return false
	var file := FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		load_failed.emit(save_path, "Cannot open file for read")
		return false
	var text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		load_failed.emit(save_path, "Invalid JSON")
		return false
	var data: Dictionary = parsed
	var payload: Dictionary = data.get("payload", {})
	var scopes: Dictionary = data.get("scopes", {})
	_restore_saveables(root, payload, scopes)
	load_completed.emit(save_path)
	return true


func _collect_saveables(root: Node) -> Array[Saveable]:
	var result: Array[Saveable] = []
	var seen: Dictionary = {}
	if root != null:
		for node in root.find_children("*", "", true, false):
			if node is Saveable:
				var saveable := node as Saveable
				var key := str(saveable.get_instance_id())
				if seen.has(key):
					continue
				seen[key] = true
				result.append(saveable)
	for scope_name in _registered_scopes.keys():
		for registered in _registered_scopes[scope_name]:
			if registered == null:
				continue
			var key := str(registered.get_instance_id())
			if seen.has(key):
				continue
			seen[key] = true
			result.append(registered)
	return result


func _restore_saveables(root: Node, payload: Dictionary, scoped_payload: Dictionary) -> void:
	var saveables := _collect_saveables(root)
	for saveable in saveables:
		var id := saveable.get_save_id()
		if id == "":
			continue
		var restored := false
		for scope in saveable.get_save_scopes():
			var normalized_scope := _normalize_scope(scope)
			var scoped_data: Dictionary = scoped_payload.get(normalized_scope, {})
			if scoped_data is Dictionary and scoped_data.has(id):
				var data: Dictionary = scoped_data[id]
				if data is Dictionary and saveable.apply_save_payload_for_scope(normalized_scope, data):
					restored = true
					break
		if restored:
			continue
		if payload.has(id):
			saveable.from_save_data(payload[id])


func register_saveable_scope(provider: Saveable) -> void:
	if provider == null:
		push_warning("SaveService.register_saveable_scope: provider is null")
		return
	for scope in provider.get_save_scopes():
		var normalized_scope := _normalize_scope(scope)
		var providers: Array = _registered_scopes.get(normalized_scope, [])
		if not providers.has(provider):
			providers.append(provider)
		_registered_scopes[normalized_scope] = providers


func unregister_saveable_scope(provider: Saveable) -> void:
	if provider == null:
		return
	for scope_name in _registered_scopes.keys():
		var providers := _registered_scopes.get(scope_name, [])
		if providers.has(provider):
			providers.erase(provider)
		if providers.is_empty():
			_registered_scopes.erase(scope_name)
		else:
			_registered_scopes[scope_name] = providers


func get_registered_scope_snapshot() -> Dictionary:
	var snapshot: Dictionary = {}
	for scope_name in _registered_scopes.keys():
		var ids: Array = []
		for provider in _registered_scopes[scope_name]:
			var saveable := provider as Saveable
			if saveable == null:
				continue
			var save_id := saveable.get_save_id()
			if save_id != "":
				ids.append(save_id)
		ids.sort()
		snapshot[scope_name] = ids
	return snapshot


func _normalize_scope(scope_name: String) -> String:
	var normalized_scope := scope_name.strip_edges()
	if normalized_scope == "":
		return DEFAULT_SCOPE
	return normalized_scope

