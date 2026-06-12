class_name SimpleAIEnemyBrain
extends Brain
## 说明：`SimpleAIEnemyBrain` 是 AI 系统 的公开 API 类型，负责承载该领域的可复用运行时数据或行为。
## 上游：通常由同领域服务、controller、组件或内容资源创建或调用。
## 下游：会连接 mkit 的服务、组件、资源或事件管线，不直接依赖具体游戏内容。
## 使用：当项目需要在AI 系统中复用这段契约或状态时使用它。
## 示例：`var instance := SimpleAIEnemyBrain.new()`

## AI 搜索目标的距离，单位为像素；超出范围的目标会被忽略。
@export var detection_range: float = 240.0
## AI 触发攻击的距离，单位为像素；目标更远时通常改为追击。
@export var attack_range: float = 48.0
## AI 搜索目标时使用的 Godot 分组名称。
@export var target_group: String = "player"


func _ready() -> void:
	super._ready()
	target = get_tree().get_first_node_in_group(target_group)
	if target != null:
		blackboard.set_value("target", target)


## 执行 `think` 对应的公开操作，并保持 `SimpleAIEnemyBrain` 的领域契约一致。
func think() -> void:
	target = _get_target()
	if target == null:
		blackboard.set_value("intent", "idle")
		return
	var owner_2d := owner as Node2D
	var target_2d := target as Node2D
	if owner_2d == null or target_2d == null:
		blackboard.set_value("intent", "idle")
		return
	var distance: float = owner_2d.global_position.distance_to(target_2d.global_position)
	blackboard.set_value("distance", distance)
	if distance <= attack_range:
		blackboard.set_value("intent", "attack")
		issue_command(BuiltinCommands.ATTACK, {"target": target})
	elif distance <= detection_range:
		var direction: Vector2 = (target_2d.global_position - owner_2d.global_position).normalized()
		blackboard.set_value("intent", "approach")
		issue_command(BuiltinCommands.MOVE, {"direction": direction})
	else:
		blackboard.set_value("intent", "idle")
		issue_command(BuiltinCommands.STOP_MOVE, {})


func _get_target() -> Node:
	var stored := blackboard.get_value("target", null) as Node
	if is_instance_valid(stored):
		return stored
	stored = get_tree().get_first_node_in_group(target_group)
	if stored != null:
		blackboard.set_value("target", stored)
	else:
		blackboard.erase_value("target")
	return stored
