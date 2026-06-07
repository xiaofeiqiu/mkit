class_name CommandService
extends Node
signal command_dispatched(command: GameCommand)
signal command_failed(command: GameCommand, reason: String)
var _receivers: Dictionary = {}


func register_receiver(receiver_id: String, receiver: CommandReceiver) -> void:
	if receiver_id.strip_edges() == "":
		push_warning("CommandService.register_receiver: receiver_id is empty")
		return
	if receiver == null:
		push_error("CommandService.register_receiver: receiver is null for id %s" % receiver_id)
		return
	_receivers[receiver_id] = receiver


func unregister_receiver(receiver_id: String) -> void:
	_receivers.erase(receiver_id)


func dispatch(command: GameCommand) -> bool:
	if command == null:
		push_warning("CommandService.dispatch: command is null")
		return false
	command_dispatched.emit(command)
	if command.target_id.strip_edges() == "":
		command_failed.emit(command, "Missing target_id")
		return false
	if not _receivers.has(command.target_id):
		command_failed.emit(command, "No receiver for target_id: %s" % command.target_id)
		return false
	var receiver := _receivers[command.target_id] as CommandReceiver
	if receiver == null or not is_instance_valid(receiver):
		command_failed.emit(command, "Receiver is invalid for target_id: %s" % command.target_id)
		return false
	var handled := receiver.receive_command(command)
	if not handled:
		command_failed.emit(command, "Receiver did not handle command: %s" % command.command_type)
	return handled


func broadcast(command: GameCommand, receiver_ids: Array[String]) -> int:
	if command == null:
		push_error("CommandService.broadcast: command is null")
		return 0
	if receiver_ids.is_empty():
		return 0
	var handled_count := 0
	for id in receiver_ids:
		if id.strip_edges() == "":
			continue
		var cloned := GameCommand.create(
			command.command_type, command.source_id, id, command.payload.duplicate(true)
		)
		if dispatch(cloned):
			handled_count += 1
	return handled_count
