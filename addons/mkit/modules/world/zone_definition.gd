class_name ZoneDefinition
extends Resource
@export var zone_id: String = ""
@export var display_name: String = ""
@export var scene_path: String = ""
@export var bgm_id: String = ""
@export var default_spawn_id: String = "default"
@export var tags: Array[String] = []


func get_resource_id() -> String:
	return zone_id
