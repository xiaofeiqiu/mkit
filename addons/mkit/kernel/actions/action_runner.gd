class_name ActionRunner
extends Node

signal action_started(action: GameAction)
signal action_completed(action: GameAction)
signal action_cancelled(action: GameAction, reason: String)

var active_actions: Array[GameAction] = []


func start_action(action: GameAction, context: ActionContext) -> GameAction:
	active_actions.append(action)
	action.completed.connect(_on_action_completed)
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
		action.update(scaled_delta)
		if action.is_finished():
			active_actions.erase(action)


func cancel_actions_for_source(source: Node, reason: String = "") -> void:
	for action in active_actions.duplicate():
		if action.context != null and action.context.source == source:
			action.cancel(reason)


func _on_action_completed(action: GameAction) -> void:
	action_completed.emit(action)


func _on_action_cancelled(action: GameAction, reason: String) -> void:
	action_cancelled.emit(action, reason)
