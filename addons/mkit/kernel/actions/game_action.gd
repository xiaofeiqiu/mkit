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


func start(ctx: ActionContext) -> void:
	context = ctx
	elapsed = 0.0
	finished = false
	cancelled_flag = false
	_on_start()


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
	cancelled.emit(self, reason)


func complete() -> void:
	if finished or cancelled_flag:
		return
	finished = true
	_on_complete()
	completed.emit(self)


func is_finished() -> bool:
	return finished or cancelled_flag


func can_cancel_with(tag: String) -> bool:
	return cancel_tags.has(tag)


func _on_start() -> void:
	pass


func _on_update(delta: float) -> void:
	pass


func _on_cancel(reason: String) -> void:
	pass


func _on_complete() -> void:
	pass
