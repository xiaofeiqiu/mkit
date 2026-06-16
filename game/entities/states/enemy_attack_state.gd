extends HfsmState

var current_action: GameAction = null


func enter(context: Dictionary = {}) -> void:
	var body := owner_entity as CharacterBody2D
	if body != null:
		body.velocity = Vector2.ZERO
	var facing := _facing_from_context(context)
	blackboard.set_value("facing", facing)
	var hitbox := owner_entity.get_node_or_null("Components/HitboxComponent") as HitboxComponent
	if hitbox != null:
		hitbox.position = facing.normalized() * 28.0
	var ctx := ActionContext.new()
	ctx.source = owner_entity
	ctx.direction = facing
	var action := TimedAttackAction.new()
	action.startup_duration = 0.05
	action.active_duration = 0.12
	action.recovery_duration = 0.10
	action.hitbox_path = NodePath("Components/HitboxComponent")
	action.completed.connect(_on_action_completed)
	var runner := Mkit.actions()
	if runner == null:
		request_transition("Enemy/Idle", {"reason": "no_action_runner"})
		return
	current_action = action
	runner.start_action(action, ctx)


func exit(context: Dictionary = {}) -> void:
	if current_action != null and not current_action.is_finished():
		current_action.cancel("state_exit")
	current_action = null


func handle_command(command: GameCommand) -> bool:
	match command.command_type:
		BuiltinCommands.MOVE, BuiltinCommands.STOP_MOVE, BuiltinCommands.ATTACK:
			return true
	return false


func _facing_from_context(context: Dictionary) -> Vector2:
	var command := context.get("command", null) as GameCommand
	if command != null:
		var target := command.payload.get("target", null) as Node2D
		var owner_2d := owner_entity as Node2D
		if target != null and owner_2d != null:
			var dir := target.global_position - owner_2d.global_position
			if dir != Vector2.ZERO:
				return dir.normalized()
	var facing: Vector2 = blackboard.get_value("facing", Vector2.LEFT)
	return facing.normalized() if facing != Vector2.ZERO else Vector2.LEFT


func _on_action_completed(_action: GameAction) -> void:
	request_transition("Enemy/Idle", {"reason": "attack_finished"})
