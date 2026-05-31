class_name DummyAttackState
extends State

var current_action: GameAction = null


func enter(context: Dictionary = {}) -> void:
	print("[Dummy] Enter Attack")

	var action_context := ActionContext.new()
	action_context.source = owner_entity

	var action := DemoWaitAction.new()
	action.duration = 0.3
	action.completed.connect(_on_action_completed)
	current_action = action

	var runner := ServiceRegistry.get_service("actions") as ActionRunner
	runner.start_action(action, action_context)


func exit(context: Dictionary = {}) -> void:
	if current_action != null and not current_action.is_finished():
		current_action.cancel("state_exit")
	current_action = null


func _on_action_completed(_action: GameAction) -> void:
	# Action finished -> run a declarative effect, which logs a structured result
	# and emits a domain event picked up by the DebugOverlay.
	var effect := LogEffect.new()
	effect.effect_id = "effect.demo_attack"
	effect.message = "dummy attack landed"
	effect.event_type = "attack_resolved"

	var ctx := GameplayContext.new()
	ctx.source = owner_entity

	var executor := ServiceRegistry.get_service("effects") as EffectExecutor
	var result := executor.execute(effect, ctx)
	print("[Dummy] Effect result: success=%s payload=%s" % [result.success, str(result.payload)])

	request_transition("Dummy/Idle", {"reason": "attack_finished"})
