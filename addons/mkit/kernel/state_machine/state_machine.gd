class_name StateMachine
extends Node

## Purpose: Emits the `state_changed` signal to notify external listeners of a state change.
## Example: `self.state_changed.connect(_on_state_changed)`
## Scenario: Use this in event-driven flows where UI, audio, or systems react without direct coupling.
signal state_changed(previous_path: String, current_path: String)
## Purpose: Emits the `transition_failed` signal to notify external listeners of a state change.
## Example: `self.transition_failed.connect(_on_transition_failed)`
## Scenario: Use this in event-driven flows where UI, audio, or systems react without direct coupling.
signal transition_failed(from_path: String, to_path: String, reason: String)

## Purpose: Inspector-exposed configuration `initial_state_path`.
## Example: `self.initial_state_path = "value"`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var initial_state_path: String = ""
## Purpose: Inspector-exposed configuration `auto_start`.
## Example: `self.auto_start = true`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var auto_start: bool = true

## Purpose: Public runtime field `owner_entity`.
## Example: `self.owner_entity = null`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var owner_entity: Node = null
## Purpose: Public runtime field `root_state`.
## Example: `self.root_state = null`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var root_state: State = null
## Purpose: Public runtime field `current_leaf_state`.
## Example: `self.current_leaf_state = null`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var current_leaf_state: State = null
## Purpose: Public runtime field `blackboard`.
## Example: `self.blackboard = null`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var blackboard: Blackboard = Blackboard.new()
## Purpose: Public runtime field `previous_path`.
## Example: `self.previous_path = "value"`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var previous_path: String = ""
## Purpose: Public runtime field `last_transition_reason`.
## Example: `self.last_transition_reason = "value"`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var last_transition_reason: String = ""
## Purpose: Public runtime field `last_failed_transition_reason`.
## Example: `self.last_failed_transition_reason = "value"`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var last_failed_transition_reason: String = ""


func _ready() -> void:
	owner_entity = owner
	root_state = _find_root_state()
	if root_state != null:
		root_state.setup(self, owner_entity, null)
	if auto_start and initial_state_path != "":
		transition_to(initial_state_path, {"reason": "initial"})


func _process(delta: float) -> void:
	if current_leaf_state != null:
		_update_state_chain(current_leaf_state, delta, false)


func _physics_process(delta: float) -> void:
	if current_leaf_state != null:
		_update_state_chain(current_leaf_state, delta, true)


## Purpose: Public method `handle_command` for external gameplay integration.
## Example: `self.handle_command(<command>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func handle_command(command: GameCommand) -> bool:
	if current_leaf_state == null:
		return false

	var current: State = current_leaf_state
	while current != null:
		if current.handle_command(command):
			return true
		current = current.parent_state

	return false


## Purpose: Public method `transition_to` for external gameplay integration.
## Example: `self.transition_to(<target_path>, <context>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func transition_to(target_path: String, context: Dictionary = {}) -> bool:
	var target := find_state_by_path(target_path)
	if target == null:
		_fail_transition(target_path, "Target state not found")
		return false

	if current_leaf_state == target:
		return true

	var from_path := get_current_path()

	if current_leaf_state != null and not _can_exit_chain(current_leaf_state, target, context):
		_fail_transition(target_path, "Current state chain cannot exit")
		return false

	if not _can_enter_chain(current_leaf_state, target, context):
		_fail_transition(target_path, "Target state chain cannot enter")
		return false

	_perform_lca_transition(current_leaf_state, target, context)

	previous_path = from_path
	current_leaf_state = _enter_initial_children(target, context)
	last_transition_reason = str(context.get("reason", ""))
	state_changed.emit(from_path, get_current_path())
	return true


## Purpose: Public method `get_current_path` for external gameplay integration.
## Example: `self.get_current_path()`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func get_current_path() -> String:
	if current_leaf_state == null:
		return ""
	return current_leaf_state.get_full_path()


## Purpose: Public method `find_state_by_path` for external gameplay integration.
## Example: `self.find_state_by_path(<path>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func find_state_by_path(path: String) -> State:
	if root_state == null:
		return null
	var parts := path.split("/", false)
	if parts.size() == 0:
		return null
	if parts[0] != root_state.state_id:
		return null

	var current := root_state
	for i in range(1, parts.size()):
		current = _find_child_state(current, parts[i])
		if current == null:
			return null
	return current


func _perform_lca_transition(from_state: State, to_state: State, context: Dictionary) -> void:
	if from_state == null:
		_enter_chain(null, to_state, context)
		return

	var lca := _find_lowest_common_ancestor(from_state, to_state)
	_exit_until(from_state, lca, context)
	_enter_chain(lca, to_state, context)


func _find_lowest_common_ancestor(a: State, b: State) -> State:
	var ancestors_a: Array[State] = []
	var current: State = a
	while current != null:
		ancestors_a.append(current)
		current = current.parent_state

	current = b
	while current != null:
		if ancestors_a.has(current):
			return current
		current = current.parent_state
	return null


func _exit_until(from_state: State, stop_state: State, context: Dictionary) -> void:
	var current := from_state
	while current != null and current != stop_state:
		current.exit(context)
		if current.parent_state != null and current.parent_state.active_child == current:
			current.parent_state.active_child = null
		current = current.parent_state


func _enter_chain(ancestor: State, target: State, context: Dictionary) -> void:
	var chain: Array[State] = []
	var current := target
	while current != null and current != ancestor:
		chain.push_front(current)
		current = current.parent_state

	for state in chain:
		if state.parent_state != null:
			state.parent_state.active_child = state
		state.enter(context)


func _enter_initial_children(state: State, context: Dictionary) -> State:
	var current := state
	while current.initial_child_state_id != "":
		var child := _find_child_state(current, current.initial_child_state_id)
		if child == null:
			break
		current.active_child = child
		child.enter(context)
		current = child
	return current


func _can_exit_chain(from_state: State, target_state: State, context: Dictionary) -> bool:
	var lca := _find_lowest_common_ancestor(from_state, target_state)
	var current := from_state
	while current != null and current != lca:
		if not current.can_exit(context):
			return false
		current = current.parent_state
	return true


func _can_enter_chain(from_state: State, target_state: State, context: Dictionary) -> bool:
	var lca: State = null
	if from_state != null:
		lca = _find_lowest_common_ancestor(from_state, target_state)
	var chain: Array[State] = []
	var current := target_state
	while current != null and current != lca:
		chain.push_front(current)
		current = current.parent_state
	for state in chain:
		if not state.can_enter(context):
			return false
	return true


func _update_state_chain(leaf: State, delta: float, physics: bool) -> void:
	var chain: Array[State] = []
	var current := leaf
	while current != null:
		chain.push_front(current)
		current = current.parent_state
	for state in chain:
		if physics:
			state.physics_update(delta)
		else:
			state.update(delta)


func _find_root_state() -> State:
	for child in get_children():
		if child is State:
			return child
	return null


func _find_child_state(parent: State, id: String) -> State:
	for child in parent.get_children():
		if child is State and child.state_id == id:
			return child
	return null


func _fail_transition(target_path: String, reason: String) -> void:
	last_failed_transition_reason = reason
	transition_failed.emit(get_current_path(), target_path, reason)
