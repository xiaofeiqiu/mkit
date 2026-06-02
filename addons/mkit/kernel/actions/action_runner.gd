class_name ActionRunner
extends Node
signal action_started(action: GameAction)
signal action_completed(action: GameAction)
signal action_cancelled(action: GameAction, reason: String)
var active_actions: Array[GameAction] = []


func start_action(action: GameAction, context: ActionContext) -> GameAction:
	if action == null:
		push_warning("ActionRunner.start_action: action is null")
		return null
	if context == null:
		push_warning("ActionRunner.start_action: context is null")
		return null
	active_actions.append(action)
	if not action.completed.is_connected(_on_action_completed):
		action.completed.connect(_on_action_completed)
	if not action.cancelled.is_connected(_on_action_cancelled):
		action.cancelled.connect(_on_action_cancelled)
	action.start(context)
	action_started.emit(action)
	return action


func _process(delta: float) -> void:
	var time: TimeService = null
	if ServiceRegistry.has_service("time"):
		time = ServiceRegistry.get_service("time") as TimeService
	var scaled_delta := time.get_scaled_delta(delta) if time != null else delta
	for action in active_actions.duplicate():
		if action == null:
			active_actions.erase(action)
			continue
		action.update(scaled_delta)
		if action.is_finished():
			active_actions.erase(action)
			if not action.cancelled_flag:
				action_completed.emit(action)


func cancel_actions_for_source(source: Node, reason: String = "") -> void:
	if source == null:
		push_warning("ActionRunner.cancel_actions_for_source: source is null")
		return
	for action in active_actions.duplicate():
		if action.context != null and action.context.source == source:
			action.cancel(reason)


func _on_action_completed(_action: GameAction) -> void:
	pass


func _on_action_cancelled(action: GameAction, reason: String) -> void:
	action_cancelled.emit(action, reason)
