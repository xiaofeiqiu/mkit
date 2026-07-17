class_name PlayerIdleState
extends HfsmState


func enter(context: Dictionary = {}) -> void:
	var body := owner_entity as CharacterBody2D
	if body != null:
		body.velocity = Vector2.ZERO


func handle_command(command: GameCommand) -> bool:
	match command.command_type:
		BuiltinCommands.MOVE:
			var dir := command.get_vector2("direction")
			blackboard.set_value("move_direction", dir)
			if dir != Vector2.ZERO:
				blackboard.set_value("facing", dir)
			return request_transition("Player/Move", {"reason": "move_command"})
		BuiltinCommands.ATTACK:
			return request_transition(
				"Player/Attack", {"reason": "attack_command", "command": command}
			)
		BuiltinCommands.DASH:
			return request_transition("Player/Dash", {"reason": "dash_command", "command": command})
		BuiltinCommands.CAST_ABILITY:
			return request_transition(
				"Player/CastAbility", {"reason": "cast_command", "command": command}
			)
	return false
