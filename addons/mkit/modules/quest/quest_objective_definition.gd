class_name QuestObjectiveDefinition
extends Resource
@export var objective_id: String = ""
@export_multiline var description: String = ""
@export var event_type: String = ""
@export var match_key: String = ""
@export var match_value: String = ""
@export var count_payload_key: String = ""
@export var required_count: int = 1
@export var optional: bool = false
