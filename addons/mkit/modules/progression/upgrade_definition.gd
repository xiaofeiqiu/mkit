class_name UpgradeDefinition
extends Resource

@export var upgrade_id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var max_level: int = 1
@export var currency_id: String = "meta_currency"
@export var cost_by_level: Array[int] = [100]
@export var prerequisite_upgrade_ids: Array[String] = []
@export var unlock_content_ids: Array[String] = []
@export var effects: Array[GameEffect] = []
@export var tags: Array[String] = []
@export var is_meta_upgrade: bool = true


func get_cost_for_level(next_level: int) -> int:
	var index := max(0, next_level - 1)
	if index >= cost_by_level.size():
		return cost_by_level[-1] if not cost_by_level.is_empty() else 0
	return cost_by_level[index]
