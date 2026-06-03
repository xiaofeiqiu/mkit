class_name ItemDefinition
extends Resource
@export var item_id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var item_type: String = "material"
@export var rarity: String = "common"
@export var value: int = 0
@export var icon: Texture2D
@export var stackable: bool = true
@export var max_stack: int = 99
@export var equipment_slot: String = ""
@export var tags: Array[String] = []
@export var use_conditions: Array[Condition] = []
@export var use_effects: Array[GameEffect] = []
@export var stat_modifiers: Array[StatModifierDefinition] = []


func get_resource_id() -> String:
	return item_id
