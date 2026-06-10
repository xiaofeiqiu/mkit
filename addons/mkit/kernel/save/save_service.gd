class_name SaveService
extends Node
signal save_completed(path: String)
signal load_completed(path: String)
signal save_failed(path: String, reason: String)
signal load_failed(path: String, reason: String)
const DEFAULT_SCOPE: String = "global"
const CURRENT_SCHEMA_VERSION: int = 2
@export var save_path: String = "user://save.json"
@export var save_version: int = 1
@export var schema_version: int = CURRENT_SCHEMA_VERSION
@export var game_version: String = "0.1.0"
var _registered_scopes: Dictionary = {}


func save_game(root: Node) -> bool:
	var roots: Dictionary = {}
	var saveables := _collect_saveables(root)
	var scope_data: Dictionary = {}
	var scope_manifest: Dictionary = {}
	for saveable in saveables:
		var save_id := saveable.get_save_id()
		if save_id == "":
			push_warning("SaveService.save_game: skipping Saveable with empty save id")
			continue
		if roots.has(save_id):
			return _fail_save("Duplicate root save id: %s" % save_id)
		roots[save_id] = saveable.to_save_data()
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
	var entities: Dictionary = {}
	for agent in _collect_entity_agents(root):
		var entity_id := agent.get_entity_id()
		if entity_id == "":
			push_warning("SaveService.save_game: skipping EntitySaveAgent with empty entity id")
			continue
		if entities.has(entity_id):
			return _fail_save("Duplicate entity save id: %s" % entity_id)
		var record := agent.to_entity_save_record()
		if agent.has_save_errors():
			return _fail_save(_format_errors(agent.get_save_errors()))
		entities[entity_id] = record
	var data := {
		"schema_version": schema_version,
		"save_version": save_version,
		"game_version": game_version,
		"timestamp": Time.get_datetime_string_from_system(true),
		"profile_id": "profile_001",
		"roots": roots,
		"entities": entities,
		"payload": roots,
		"scopes": scope_data,
		"scope_manifest": scope_manifest,
		"save_scopes": scope_names,
	}
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		return _fail_save("Cannot open file for write")
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
	var data := _migrate_save_payload(parsed)
	var roots := _dictionary_value(data, "roots")
	var legacy_payload := _dictionary_value(data, "payload")
	if roots.is_empty() and not legacy_payload.is_empty():
		roots = legacy_payload
	var entities := _dictionary_value(data, "entities")
	var scopes := _dictionary_value(data, "scopes")
	var root_error := _restore_saveables(root, roots, scopes)
	if root_error != "":
		load_failed.emit(save_path, root_error)
		return false
	var entity_error := _restore_entities(root, entities, roots)
	if entity_error != "":
		load_failed.emit(save_path, entity_error)
		return false
	load_completed.emit(save_path)
	return true


func _collect_saveables(root: Node) -> Array[Saveable]:
	var result: Array[Saveable] = []
	var seen: Dictionary = {}
	if root != null:
		for node in root.find_children("*", "", true, false):
			if node.is_queued_for_deletion():
				continue
			if _is_inactive_service_registry_child(node):
				continue
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
			if registered.is_queued_for_deletion():
				continue
			if _is_inactive_service_registry_child(registered):
				continue
			var key := str(registered.get_instance_id())
			if seen.has(key):
				continue
			seen[key] = true
			result.append(registered)
	result.sort_custom(
		func(left: Saveable, right: Saveable) -> bool:
			return _restore_order(left) < _restore_order(right)
	)
	return result


func _collect_entity_agents(root: Node) -> Array[EntitySaveAgent]:
	var result: Array[EntitySaveAgent] = []
	var seen: Dictionary = {}
	if root != null:
		for node in root.find_children("*", "", true, false):
			if node.is_queued_for_deletion():
				continue
			if node is EntitySaveAgent:
				var agent := node as EntitySaveAgent
				var key := str(agent.get_instance_id())
				if seen.has(key):
					continue
				seen[key] = true
				result.append(agent)
	result.sort_custom(
		func(left: EntitySaveAgent, right: EntitySaveAgent) -> bool:
			return _restore_order(left) < _restore_order(right)
	)
	return result


