class_name RoomDefinition
extends ContentDefinition
@export var room_id: String = ""
@export var scene_path: String = ""
@export var room_type: String = "combat"
@export var difficulty_rating: int = 1
@export var size: Vector2i = Vector2i(1, 1)
@export var tags: Array[String] = []
@export var enemy_spawn_ids: Array[String] = []
@export var reward_pool_ids: Array[String] = []


func get_content_id() -> String:
	return room_id
