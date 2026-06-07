class_name EntityContract
extends RefCounted

static var _warned_contract_lookup: Dictionary = {}


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
	if owner != null:
		var component := owner.get_component(id_or_type)
		if component == null:
			_warn_missing(node, "component", id_or_type)
		return component
	_warn_missing(node, "component", id_or_type)
	return _legacy_lookup(node, "Components", id_or_type)


static func get_controller(node: Node, id_or_type: Variant) -> Node:
	var owner := resolve_entity_root(node)
	if owner != null:
		var controller := owner.get_controller(id_or_type)
		if controller == null:
			_warn_missing(node, "controller", id_or_type)
		return controller
	_warn_missing(node, "controller", id_or_type)
	return _legacy_lookup(node, "Controllers", id_or_type)


static func get_contract_node(node: Node, container: String, id_or_type: Variant) -> Node:
	if node == null or container.strip_edges() == "":
		return null
	var target := _legacy_lookup(node, container, id_or_type)
	if target == null:
		_warn_missing(node, "contract:%s" % container, id_or_type)
	return target


static func get_identity(node: Node) -> EntityIdentity:
	var owner := resolve_entity_root(node)
	if owner != null:
		var identity := owner.get_entity_identity()
		if identity == null:
			_warn_missing(node, "identity", "EntityIdentity")
		return identity
	_warn_missing(node, "identity", "EntityIdentity")
	return _legacy_lookup(node, "", "EntityIdentity") as EntityIdentity


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
	var state_machine := node.get_node_or_null("StateMachine") as StateMachine
	if state_machine == null:
		_warn_missing(node, "state_machine", "StateMachine")
	return state_machine


static func get_command_receiver(node: Node) -> CommandReceiver:
	var root := resolve_entity_root(node)
	if root != null:
		var receiver := root.get_command_receiver_node()
		if receiver == null:
			_warn_missing(node, "command_receiver", "CommandReceiver")
		return receiver
	if node == null:
		return null
	var receiver := node.get_node_or_null("CommandReceiver") as CommandReceiver
	if receiver == null:
		_warn_missing(node, "command_receiver", "CommandReceiver")
	return receiver


static func has_contract_node(node: Node, container: String, id_or_type: Variant) -> bool:
	if node == null or container.strip_edges() == "":
		return false
	return _legacy_lookup(node, container, id_or_type) != null


static func _legacy_lookup(node: Node, container: String, id_or_type: Variant) -> Node:
	if node == null:
		return null
	if container == "":
		return node.get_node_or_null(str(id_or_type)) if node != null else null
	if id_or_type is String or id_or_type is StringName:
		return node.get_node_or_null("%s/%s" % [container, str(id_or_type)])
	var container_node := node.get_node_or_null(container) as Node
	if container_node == null:
		return null
	if id_or_type is Script:
		for child in container_node.get_children():
			if child != null and child.get_script() == id_or_type:
				return child
	return null


static func _warn_missing(node: Node, contract_kind: String, id_or_type: Variant) -> void:
	if node == null:
		return
	var owner := resolve_entity_root(node)
	var owner_name := node.name if node != null else "null"
	if owner != null:
		owner_name = owner.name
	var contract_class := "Node"
	if owner != null:
		contract_class = owner.get_class()
	var key := "%s|%s|%s|%s" % [str(node.get_instance_id()), contract_kind, contract_class, str(id_or_type)]
	if _warned_contract_lookup.has(key):
		return
	_warned_contract_lookup[key] = true
	push_warning(
		"EntityContract missing %s '%s' for %s(%s); add to %s."
		% [contract_kind, str(id_or_type), owner_name, contract_class, _format_contract_hint(contract_kind)]
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
