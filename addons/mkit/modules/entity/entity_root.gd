class_name EntityRoot
extends CharacterBody2D
@onready var identity: EntityIdentity = $EntityIdentity
@onready var state_machine: StateMachine = $StateMachine
@onready var command_receiver: CommandReceiver = $CommandReceiver


func get_entity_identity() -> EntityIdentity:
	return identity


func get_state_machine_node() -> StateMachine:
	return state_machine


func get_command_receiver_node() -> CommandReceiver:
	return command_receiver


func get_entity_id() -> String:
	if identity == null:
		return name
	return identity.entity_id


func get_component(component_name: Variant) -> Node:
	if component_name is String or component_name is StringName:
		return get_node_or_null("Components/%s" % str(component_name))
	if component_name is Script:
		var components := get_node_or_null("Components") as Node
		if components == null:
			return null
		for child in components.get_children():
			if child != null and child.get_script() == component_name:
				return child
	return null


func get_controller(controller_name: Variant) -> Node:
	if controller_name is String or controller_name is StringName:
		return get_node_or_null("Controllers/%s" % str(controller_name))
	if controller_name is Script:
		var controllers := get_node_or_null("Controllers") as Node
		if controllers == null:
			return null
		for child in controllers.get_children():
			if child != null and child.get_script() == controller_name:
				return child
	return null


func has_contract_node(container: String, member: Variant) -> bool:
	if container == "Components":
		return get_component(member) != null
	if container == "Controllers":
		return get_controller(member) != null
	return false
