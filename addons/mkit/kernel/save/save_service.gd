class_name SaveService
extends Node
## 说明：`SaveService` 是 存档系统 的存档服务，负责收集根节点、实体和作用域 payload 并写入或恢复存档。
## 上游：通常由同领域服务、controller、组件或内容资源创建或调用。
## 下游：会连接 mkit 的服务、组件、资源或事件管线，不直接依赖具体游戏内容。
## 使用：当项目需要在存档系统中复用这段契约或状态时使用它。
## 示例：`var instance := SaveService.new()`

## 当 `SaveService` 发生 `save completed` 事件时发出，供 UI、音频、VFX、任务或测试订阅。
signal save_completed(path: String)
## 当 `SaveService` 发生 `load completed` 事件时发出，供 UI、音频、VFX、任务或测试订阅。
signal load_completed(path: String)
## 当 `SaveService` 发生 `save failed` 事件时发出，供 UI、音频、VFX、任务或测试订阅。
signal save_failed(path: String, reason: String)
## 当 `SaveService` 发生 `load failed` 事件时发出，供 UI、音频、VFX、任务或测试订阅。
signal load_failed(path: String, reason: String)
## 服务注册 id，供 GameBootstrap、ModuleBootstrap、ServiceRegistry 和 Mkit 查找 `SaveService`。
const SERVICE_ID: String = "save"
## 公开常量 `DEFAULT_SCOPE`，作为 `SaveService` 对外暴露的类型、事件或命令标识。
const DEFAULT_SCOPE: String = "global"
## 公开常量 `CURRENT_SCHEMA_VERSION`，作为 `SaveService` 对外暴露的类型、事件或命令标识。
const CURRENT_SCHEMA_VERSION: int = 2
## 编辑器配置：`save_path` 表示资源或节点路径，由 `SaveService` 的公开 API 读取或维护。
@export var save_path: String = "user://save.json"
## 编辑器配置：`save_version` 表示 `SaveService` 的字段值，由 `SaveService` 的公开 API 读取或维护。
@export var save_version: int = 1
## 编辑器配置：`schema_version` 表示 `SaveService` 的字段值，由 `SaveService` 的公开 API 读取或维护。
@export var schema_version: int = CURRENT_SCHEMA_VERSION
## 编辑器配置：`game_version` 表示 `SaveService` 的字段值，由 `SaveService` 的公开 API 读取或维护。
@export var game_version: String = "0.1.0"
## 编辑器配置：`profile_id` 表示稳定 id，由 `SaveService` 的公开 API 读取或维护。
@export var profile_id: String = "profile_001"
var _registered_scopes: Dictionary = {}


## 保存当前运行时状态，并保持 `SaveService` 的领域契约一致。
func save_game(root: Node) -> bool:
	var roots: Dictionary = {}
	var saveables := _collect_saveables(root)
	var scope_data: Dictionary = {}
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
		"profile_id": profile_id,
		"roots": roots,
		"entities": entities,
		"scopes": scope_data,
	}
	var tmp_path := "%s.tmp" % save_path
	var file := FileAccess.open(tmp_path, FileAccess.WRITE)
	if file == null:
		return _fail_save("Cannot open file for write")
	file.store_string(JSON.stringify(data, "  "))
	file.close()
	var rename_error := DirAccess.rename_absolute(tmp_path, save_path)
	if rename_error != OK:
		DirAccess.remove_absolute(tmp_path)
		return _fail_save("Cannot replace save file: error_%d" % rename_error)
	save_completed.emit(save_path)
	return true


## 加载配置、资源或运行时状态，并保持 `SaveService` 的领域契约一致。
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
	var envelope_error := _validate_save_envelope(data)
	if envelope_error != "":
		load_failed.emit(save_path, envelope_error)
		return false
	var roots := _dictionary_value(data, "roots")
	var entities := _dictionary_value(data, "entities")
	var scopes := _dictionary_value(data, "scopes")
	var root_error := _restore_saveables(root, roots, scopes)
	if root_error != "":
		load_failed.emit(save_path, root_error)
		return false
	var entity_error := _restore_entities(root, entities)
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


func _restore_entities(root: Node, entities: Dictionary) -> String:
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
		if has_record:
			agent.apply_entity_save_record(record)
			if agent.has_save_errors():
				for error in agent.get_save_errors():
					push_warning("SaveService.load_game: %s" % error)
	return ""


## 注册 `saveable_scope`，让后续查询或路由可以找到它，并保持 `SaveService` 的领域契约一致。
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


## 注销 `saveable_scope`，停止后续查询或路由使用它，并保持 `SaveService` 的领域契约一致。
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


## 返回 `registered_scope_snapshot` 对应的数据或对象，并保持 `SaveService` 的领域契约一致。
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


func _validate_save_envelope(data: Dictionary) -> String:
	var found_schema_version := int(data.get("schema_version", 0))
	if found_schema_version <= 0:
		return "Unsupported save schema version: %d" % found_schema_version
	if found_schema_version > schema_version:
		return "Unsupported save schema version: %d" % found_schema_version
	while found_schema_version < schema_version:
		var migrate_error := _migrate_save_envelope(
			data, found_schema_version, found_schema_version + 1
		)
		if migrate_error != "":
			return migrate_error
		found_schema_version = int(data.get("schema_version", found_schema_version + 1))
	if found_schema_version != schema_version:
		return "Unsupported save schema version: %d" % found_schema_version
	for legacy_key in ["payload", "scope_manifest", "save_scopes"]:
		if data.has(legacy_key):
			return "Save file contains legacy field: %s" % legacy_key
	for key in ["roots", "entities", "scopes"]:
		if not data.has(key):
			return "Save file missing current field: %s" % key
		var raw_value = data[key]
		if not (raw_value is Dictionary):
			return "Save file field must be Dictionary: %s" % key
	return ""


func _migrate_save_envelope(
	data: Dictionary, from_schema_version: int, to_schema_version: int
) -> String:
	if from_schema_version == 1 and to_schema_version == 2:
		for legacy_key in ["payload", "scope_manifest", "save_scopes"]:
			if data.has(legacy_key):
				return "Save file contains legacy field: %s" % legacy_key
		if not data.has("roots"):
			data["roots"] = {}
		if not data.has("entities"):
			data["entities"] = {}
		if not data.has("scopes"):
			data["scopes"] = {}
		data["schema_version"] = to_schema_version
		return ""
	push_error(
		(
			"SaveService._migrate_save_envelope: no migration from schema %d to %d"
			% [from_schema_version, to_schema_version]
		)
	)
	return (
		"No save migration from schema version %d to %d"
		% [from_schema_version, to_schema_version]
	)


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
		if ServiceRegistry.get_port(service_id) == node:
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
