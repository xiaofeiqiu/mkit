## What: CommandReceiver is a node component that accepts GameCommand objects for one entity or system.
## Responsibilities: register with CommandRouter, keep command history, forward commands to StateMachine, and allow overrides.
## Upstream: CommandRouter dispatches commands from input, AI, cutscenes, or tests.
## Downstream: StateMachine or subclass-specific handlers consume commands and decide whether they were handled.
## When to use: Attach it to controllable entities or managers that need addressable command handling.
## Example: set `receiver_id = "player_001"`; then dispatch `GameCommand.create(BuiltinCommands.DASH, "input", "player_001")`.
class_name CommandReceiver
extends Node

## Purpose: Inspector-exposed configuration `receiver_id`.
## Example: `self.receiver_id = "value"`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var receiver_id: String = ""
## Purpose: Inspector-exposed configuration `auto_register`.
## Example: `self.auto_register = true`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var auto_register: bool = true

## Purpose: Public runtime field `owner_entity`.
## Example: `self.owner_entity = null`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var owner_entity: Node = null
## Purpose: Public runtime field `state_machine`.
## Example: `self.state_machine = null`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var state_machine: StateMachine = null
## Purpose: Public runtime field `command_history`.
## Example: `self.command_history = []`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var command_history: Array[GameCommand] = []
## Purpose: Public runtime field `max_history`.
## Example: `self.max_history = 1`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
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


## Purpose: Public method `receive_command` for external gameplay integration.
## Example: `self.receive_command(<command>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func receive_command(command: GameCommand) -> bool:
	_record_command(command)

	if state_machine != null:
		var handled := state_machine.handle_command(command)
		if handled:
			command.mark_consumed()
			return true

	return handle_unhandled_command(command)


## Purpose: Public method `handle_unhandled_command` for external gameplay integration.
## Example: `self.handle_unhandled_command(<command>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func handle_unhandled_command(command: GameCommand) -> bool:
	return false


func _record_command(command: GameCommand) -> void:
	command_history.append(command)
	if command_history.size() > max_history:
		command_history.pop_front()
