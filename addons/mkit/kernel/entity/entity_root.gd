class_name EntityRoot
extends CharacterBody2D
## 说明：`EntityRoot` 是 实体系统 的实体根节点，负责提供实体场景的统一入口和契约路径。
## 上游：通常由同领域服务、controller、组件或内容资源创建或调用。
## 下游：会连接 mkit 的服务、组件、资源或事件管线，不直接依赖具体游戏内容。
## 使用：当项目需要在实体系统中复用这段契约或状态时使用它。
## 示例：`var instance := EntityRoot.new()`

## EntityRoot 缓存的 EntityIdentity 子节点；准备阶段解析 Components/Controllers 会使用它。
var identity: EntityIdentity
## 绑定到同一实体的状态机引用；可以是 Hfsm 或 Fsm，准备阶段解析后用于转发命令。
var state_machine: StateMachineBase
## EntityRoot 缓存的 CommandReceiver 子节点；命令管线通过它进入状态机。
var command_receiver: CommandReceiver


## 读取当前对象中的 `entity_identity`；未找到时返回 null、空集合或该 API 的默认值。
func get_entity_identity() -> EntityIdentity:
	if identity == null:
		identity = get_node_or_null("EntityIdentity")
	return identity


## 读取当前对象中的 `state_machine_node`；未找到时返回 null、空集合或该 API 的默认值。
func get_state_machine_node() -> StateMachineBase:
	if state_machine == null:
		state_machine = get_node_or_null("StateMachine")
	return state_machine


## 读取当前对象中的 `command_receiver_node`；未找到时返回 null、空集合或该 API 的默认值。
func get_command_receiver_node() -> CommandReceiver:
	if command_receiver == null:
		command_receiver = get_node_or_null("CommandReceiver")
	return command_receiver


## 读取当前对象中的 `entity_id`；未找到时返回 null、空集合或该 API 的默认值。
func get_entity_id() -> String:
	var resolved_identity := get_entity_identity()
	if resolved_identity == null:
		return name
	return resolved_identity.entity_id


## 读取当前对象中的 `component`；未找到时返回 null、空集合或该 API 的默认值。
func get_component(component_name: Variant) -> Node:
	return get_contract_node("Components", component_name)


## 读取当前对象中的 `controller`；未找到时返回 null、空集合或该 API 的默认值。
func get_controller(controller_name: Variant) -> Node:
	return get_contract_node("Controllers", controller_name)


## 从约定容器中按节点名或脚本类型读取成员；Components、Controllers 和 Presentation 共用同一查找规则。
func get_contract_node(container: String, member: Variant) -> Node:
	if container.strip_edges() == "":
		return null
	if member is String or member is StringName:
		return get_node_or_null("%s/%s" % [container, str(member)])
	if member is Script:
		var container_node := get_node_or_null(container) as Node
		if container_node == null:
			return null
		for child in container_node.get_children():
			if child != null and child.get_script() == member:
				return child
	return null


## 检查当前集合或对象是否包含 `contract_node`；缺失或空值时返回 false。
func has_contract_node(container: String, member: Variant) -> bool:
	return get_contract_node(container, member) != null
