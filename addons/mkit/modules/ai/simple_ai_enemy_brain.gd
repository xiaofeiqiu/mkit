class_name SimpleAIEnemyBrain
extends Brain
@export var detection_range: float = 240.0
@export var attack_range: float = 48.0
@export var target_group: String = "player"


func _ready() -> void:
	super._ready()
	target = get_tree().get_first_node_in_group(target_group)


func think() -> void:
	if target == null:
		return
	var owner_2d := owner as Node2D
	var target_2d := target as Node2D
	if owner_2d == null or target_2d == null:
		return
	var distance: float = owner_2d.global_position.distance_to(target_2d.global_position)
	if distance <= attack_range:
		issue_command(BuiltinCommands.ATTACK, {"target": target})
	elif distance <= detection_range:
		var direction: Vector2 = (target_2d.global_position - owner_2d.global_position).normalized()
		issue_command(BuiltinCommands.MOVE, {"direction": direction})
	else:
		issue_command(BuiltinCommands.STOP_MOVE, {})
