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
	var distance := owner.global_position.distance_to(target.global_position)
	if distance <= attack_range:
		issue_command(BuiltinCommands.ATTACK, {"target": target})
	elif distance <= detection_range:
		var direction := (target.global_position - owner.global_position).normalized()
		issue_command(BuiltinCommands.MOVE, {"direction": direction})
	else:
		issue_command(BuiltinCommands.STOP_MOVE, {})
