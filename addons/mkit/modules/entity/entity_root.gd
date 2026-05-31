## What: EntityRoot is the root CharacterBody2D for an MKit entity scene.
## Responsibilities: expose entity id lookup and standardized access to Components and Controllers child nodes.
## Upstream: EntitySpawner or hand-authored scenes instantiate it as player/enemy/entity roots.
## Downstream: states, abilities, combat, UI, and tests fetch child components through helper methods.
## When to use: Use it as the scene root for entities that share MKit components and controllers.
## Example: `var health := enemy_root.get_component("HealthComponent") as HealthComponent`.
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
