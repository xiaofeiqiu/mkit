class_name GameAction
extends RefCounted
signal completed(action: GameAction)
signal cancelled(action: GameAction, reason: String)
var action_id: String = ""
var context: ActionContext = null
var elapsed: float = 0.0
var finished: bool = false
var cancelled_flag: bool = false
var cancel_tags: Array[String] = []
var on_start_effects: Array[GameEffect] = []
var on_complete_effects: Array[GameEffect] = []
var on_cancel_effects: Array[GameEffect] = []


func start(ctx: ActionContext) -> void:
	context = ctx
	elapsed = 0.0
	finished = false
	cancelled_flag = false
	_on_start()
	_fire_effects(on_start_effects + _resolve_effects(context))


func update(delta: float) -> void:
	if finished or cancelled_flag:
		return
	elapsed += delta
	_on_update(delta)


func cancel(reason: String = "") -> void:
	if finished or cancelled_flag:
		return
	cancelled_flag = true
	_on_cancel(reason)
	_fire_effects(on_cancel_effects)
	cancelled.emit(self, reason)


func complete() -> void:
	if finished or cancelled_flag:
		return
	finished = true
	_on_complete()
	_fire_effects(on_complete_effects + _resolve_effects(context))
	completed.emit(self)


func is_finished() -> bool:
	return finished or cancelled_flag


func can_cancel_with(tag: String) -> bool:
	return cancel_tags.has(tag)


func _fire_effects(effects: Array[GameEffect]) -> void:
	if effects.is_empty():
		return
	var svc := ServiceRegistry.get_service_or_null(ServiceRegistry.SERVICE_EFFECTS) as EffectService
	if svc == null:
		return
	svc.execute_many(effects, context)


func _resolve_effects(_ctx: ActionContext) -> Array[GameEffect]:
	return []


func _on_start() -> void:
	pass


func _on_update(delta: float) -> void:
	pass


func _on_cancel(reason: String) -> void:
	pass


func _on_complete() -> void:
	pass
