class_name SaveService
extends Node
signal save_completed(path: String)
signal load_completed(path: String)
signal save_failed(path: String, reason: String)
signal load_failed(path: String, reason: String)
@export var save_path: String = "user://save.json"
@export var save_version: int = 1
@export var game_version: String = "0.1.0"
@export var migrations: Array[SaveMigration] = []


func save_game(root: Node) -> bool:
	var payload := _collect_saveables(root)
	var data := {
		"save_version": save_version,
		"game_version": game_version,
		"timestamp": Time.get_datetime_string_from_system(true),
		"profile_id": "profile_001",
		"payload": payload
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
	data = _migrate_data(data)
	var payload: Dictionary = data.get("payload", {})
	_restore_saveables(root, payload)
	load_completed.emit(save_path)
	return true


func _collect_saveables(root: Node) -> Dictionary:
	var result: Dictionary = {}
	for node in root.find_children("*", "", true, false):
		if node is Saveable:
			var saveable := node as Saveable
			result[saveable.get_save_id()] = saveable.to_save_data()
	return result


func _restore_saveables(root: Node, payload: Dictionary) -> void:
	for node in root.find_children("*", "", true, false):
		if node is Saveable:
			var saveable := node as Saveable
			var id := saveable.get_save_id()
			if payload.has(id):
				saveable.from_save_data(payload[id])


func _migrate_data(data: Dictionary) -> Dictionary:
	var current_version := int(data.get("save_version", 1))
	while current_version < save_version:
		var migration := _find_migration(current_version, current_version + 1)
		if migration == null:
			push_warning(
				"Missing save migration: %d -> %d" % [current_version, current_version + 1]
			)
			break
		data = migration.migrate(data)
		current_version = int(data.get("save_version", current_version + 1))
	return data


func _find_migration(from_version: int, to_version: int) -> SaveMigration:
	for migration in migrations:
		if migration.from_version == from_version and migration.to_version == to_version:
			return migration
	return null
