class_name VFXSpawner
extends Node
@export var vfx_scene_map: Dictionary = {}
@export var auto_free_seconds: float = 2.0
@export var use_pool: bool = false
var _pool: ObjectPool = null


func spawn(vfx_id: String, position: Vector2, direction: Vector2 = Vector2.ZERO) -> Node:
	if not vfx_scene_map.has(vfx_id):
		return null
	var scene_path := str(vfx_scene_map[vfx_id])
	var node := _create_vfx_node(scene_path)
	if node == null:
		return null
	if node is Node2D:
		node.global_position = position
		if direction != Vector2.ZERO:
			node.rotation = direction.angle()
	if node.has_method("play"):
		node.play()
	if auto_free_seconds > 0.0:
		if use_pool and _pool != null:
			get_tree().create_timer(auto_free_seconds).timeout.connect(
				_release_vfx.bind(scene_path, node)
			)
		else:
			get_tree().create_timer(auto_free_seconds).timeout.connect(node.queue_free)
	return node


func _create_vfx_node(scene_path: String) -> Node:
	if use_pool and ServiceRegistry.has_service("pool"):
		_pool = ServiceRegistry.get_service("pool") as ObjectPool
		if _pool != null:
			return _pool.acquire(scene_path, self)
	_pool = null
	var scene := load(scene_path) as PackedScene
	if scene == null:
		return null
	var node := scene.instantiate()
	add_child(node)
	return node


func _release_vfx(scene_path: String, node: Node) -> void:
	if node == null or not is_instance_valid(node) or _pool == null:
		return
	_pool.release(scene_path, node)
