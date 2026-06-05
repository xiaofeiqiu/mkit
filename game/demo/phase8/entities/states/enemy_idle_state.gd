extends State


func handle_command(command: GameCommand) -> bool:
	match command.command_type:
		BuiltinCommands.MOVE:
			var dir := command.get_vector2("direction")
			blackboard.set_value("move_direction", dir)
			if dir != Vector2.ZERO:
				blackboard.set_value("facing", dir)
			return request_transition("Enemy/Move", {"reason": "move_command", "command": command})
		BuiltinCommands.ATTACK:
			return request_transition("Enemy/Attack", {"reason": "attack_command", "command": command})
	return false
