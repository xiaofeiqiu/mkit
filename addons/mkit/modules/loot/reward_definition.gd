class_name RewardDefinition
extends Resource
@export var reward_id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var icon: Texture2D
@export var rarity: String = "common"
@export var weight: float = 1.0
@export var conditions: Array[Condition] = []
@export var effects: Array[GameEffect] = []


func get_resource_id() -> String:
	return reward_id
