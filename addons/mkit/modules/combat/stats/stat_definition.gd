class_name StatDefinition
extends ContentDefinition
@export var stat_id: String = ""
@export var display_name: String = ""
@export var default_value: float = 0.0
@export var min_value: float = -INF
@export var max_value: float = INF
@export var is_percent: bool = false


func get_content_id() -> String:
	return stat_id
