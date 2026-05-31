class_name DummyIdleState
extends State


func enter(context: Dictionary = {}) -> void:
	print("[Dummy] Enter Idle")


func handle_command(command: GameCommand) -> bool:
	match command.command_type:
		BuiltinCommands.MOVE:
			blackboard.set_value("move_direction", command.get_vector2("direction"))
			return request_transition("Dummy/Move", {"reason": "move_command"})
		BuiltinCommands.ATTACK:
			return request_transition("Dummy/Attack", {"reason": "attack_command", "command": command})
	return false
