class_name PlayerDashState
extends HfsmState

var current_action: GameAction = null


func enter(context: Dictionary = {}) -> void:
	var command := context.get("command") as GameCommand
	var direction := Vector2.ZERO
	if command != null:
		direction = command.get_vector2("direction")
	if direction == Vector2.ZERO:
		direction = blackboard.get_value("facing", Vector2.RIGHT)
	if direction != Vector2.ZERO:
		blackboard.set_value("facing", direction)

	var action := DashAction.new()
	action.duration = 0.18
	action.speed = 520.0
	action.completed.connect(_on_action_completed)
	current_action = action

	var ctx := ActionContext.new()
	ctx.source = owner_entity
	ctx.direction = direction

	var runner := Mkit.actions()
	if runner == null:
		request_transition.call_deferred("Player/Idle", {"reason": "missing_action_runner"})
		return
	runner.start_action(action, ctx)


func exit(context: Dictionary = {}) -> void:
	if current_action != null and not current_action.is_finished():
		current_action.cancel("state_exit")
	current_action = null


func _on_action_completed(_action: GameAction) -> void:
	request_transition("Player/Idle", {"reason": "dash_finished"})
