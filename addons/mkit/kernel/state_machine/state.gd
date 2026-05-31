class_name State
extends Node

@export var state_id: String = ""
@export var initial_child_state_id: String = ""

var parent_state: State = null
var state_machine: StateMachine = null
var owner_entity: Node = null
var active_child: State = null
var blackboard: Blackboard = null


func setup(machine: StateMachine, entity: Node, parent: State = null) -> void:
	state_machine = machine
	owner_entity = entity
	parent_state = parent
	blackboard = machine.blackboard

	for child in get_children():
		if child is State:
			child.setup(machine, entity, self)


func enter(context: Dictionary = {}) -> void:
	pass


func exit(context: Dictionary = {}) -> void:
	pass


func update(delta: float) -> void:
	pass


func physics_update(delta: float) -> void:
	pass


func handle_command(command: GameCommand) -> bool:
	if active_child != null:
		if active_child.handle_command(command):
			return true
	return false


func can_enter(context: Dictionary = {}) -> bool:
	return true


func can_exit(context: Dictionary = {}) -> bool:
	return true


func request_transition(target_path: String, context: Dictionary = {}) -> bool:
	if state_machine == null:
		return false
	return state_machine.transition_to(target_path, context)


func get_path_ids() -> Array[String]:
	var result: Array[String] = []
	var current: State = self
	while current != null:
		result.push_front(current.state_id)
		current = current.parent_state
	return result


func get_full_path() -> String:
	return "/".join(get_path_ids())
