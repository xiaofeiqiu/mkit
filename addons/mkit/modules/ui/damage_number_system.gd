class_name DamageNumberSystem
extends Node
@export var damage_number_scene_path: String = ""
@export var default_offset: Vector2 = Vector2(0, -24)
@export var use_pool: bool = false
@export var auto_release_seconds: float = 0.0
var _pool: PoolService = null


func show_number(position: Vector2, amount: float, critical: bool = false) -> Node:
	if damage_number_scene_path == "":
		return null
	var node := _create_number_node()
	if node == null:
		return null
	if node is Node2D:
		node.global_position = position + default_offset
	if node.has_method("setup"):
		node.setup(amount, critical)
	if use_pool and _pool != null and auto_release_seconds > 0.0:
		get_tree().create_timer(auto_release_seconds).timeout.connect(
			_release_number.bind(damage_number_scene_path, node)
		)
	return node


func _create_number_node() -> Node:
	if use_pool:
		_pool = ServiceRegistry.get_port(ServiceRegistry.SERVICE_POOL) as PoolService
		if _pool != null:
			return _pool.acquire(damage_number_scene_path, self)
	_pool = null
	var scene := load(damage_number_scene_path) as PackedScene
	if scene == null:
		return null
	var node := scene.instantiate()
	add_child(node)
	return node


func _release_number(scene_path: String, node: Node) -> void:
	if node == null or not is_instance_valid(node) or _pool == null:
		return
	_pool.release(scene_path, node)
