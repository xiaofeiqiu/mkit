class_name CommandRouter
extends Node

signal command_dispatched(command: GameCommand)
signal command_failed(command: GameCommand, reason: String)

var _receivers: Dictionary = {}


func register_receiver(receiver_id: String, receiver: CommandReceiver) -> void:
	assert(receiver_id != "")
	assert(receiver != null)
	_receivers[receiver_id] = receiver


func unregister_receiver(receiver_id: String) -> void:
	_receivers.erase(receiver_id)


func dispatch(command: GameCommand) -> bool:
	command_dispatched.emit(command)

	if command.target_id == "":
		command_failed.emit(command, "Missing target_id")
		return false

	if not _receivers.has(command.target_id):
		command_failed.emit(command, "No receiver for target_id: %s" % command.target_id)
		return false

	var receiver := _receivers[command.target_id] as CommandReceiver
	var handled := receiver.receive_command(command)
	if not handled:
		command_failed.emit(command, "Receiver did not handle command: %s" % command.command_type)
	return handled


func broadcast(command: GameCommand, receiver_ids: Array[String]) -> int:
	var handled_count := 0
	for id in receiver_ids:
		var cloned := GameCommand.create(command.command_type, command.source_id, id, command.payload)
		if dispatch(cloned):
			handled_count += 1
	return handled_count
