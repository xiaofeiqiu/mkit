class_name LootTableDefinition
extends Resource

@export var loot_table_id: String = ""
@export var rolls: int = 1
@export var entries: Array[LootEntry] = []
@export var allow_empty: bool = true
@export var empty_weight: float = 0.0


func get_resource_id() -> String:
	return loot_table_id
