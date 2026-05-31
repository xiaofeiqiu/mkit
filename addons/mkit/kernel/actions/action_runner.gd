## What: ActionRunner owns active GameAction instances and ticks them each frame.
## Responsibilities: start actions, connect completion/cancel signals, update active actions, and cancel actions by source.
## Upstream: abilities, states, command receivers, or scripted encounters submit GameAction instances.
## Downstream: GameAction subclasses execute movement, attacks, casts, or other timed behaviors.
## When to use: Use it as the shared service for cancellable time-based gameplay actions.
## Example: `actions.start_action(TimedAttackAction.new(), ActionContext.from_command(attack_cmd, player, enemy))`.
class_name ActionRunner
extends Node

## Purpose: Emits the `action_started` signal to notify external listeners of a state change.
## Example: `self.action_started.connect(_on_action_started)`
## Scenario: Use this in event-driven flows where UI, audio, or systems react without direct coupling.
signal action_started(action: GameAction)
## Purpose: Emits the `action_completed` signal to notify external listeners of a state change.
## Example: `self.action_completed.connect(_on_action_completed)`
## Scenario: Use this in event-driven flows where UI, audio, or systems react without direct coupling.
signal action_completed(action: GameAction)
## Purpose: Emits the `action_cancelled` signal to notify external listeners of a state change.
## Example: `self.action_cancelled.connect(_on_action_cancelled)`
## Scenario: Use this in event-driven flows where UI, audio, or systems react without direct coupling.
signal action_cancelled(action: GameAction, reason: String)

## Purpose: Public runtime field `active_actions`.
## Example: `self.active_actions = []`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var active_actions: Array[GameAction] = []


## Purpose: Public method `start_action` for external gameplay integration.
## Example: `self.start_action(<action>, <context>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
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


## Purpose: Public method `cancel_actions_for_source` for external gameplay integration.
## Example: `self.cancel_actions_for_source(<source>, <reason>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func cancel_actions_for_source(source: Node, reason: String = "") -> void:
	for action in active_actions.duplicate():
		if action.context != null and action.context.source == source:
			action.cancel(reason)


func _on_action_completed(action: GameAction) -> void:
	action_completed.emit(action)


func _on_action_cancelled(action: GameAction, reason: String) -> void:
	action_cancelled.emit(action, reason)