func _restore_saveables(root: Node, roots: Dictionary, scoped_payload: Dictionary) -> String:
	var saveables := _collect_saveables(root)
	var seen: Dictionary = {}
	for saveable in saveables:
		var id := saveable.get_save_id()
		if id == "":
			continue
		if seen.has(id):
			return "Duplicate root save id: %s" % id
		seen[id] = true
		var restored := false
		for scope in saveable.get_save_scopes():
			var normalized_scope := _normalize_scope(scope)
			var scoped_data := _dictionary_value(scoped_payload, normalized_scope)
			if scoped_data is Dictionary and scoped_data.has(id):
				var raw_data = scoped_data[id]
				if raw_data is Dictionary:
					var scoped_root_data: Dictionary = raw_data
					if saveable.apply_save_payload_for_scope(normalized_scope, scoped_root_data):
						restored = true
		if not restored and roots.has(id):
			var raw_root_data = roots[id]
			if raw_root_data is Dictionary:
				var root_data: Dictionary = raw_root_data
				saveable.from_save_data(root_data)
	return ""


func _restore_entities(root: Node, entities: Dictionary, legacy_roots: Dictionary) -> String:
	var seen: Dictionary = {}
	for agent in _collect_entity_agents(root):
		var entity_id := agent.get_entity_id()
		if entity_id == "":
			continue
		if seen.has(entity_id):
			return "Duplicate entity save id: %s" % entity_id
		seen[entity_id] = true
		var record: Dictionary = {}
		var has_record := false
		if entities.has(entity_id):
			var raw_record = entities[entity_id]
			if not (raw_record is Dictionary):
				return "Invalid entity payload for id: %s" % entity_id
			var entity_record: Dictionary = raw_record
			record = entity_record
			has_record = true
		elif legacy_roots.has(entity_id):
			record = _legacy_entity_record(legacy_roots[entity_id])
			has_record = not record.is_empty()
		if has_record:
			agent.apply_entity_save_record(record)
			if agent.has_save_errors():
				for error in agent.get_save_errors():
					push_warning("SaveService.load_game: %s" % error)
	return ""


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


func _migrate_save_payload(data: Dictionary) -> Dictionary:
	var migrated := data.duplicate(true)
	if not migrated.has("roots"):
		var raw_payload = migrated.get("payload", {})
		if raw_payload is Dictionary:
			var legacy_payload: Dictionary = raw_payload
			migrated["roots"] = legacy_payload.duplicate(true)
		else:
			migrated["roots"] = {}
	if not migrated.has("entities"):
		migrated["entities"] = {}
	return migrated


func _legacy_entity_record(raw_data: Variant) -> Dictionary:
	if not (raw_data is Dictionary):
		return {}
	var data: Dictionary = raw_data
	if data.has("components"):
		return data
	return {"components": data}


func _dictionary_value(data: Dictionary, key: String) -> Dictionary:
	var raw_value = data.get(key, {})
	if raw_value is Dictionary:
		var value: Dictionary = raw_value
		return value
	return {}


func _restore_order(node: Node) -> int:
	var value: Variant = node.get("restore_order")
	if value == null:
		return 0
	return int(value)


func _is_inactive_service_registry_child(node: Node) -> bool:
	if ServiceRegistry == null:
		return false
	if node.get_parent() != ServiceRegistry:
		return false
	for service_id in ServiceRegistry.get_registered_service_ids():
		if ServiceRegistry.get_service_or_null(service_id) == node:
			return false
	return true


func _format_errors(errors: Array[String]) -> String:
	var result := ""
	for error in errors:
		if result != "":
			result += "; "
		result += error
	return result


func _fail_save(reason: String) -> bool:
	push_error(reason)
	save_failed.emit(save_path, reason)
	return false


func _normalize_scope(scope_name: String) -> String:
	var normalized_scope := scope_name.strip_edges()
	if normalized_scope == "":
		return DEFAULT_SCOPE
	return normalized_scope
