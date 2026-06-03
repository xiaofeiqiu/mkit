class_name CommandReceiver
extends Node
@export var receiver_id: String = ""
@export var auto_register: bool = true
var owner_entity: Node = null
var state_machine: StateMachine = null
var command_history: Array[GameCommand] = []
var max_history: int = 20


func _ready() -> void:
	owner_entity = owner if owner != null else get_parent()
	state_machine = null
	if owner_entity != null:
		state_machine = owner_entity.get_node_or_null("StateMachine") as StateMachine
	if receiver_id == "":
		var identity = (
			owner_entity.get_node_or_null("EntityIdentity") if owner_entity != null else null
		)
		if identity != null and "entity_id" in identity:
			receiver_id = str(identity.entity_id)
	if auto_register:
		if receiver_id == "":
			push_warning("CommandReceiver auto_register skipped: receiver_id is empty")
			return
		var router := ServiceRegistry.get_service("commands") as CommandRouter
		if router != null:
			router.register_receiver(receiver_id, self)


func receive_command(command: GameCommand) -> bool:
	if command == null:
		push_warning("CommandReceiver.receive_command: command is null")
		return false
	_record_command(command)
	if state_machine != null:
		var handled := state_machine.handle_command(command)
		if handled:
			command.mark_consumed()
			return true
	var fallback_handled := handle_unhandled_command(command)
	if fallback_handled:
		command.mark_consumed()
	return fallback_handled


func handle_unhandled_command(command: GameCommand) -> bool:
	return false


func _record_command(command: GameCommand) -> void:
	if command == null:
		return
	command_history.append(command)
	if command_history.size() > max_history:
		command_history.pop_front()
