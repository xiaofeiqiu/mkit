class_name DialogueChoice
extends Resource
@export_multiline var text: String = ""
@export var next_node_id: String = ""
@export var conditions: Array[Condition] = []
@export var effects: Array[GameEffect] = []
