class_name DummyMoveState
extends State


func enter(context: Dictionary = {}) -> void:
	print(
		(
			"[Dummy] Enter Move (direction=%s)"
			% str(blackboard.get_value("move_direction", Vector2.ZERO))
		)
	)


func handle_command(command: GameCommand) -> bool:
	match command.command_type:
		BuiltinCommands.ATTACK:
			return request_transition(
				"Dummy/Attack", {"reason": "attack_command", "command": command}
			)
		BuiltinCommands.STOP_MOVE:
			return request_transition("Dummy/Idle", {"reason": "stop_command"})
		BuiltinCommands.MOVE:
			blackboard.set_value("move_direction", command.get_vector2("direction"))
			return true
	return false
