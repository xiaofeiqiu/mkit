class_name SpawnSceneEffect
extends GameEffect
## 说明：`SpawnSceneEffect` 是 效果管线 的效果对象，负责由 EffectService 执行并把结果落到服务或组件。
## 上游：通常由 GameAction、EffectService、对话、任务、物品或奖励定义创建或调用。
## 下游：会连接GameplayContext、ConditionEvaluator、领域服务和 EffectResult，不直接依赖具体游戏内容。
## 使用：当项目内容资源需要以数据驱动方式改变世界、实体或服务状态时使用它。
## 示例：`var instance := SpawnSceneEffect.new()`

## 编辑器配置：`scene_path` 表示场景路径，由 `SpawnSceneEffect` 的公开 API 读取或维护。
@export var scene_path: String = ""
## 编辑器配置：`spawn_at_target` 表示 `SpawnSceneEffect` 的字段值，由 `SpawnSceneEffect` 的公开 API 读取或维护。
@export var spawn_at_target: bool = false
## 编辑器配置：`use_pool` 表示 `SpawnSceneEffect` 的字段值，由 `SpawnSceneEffect` 的公开 API 读取或维护。
@export var use_pool: bool = false


## 子类覆写的实际效果入口，并保持 `SpawnSceneEffect` 的领域契约一致。
func _apply_impl(context: GameplayContext) -> EffectResult:
	if scene_path == "":
		return EffectResult.fail(effect_id, "missing_scene_path")
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.current_scene == null:
		return EffectResult.fail(effect_id, "no_scene_tree")
	var pool: PoolService = null
	if use_pool:
		pool = ServiceRegistry.get_port(PoolService.SERVICE_ID) as PoolService
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
	return EffectResult.ok(
		effect_id,
		{
			"spawned": instance.name,
			"pooled": pool != null,
			"instance": instance,
		}
	)


func _create_spawn_instance(parent: Node, pool: PoolService) -> Node:
	if pool != null:
		return pool.acquire(scene_path, parent)
	var packed := load(scene_path) as PackedScene
	if packed == null:
		return null
	return packed.instantiate()
