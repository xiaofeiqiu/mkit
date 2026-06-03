class_name DialogueNode
extends Resource
@export var node_id: String = ""
@export var speaker_id: String = ""
@export_multiline var text: String = ""
@export var on_enter_effects: Array[GameEffect] = []
@export var choices: Array[DialogueChoice] = []
@export var next_node_id: String = ""
