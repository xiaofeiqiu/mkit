class_name SpawnSceneEffect
extends GameEffect
@export var scene_path: String = ""
@export var spawn_at_target: bool = false
@export var use_pool: bool = false


func _apply_impl(context: GameplayContext) -> EffectResult:
	if scene_path == "":
		return EffectResult.fail(effect_id, "missing_scene_path")
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.current_scene == null:
		return EffectResult.fail(effect_id, "no_scene_tree")
	var pool: PoolService = null
	if use_pool:
		pool = ServiceRegistry.get_port(ServiceRegistry.SERVICE_POOL) as PoolService
	var instance := _create_spawn_instance(tree.current_scene, pool)
	if instance == null:
		return EffectResult.fail(effect_id, "cannot_load_scene")
	var spawn_pos := context.position
	if spawn_at_target and context.target != null and context.target is Node2D:
		spawn_pos = (context.target as Node2D).global_position
	elif context.source != null and context.source is Node2D:
		spawn_pos = (context.source as Node2D).global_position
	if instance.get_parent() == null:
		tree.current_scene.add_child(instance)
	if instance is Node2D:
		(instance as Node2D).global_position = spawn_pos
		if context.direction != Vector2.ZERO and instance.has_method("set_direction"):
			instance.call("set_direction", context.direction)
	return EffectResult.ok(effect_id, {"spawned": instance.name, "pooled": pool != null})


func _create_spawn_instance(parent: Node, pool: PoolService) -> Node:
	if pool != null:
		return pool.acquire(scene_path, parent)
	var packed := load(scene_path) as PackedScene
	if packed == null:
		return null
	return packed.instantiate()
