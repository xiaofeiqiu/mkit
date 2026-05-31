class_name EntityRoot
extends CharacterBody2D

@onready var identity: EntityIdentity = $EntityIdentity
@onready var state_machine: StateMachine = $StateMachine
@onready var command_receiver: CommandReceiver = $CommandReceiver


## Purpose: Public method `get_entity_id` for external gameplay integration.
## Example: `self.get_entity_id()`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func get_entity_id() -> String:
	if identity == null:
		return name
	return identity.entity_id


## Purpose: Public method `get_component` for external gameplay integration.
## Example: `self.get_component(<component_name>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func get_component(component_name: String) -> Node:
	return get_node_or_null("Components/%s" % component_name)


## Purpose: Public method `get_controller` for external gameplay integration.
## Example: `self.get_controller(<controller_name>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func get_controller(controller_name: String) -> Node:
	return get_node_or_null("Controllers/%s" % controller_name)
