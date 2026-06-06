class_name SimpleAIEnemyBrain
extends Brain
@export var detection_range: float = 240.0
@export var attack_range: float = 48.0
@export var target_group: String = "player"


func _ready() -> void:
	super._ready()
	target = get_tree().get_first_node_in_group(target_group)
	if target != null:
		blackboard.set_value("target", target)


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
