class_name SpawnPoint
extends Marker2D
const GROUP: String = "spawn_point"
@export var spawn_id: String = "default"


func _ready() -> void:
	add_to_group(GROUP)
