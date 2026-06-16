extends HfsmState

var _stats: StatsComponent = null


func enter(context: Dictionary = {}) -> void:
	if _stats == null and owner_entity != null:
		_stats = owner_entity.get_node_or_null("Components/StatsComponent") as StatsComponent


func physics_update(delta: float) -> void:
	var body := owner_entity as CharacterBody2D
	if body == null:
		return
	var dir: Vector2 = blackboard.get_value("move_direction", Vector2.ZERO)
	if dir == Vector2.ZERO:
		request_transition("Enemy/Idle", {"reason": "no_input"})
		return
	body.velocity = dir * _move_speed()
	body.move_and_slide()


func handle_command(command: GameCommand) -> bool:
	match command.command_type:
		BuiltinCommands.MOVE:
			var dir := command.get_vector2("direction")
			blackboard.set_value("move_direction", dir)
			if dir != Vector2.ZERO:
				blackboard.set_value("facing", dir)
			return true
		BuiltinCommands.STOP_MOVE:
			blackboard.set_value("move_direction", Vector2.ZERO)
			return request_transition("Enemy/Idle", {"reason": "stop_command"})
		BuiltinCommands.ATTACK:
			return request_transition("Enemy/Attack", {"reason": "attack_command", "command": command})
	return false


func _move_speed() -> float:
	if _stats != null:
		return _stats.get_stat_value("move_speed", 120.0)
	return 120.0
