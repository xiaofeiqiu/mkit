class_name EntityRoot
extends CharacterBody2D
@onready var identity: EntityIdentity = $EntityIdentity
@onready var state_machine: StateMachine = $StateMachine
@onready var command_receiver: CommandReceiver = $CommandReceiver


func get_entity_id() -> String:
	if identity == null:
		return name
	return identity.entity_id


func get_component(component_name: String) -> Node:
	return get_node_or_null("Components/%s" % component_name)


func get_controller(controller_name: String) -> Node:
	return get_node_or_null("Controllers/%s" % controller_name)
