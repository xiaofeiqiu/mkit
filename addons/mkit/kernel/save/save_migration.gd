class_name SaveMigration
extends Resource

@export var from_version: int = 1
@export var to_version: int = 2


func migrate(data: Dictionary) -> Dictionary:
	var migrated := data.duplicate(true)
	migrated["save_version"] = to_version
	return _migrate_impl(migrated)


func _migrate_impl(data: Dictionary) -> Dictionary:
	return data
