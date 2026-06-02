class_name PlayerMoveState
extends State


func physics_update(delta: float) -> void:
	var body := owner_entity as CharacterBody2D
	if body == null:
		return
	var dir: Vector2 = blackboard.get_value("move_direction", Vector2.ZERO)
	if dir == Vector2.ZERO:
		request_transition("Player/Idle", {"reason": "no_input"})
		return
	body.velocity = dir.normalized() * _move_speed()
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
			return request_transition("Player/Idle", {"reason": "stop_command"})
		BuiltinCommands.ATTACK:
			return request_transition(
				"Player/Attack", {"reason": "attack_command", "command": command}
			)
		BuiltinCommands.CAST_ABILITY:
			return request_transition(
				"Player/CastAbility", {"reason": "cast_command", "command": command}
			)
	return false


func _move_speed() -> float:
	var stats := owner_entity.get_node_or_null("Components/StatsComponent") as StatsComponent
	if stats != null:
		return stats.get_stat_value("move_speed", 160.0)
	return 160.0
