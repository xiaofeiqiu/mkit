class_name CommandReceiver
extends Node
@export var receiver_id: String = ""
@export var auto_register: bool = true
var owner_entity: Node = null
var state_machine: StateMachine = null
var command_history: Array[GameCommand] = []
var max_history: int = 20
var _registered_router: CommandService = null


func _ready() -> void:
	owner_entity = owner if owner != null else get_parent()
	_resolve_state_machine()
	if receiver_id == "":
		var identity = (
			owner_entity.get_node_or_null("EntityIdentity") if owner_entity != null else null
		)
		if identity != null and "entity_id" in identity:
			receiver_id = str(identity.entity_id)
	_register_with_router()


func _process(_delta: float) -> void:
	if state_machine == null:
		_resolve_state_machine()
	if auto_register and _registered_router == null:
		_register_with_router()
	if state_machine != null and (not auto_register or _registered_router != null):
		set_process(false)


func _exit_tree() -> void:
	if _registered_router != null and receiver_id != "":
		_registered_router.unregister_receiver(receiver_id)
	_registered_router = null


func configure_receiver_id(id: String) -> void:
	if id == "":
		return
	if _registered_router != null and receiver_id != id:
		_registered_router.unregister_receiver(receiver_id)
		_registered_router = null
	receiver_id = id
	_register_with_router()


func receive_command(command: GameCommand) -> bool:
	if command == null:
		push_warning("CommandReceiver.receive_command: command is null")
		return false
	if state_machine == null:
		_resolve_state_machine()
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


func _resolve_state_machine() -> void:
	state_machine = null
	if owner_entity != null:
		state_machine = owner_entity.get_node_or_null("StateMachine") as StateMachine


func _register_with_router() -> void:
	if not auto_register:
		set_process(state_machine == null)
		return
	if receiver_id == "":
		push_warning("CommandReceiver auto_register skipped: receiver_id is empty")
		set_process(true)
		return
	var router := ServiceRegistry.get_service_or_null(ServiceRegistry.SERVICE_COMMANDS) as CommandService
	if router == null:
		set_process(true)
		return
	router.register_receiver(receiver_id, self)
	_registered_router = router
	set_process(state_machine == null)
