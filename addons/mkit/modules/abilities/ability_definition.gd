class_name AbilityDefinition
extends ContentDefinition
@export var ability_id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var icon: Texture2D
@export var cooldown: float = 1.0
@export var charges: int = 1
@export var cost_type: String = "none"
@export var cost_amount: float = 0.0
@export var cast_time: float = 0.0
@export var range: float = 0.0
@export var tags: Array[String] = []
@export var conditions: Array[Condition] = []
@export var effects: Array[GameEffect] = []


func get_content_id() -> String:
	return ability_id
