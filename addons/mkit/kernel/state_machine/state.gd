class_name State
extends Node

## Purpose: Inspector-exposed configuration `state_id`.
## Example: `self.state_id = "value"`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var state_id: String = ""
## Purpose: Inspector-exposed configuration `initial_child_state_id`.
## Example: `self.initial_child_state_id = "value"`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var initial_child_state_id: String = ""

## Purpose: Public runtime field `parent_state`.
## Example: `self.parent_state = null`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var parent_state: State = null
## Purpose: Public runtime field `state_machine`.
## Example: `self.state_machine = null`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var state_machine: StateMachine = null
## Purpose: Public runtime field `owner_entity`.
## Example: `self.owner_entity = null`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var owner_entity: Node = null
## Purpose: Public runtime field `active_child`.
## Example: `self.active_child = null`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var active_child: State = null
## Purpose: Public runtime field `blackboard`.
## Example: `self.blackboard = null`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var blackboard: Blackboard = null


## Purpose: Public method `setup` for external gameplay integration.
## Example: `self.setup(<machine>, <entity>, <parent>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func setup(machine: StateMachine, entity: Node, parent: State = null) -> void:
	state_machine = machine
	owner_entity = entity
	parent_state = parent
	blackboard = machine.blackboard

	for child in get_children():
		if child is State:
			child.setup(machine, entity, self)


## Purpose: Public method `enter` for external gameplay integration.
## Example: `self.enter(<context>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func enter(context: Dictionary = {}) -> void:
	pass


## Purpose: Public method `exit` for external gameplay integration.
## Example: `self.exit(<context>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func exit(context: Dictionary = {}) -> void:
	pass


## Purpose: Public method `update` for external gameplay integration.
## Example: `self.update(<delta>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func update(delta: float) -> void:
	pass


## Purpose: Public method `physics_update` for external gameplay integration.
## Example: `self.physics_update(<delta>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func physics_update(delta: float) -> void:
	pass


## Purpose: Public method `handle_command` for external gameplay integration.
## Example: `self.handle_command(<command>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func handle_command(command: GameCommand) -> bool:
	if active_child != null:
		if active_child.handle_command(command):
			return true
	return false


## Purpose: Public method `can_enter` for external gameplay integration.
## Example: `self.can_enter(<context>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func can_enter(context: Dictionary = {}) -> bool:
	return true


## Purpose: Public method `can_exit` for external gameplay integration.
## Example: `self.can_exit(<context>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func can_exit(context: Dictionary = {}) -> bool:
	return true


## Purpose: Public method `request_transition` for external gameplay integration.
## Example: `self.request_transition(<target_path>, <context>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func request_transition(target_path: String, context: Dictionary = {}) -> bool:
	if state_machine == null:
		return false
	return state_machine.transition_to(target_path, context)


## Purpose: Public method `get_path_ids` for external gameplay integration.
## Example: `self.get_path_ids()`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func get_path_ids() -> Array[String]:
	var result: Array[String] = []
	var current: State = self
	while current != null:
		result.push_front(current.state_id)
		current = current.parent_state
	return result


## Purpose: Public method `get_full_path` for external gameplay integration.
## Example: `self.get_full_path()`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func get_full_path() -> String:
	return "/".join(get_path_ids())
