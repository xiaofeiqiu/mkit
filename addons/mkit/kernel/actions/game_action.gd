class_name GameAction
extends RefCounted

## Purpose: Emits the `completed` signal to notify external listeners of a state change.
## Example: `self.completed.connect(_on_completed)`
## Scenario: Use this in event-driven flows where UI, audio, or systems react without direct coupling.
signal completed(action: GameAction)
## Purpose: Emits the `cancelled` signal to notify external listeners of a state change.
## Example: `self.cancelled.connect(_on_cancelled)`
## Scenario: Use this in event-driven flows where UI, audio, or systems react without direct coupling.
signal cancelled(action: GameAction, reason: String)

## Purpose: Public runtime field `action_id`.
## Example: `self.action_id = "value"`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var action_id: String = ""
## Purpose: Public runtime field `context`.
## Example: `self.context = null`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var context: ActionContext = null
## Purpose: Public runtime field `elapsed`.
## Example: `self.elapsed = 1.0`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var elapsed: float = 0.0
## Purpose: Public runtime field `finished`.
## Example: `self.finished = true`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var finished: bool = false
## Purpose: Public runtime field `cancelled_flag`.
## Example: `self.cancelled_flag = true`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var cancelled_flag: bool = false
## Purpose: Public runtime field `cancel_tags`.
## Example: `self.cancel_tags = []`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var cancel_tags: Array[String] = []


## Purpose: Public method `start` for external gameplay integration.
## Example: `self.start(<ctx>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func start(ctx: ActionContext) -> void:
	context = ctx
	elapsed = 0.0
	finished = false
	cancelled_flag = false
	_on_start()


## Purpose: Public method `update` for external gameplay integration.
## Example: `self.update(<delta>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func update(delta: float) -> void:
	if finished or cancelled_flag:
		return
	elapsed += delta
	_on_update(delta)


## Purpose: Public method `cancel` for external gameplay integration.
## Example: `self.cancel(<reason>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func cancel(reason: String = "") -> void:
	if finished or cancelled_flag:
		return
	cancelled_flag = true
	_on_cancel(reason)
	cancelled.emit(self, reason)


## Purpose: Public method `complete` for external gameplay integration.
## Example: `self.complete()`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func complete() -> void:
	if finished or cancelled_flag:
		return
	finished = true
	_on_complete()
	completed.emit(self)


## Purpose: Public method `is_finished` for external gameplay integration.
## Example: `self.is_finished()`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func is_finished() -> bool:
	return finished or cancelled_flag


## Purpose: Public method `can_cancel_with` for external gameplay integration.
## Example: `self.can_cancel_with(<tag>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
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
