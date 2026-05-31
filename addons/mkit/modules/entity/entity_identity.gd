class_name EntityIdentity
extends Node

@export var entity_id: String = ""
@export var definition_id: String = ""
@export var display_name: String = ""
@export var faction: String = "neutral"
@export var tags: Array[String] = []


func _ready() -> void:
	if entity_id == "":
		entity_id = "%s_%d" % [name.to_snake_case(), Time.get_ticks_usec()]


func has_tag(tag: String) -> bool:
	return tags.has(tag)


func has_any_tag(input_tags: Array[String]) -> bool:
	for tag in input_tags:
		if tags.has(tag):
			return true
	return false


func is_faction(value: String) -> bool:
	return faction == value
