class_name EntityContract
extends RefCounted

static func resolve_entity_root(node: Node) -> EntityRoot:
	if node == null:
		return null
	var current := node
	while current != null:
		if current is EntityRoot:
			return current as EntityRoot
		current = current.get_parent()
	return null

static func get_component(node: Node, id_or_type: Variant) -> Node:
	var owner := resolve_entity_root(node)
	if owner == null:
		_warn_missing(node, "component", id_or_type)
		return null
	var component := owner.get_component(id_or_type)
	if component == null:
		_warn_missing(node, "component", id_or_type)
	return component


static func get_controller(node: Node, id_or_type: Variant) -> Node:
	var owner := resolve_entity_root(node)
	if owner == null:
		_warn_missing(node, "controller", id_or_type)
		return null
	var controller := owner.get_controller(id_or_type)
	if controller == null:
		_warn_missing(node, "controller", id_or_type)
	return controller


static func get_contract_node(node: Node, container: String, id_or_type: Variant) -> Node:
	if node == null or container.strip_edges() == "":
		return null
	var owner := resolve_entity_root(node)
	if owner == null:
		_warn_missing(node, "contract:%s" % container, id_or_type)
		return null
	if id_or_type is String or id_or_type is StringName:
		return owner.get_node_or_null("%s/%s" % [container, str(id_or_type)])
	if id_or_type is Script:
		var container_node := owner.get_node_or_null(container) as Node
		if container_node == null:
			_warn_missing(node, "contract:%s" % container, id_or_type)
			return null
		for child in container_node.get_children():
			if child != null and child.get_script() == id_or_type:
				return child
	_warn_missing(node, "contract:%s" % container, id_or_type)
	return null


static func get_identity(node: Node) -> EntityIdentity:
	var owner := resolve_entity_root(node)
	if owner != null:
		var identity := owner.get_entity_identity()
		if identity == null:
			_warn_missing(node, "identity", "EntityIdentity")
		return identity
	_warn_missing(node, "identity", "EntityIdentity")
	return null


static func get_entity_id(node: Node) -> String:
	var identity := get_identity(node)
	return identity.entity_id if identity != null else str(node.name if node != null else "")


static func get_state_machine(node: Node) -> StateMachine:
	var root := resolve_entity_root(node)
	if root != null:
		var state_machine := root.get_state_machine_node()
		if state_machine == null:
			_warn_missing(node, "state_machine", "StateMachine")
		return state_machine
	if node == null:
		return null
	_warn_missing(node, "state_machine", "StateMachine")
	return null


static func get_command_receiver(node: Node) -> CommandReceiver:
	var root := resolve_entity_root(node)
	if root != null:
		var receiver := root.get_command_receiver_node()
		if receiver == null:
			_warn_missing(node, "command_receiver", "CommandReceiver")
		return receiver
	if node == null:
		return null
	_warn_missing(node, "command_receiver", "CommandReceiver")
	return null


static func has_contract_node(node: Node, container: String, id_or_type: Variant) -> bool:
	if node == null or container.strip_edges() == "":
		return false
	var owner := resolve_entity_root(node)
	if owner == null:
		return false
	return get_contract_node(owner, container, id_or_type) != null


static func _warn_missing(node: Node, contract_kind: String, id_or_type: Variant) -> void:
	if node == null:
		return
	var owner := resolve_entity_root(node)
	var owner_name := node.name
	var owner_class := node.get_class()
	if owner != null:
		owner_name = owner.name
		owner_class = owner.get_class()
	push_warning(
		"EntityContract missing %s '%s' for %s(%s); add to %s."
		% [contract_kind, str(id_or_type), owner_name, owner_class, _format_contract_hint(contract_kind)]
	)


static func _format_contract_hint(contract_kind: String) -> String:
	match contract_kind:
		"component":
			return "Components/<component>"
		"controller":
			return "Controllers/<controller>"
		"identity":
			return "EntityIdentity"
		"state_machine":
			return "StateMachine"
		"command_receiver":
			return "CommandReceiver"
		_:
			return "entity contract"
