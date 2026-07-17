class_name EntityContract
extends RefCounted
## 说明：`EntityContract` 是 实体系统 的契约工具，负责集中校验实体场景的约定子节点。
## 上游：通常由同领域服务、controller、组件或内容资源创建或调用。
## 下游：会连接 mkit 的服务、组件、资源或事件管线，不直接依赖具体游戏内容。
## 使用：当项目需要在实体系统中复用这段契约或状态时使用它。
## 示例：`var instance := EntityContract.new()`


## 执行 `resolve_entity_root` API；读取当前运行时状态，并通过返回值、signal 或事件报告结果。
static func resolve_entity_root(node: Node) -> EntityRoot:
	if node == null:
		return null
	var current := node
	while current != null:
		if current is EntityRoot:
			return current as EntityRoot
		current = current.get_parent()
	return null

## 读取当前对象中的 `component`；未找到时返回 null、空集合或该 API 的默认值。
static func get_component(node: Node, id_or_type: Variant) -> Node:
	return _get_member(node, "Components", "component", id_or_type, true)


## 读取当前对象中的 `controller`；未找到时返回 null、空集合或该 API 的默认值。
static func get_controller(node: Node, id_or_type: Variant) -> Node:
	return _get_member(node, "Controllers", "controller", id_or_type, true)


## 读取当前对象中的 `contract_node`；未找到时返回 null、空集合或该 API 的默认值。
static func get_contract_node(node: Node, container: String, id_or_type: Variant) -> Node:
	if node == null or container.strip_edges() == "":
		return null
	return _get_member(node, container, "contract:%s" % container, id_or_type, false)


## 读取当前对象中的 `identity`；未找到时返回 null、空集合或该 API 的默认值。
static func get_identity(node: Node) -> EntityIdentity:
	var owner := resolve_entity_root(node)
	if owner != null:
		var identity := owner.get_entity_identity()
		if identity == null:
			_warn_missing(node, "identity", "EntityIdentity")
		return identity
	_warn_missing(node, "identity", "EntityIdentity")
	return null


## 读取当前对象中的 `entity_id`；未找到时返回 null、空集合或该 API 的默认值。
static func get_entity_id(node: Node) -> String:
	var identity := get_identity(node)
	return identity.entity_id if identity != null else str(node.name if node != null else "")


## 读取当前对象中的 `state_machine`；未找到时返回 null、空集合或该 API 的默认值。
static func get_state_machine(node: Node) -> StateMachineBase:
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


## 读取当前对象中的 `command_receiver`；未找到时返回 null、空集合或该 API 的默认值。
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


## 检查当前集合或对象是否包含 `contract_node`；缺失或空值时返回 false。
static func has_contract_node(node: Node, container: String, id_or_type: Variant) -> bool:
	if node == null or container.strip_edges() == "":
		return false
	var owner := resolve_entity_root(node)
	if owner == null:
		return false
	return get_contract_node(owner, container, id_or_type) != null


static func _get_member(
	node: Node,
	container: String,
	contract_kind: String,
	id_or_type: Variant,
	warn_if_missing: bool
) -> Node:
	var owner := resolve_entity_root(node)
	if owner == null:
		if warn_if_missing:
			_warn_missing(node, contract_kind, id_or_type)
		return null
	var member := owner.get_contract_node(container, id_or_type)
	if member == null and warn_if_missing:
		_warn_missing(node, contract_kind, id_or_type)
	return member


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
