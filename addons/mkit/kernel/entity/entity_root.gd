class_name EntityRoot
extends CharacterBody2D
## 说明：`EntityRoot` 是 实体系统 的实体根节点，负责提供实体场景的统一入口和契约路径。
## 上游：通常由同领域服务、controller、组件或内容资源创建或调用。
## 下游：会连接 mkit 的服务、组件、资源或事件管线，不直接依赖具体游戏内容。
## 使用：当项目需要在实体系统中复用这段契约或状态时使用它。
## 示例：`var instance := EntityRoot.new()`

## 运行时状态：`identity` 表示 `EntityRoot` 的字段值，由 `EntityRoot` 的公开 API 读取或维护。
var identity: EntityIdentity
## 运行时状态：`state_machine` 表示运行时状态，由 `EntityRoot` 的公开 API 读取或维护。
var state_machine: StateMachine
## 运行时状态：`command_receiver` 表示 `EntityRoot` 的字段值，由 `EntityRoot` 的公开 API 读取或维护。
var command_receiver: CommandReceiver


## 返回 `entity_identity` 对应的数据或对象，并保持 `EntityRoot` 的领域契约一致。
func get_entity_identity() -> EntityIdentity:
	if identity == null:
		identity = get_node_or_null("EntityIdentity")
	return identity


## 返回 `state_machine_node` 对应的数据或对象，并保持 `EntityRoot` 的领域契约一致。
func get_state_machine_node() -> StateMachine:
	if state_machine == null:
		state_machine = get_node_or_null("StateMachine")
	return state_machine


## 返回 `command_receiver_node` 对应的数据或对象，并保持 `EntityRoot` 的领域契约一致。
func get_command_receiver_node() -> CommandReceiver:
	if command_receiver == null:
		command_receiver = get_node_or_null("CommandReceiver")
	return command_receiver


## 返回 `entity_id` 对应的数据或对象，并保持 `EntityRoot` 的领域契约一致。
func get_entity_id() -> String:
	if identity == null:
		return name
	return identity.entity_id


## 返回 `component` 对应的数据或对象，并保持 `EntityRoot` 的领域契约一致。
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


## 返回 `controller` 对应的数据或对象，并保持 `EntityRoot` 的领域契约一致。
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


## 判断是否存在 `contract_node`，并保持 `EntityRoot` 的领域契约一致。
func has_contract_node(container: String, member: Variant) -> bool:
	if container == "Components":
		return get_component(member) != null
	if container == "Controllers":
		return get_controller(member) != null
	return false
