class_name CommandRouter
extends Node

## Purpose: Emits the `command_dispatched` signal to notify external listeners of a state change.
## Example: `self.command_dispatched.connect(_on_command_dispatched)`
## Scenario: Use this in event-driven flows where UI, audio, or systems react without direct coupling.
signal command_dispatched(command: GameCommand)
## Purpose: Emits the `command_failed` signal to notify external listeners of a state change.
## Example: `self.command_failed.connect(_on_command_failed)`
## Scenario: Use this in event-driven flows where UI, audio, or systems react without direct coupling.
signal command_failed(command: GameCommand, reason: String)

var _receivers: Dictionary = {}


## Purpose: Public method `register_receiver` for external gameplay integration.
## Example: `self.register_receiver(<receiver_id>, <receiver>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func register_receiver(receiver_id: String, receiver: CommandReceiver) -> void:
	assert(receiver_id != "")
	assert(receiver != null)
	_receivers[receiver_id] = receiver


## Purpose: Public method `unregister_receiver` for external gameplay integration.
## Example: `self.unregister_receiver(<receiver_id>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func unregister_receiver(receiver_id: String) -> void:
	_receivers.erase(receiver_id)


## Purpose: Public method `dispatch` for external gameplay integration.
## Example: `self.dispatch(<command>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
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


## Purpose: Public method `broadcast` for external gameplay integration.
## Example: `self.broadcast(<command>, <receiver_ids>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func broadcast(command: GameCommand, receiver_ids: Array[String]) -> int:
	var handled_count := 0
	for id in receiver_ids:
		var cloned := GameCommand.create(command.command_type, command.source_id, id, command.payload)
		if dispatch(cloned):
			handled_count += 1
	return handled_count
