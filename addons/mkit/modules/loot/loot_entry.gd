class_name LootEntry
extends Resource

@export var content_id: String = ""
@export var weight: float = 1.0
@export var min_quantity: int = 1
@export var max_quantity: int = 1
@export var conditions: Array[Condition] = []
