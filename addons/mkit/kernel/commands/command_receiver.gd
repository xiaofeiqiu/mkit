class_name CommandReceiver
extends Node

@export var receiver_id: String = ""
@export var auto_register: bool = true

var owner_entity: Node = null
var state_machine: StateMachine = null
var command_history: Array[GameCommand] = []
var max_history: int = 20


func _ready() -> void:
	owner_entity = owner
	state_machine = owner.get_node_or_null("StateMachine") as StateMachine
	# Derive a stable receiver_id from EntityIdentity when it was not set in the
	# Inspector. Spawned enemies get their entity_id at runtime, so without this
	# they would register under "" and AI commands (dispatched to the entity_id)
	# would never route. Place EntityIdentity before CommandReceiver in the scene
	# so its _ready (and id assignment) runs first.
	#
	# EntityIdentity is a gameplay-module type introduced in a later phase, so we
	# resolve it by duck typing to keep the kernel free of forward dependencies.
	if receiver_id == "":
		var identity = owner.get_node_or_null("EntityIdentity")
		if identity != null and "entity_id" in identity:
			receiver_id = str(identity.entity_id)
	if auto_register:
		var router := ServiceRegistry.get_service("commands") as CommandRouter
		if router != null and receiver_id != "":
			router.register_receiver(receiver_id, self)


func receive_command(command: GameCommand) -> bool:
	_record_command(command)

	if state_machine != null:
		var handled := state_machine.handle_command(command)
		if handled:
			command.mark_consumed()
			return true

	return handle_unhandled_command(command)


func handle_unhandled_command(command: GameCommand) -> bool:
	return false


func _record_command(command: GameCommand) -> void:
	command_history.append(command)
	if command_history.size() > max_history:
		command_history.pop_front()
