class_name VFXSpawner
extends Node
@export var vfx_scene_map: Dictionary = {}
@export var auto_free_seconds: float = 2.0


func spawn(vfx_id: String, position: Vector2, direction: Vector2 = Vector2.ZERO) -> Node:
	if not vfx_scene_map.has(vfx_id):
		return null
	var scene := load(vfx_scene_map[vfx_id]) as PackedScene
	if scene == null:
		return null
	var node := scene.instantiate()
	add_child(node)
	if node is Node2D:
		node.global_position = position
		if direction != Vector2.ZERO:
			node.rotation = direction.angle()
	if node.has_method("play"):
		node.play()
	if auto_free_seconds > 0.0:
		get_tree().create_timer(auto_free_seconds).timeout.connect(node.queue_free)
	return node
