class_name State
extends Node
## 说明：`State` 是 状态机 的状态节点，负责作为 StateMachine 的可嵌套状态单元。
## 上游：通常由同领域服务、controller、组件或内容资源创建或调用。
## 下游：会连接 mkit 的服务、组件、资源或事件管线，不直接依赖具体游戏内容。
## 使用：当项目需要在状态机中复用这段契约或状态时使用它。
## 示例：`var instance := State.new()`

## StateMachine 内部引用该状态的稳定 id；同级状态应保持唯一。
@export var state_id: String = ""
## 进入复合状态时默认激活的子状态 id；为空时不自动进入子状态。
@export var initial_child_state_id: String = ""
## 父状态引用；根状态为空。
var parent_state: State = null
## 绑定到同一实体的 StateMachine 引用；准备阶段解析后用于转发命令。
var state_machine: StateMachine = null
## 拥有该运行时对象的实体节点；通常是 EntityRoot 或其子节点。
var owner_entity: Node = null
## 复合状态当前激活的直接子状态；无子状态时为 null。
var active_child: State = null
## 跨状态或 AI 决策共享的临时键值数据；同一拥有者生命周期内复用。
var blackboard: Blackboard = null


## 绑定所属 StateMachine、owner entity、parent state 和共享 blackboard，并递归 setup 子状态。
func setup(machine: StateMachine, entity: Node, parent: State = null) -> void:
	state_machine = machine
	owner_entity = entity
	parent_state = parent
	blackboard = machine.blackboard
	for child in get_children():
		if child is State:
			child.setup(machine, entity, self)


## 状态进入 hook；StateMachine 完成 can_enter 检查后调用，子类在这里启动动画、action 或临时状态。
func enter(context: Dictionary = {}) -> void:
	pass


## 状态退出 hook；StateMachine 离开该状态链时调用，子类在这里取消临时流程或清理状态。
func exit(context: Dictionary = {}) -> void:
	pass


## 每帧状态更新 hook；StateMachine 会从当前叶子到父链调用。
func update(delta: float) -> void:
	pass


## 按 physics delta 推进状态；由 StateMachine 在物理帧调用。
func physics_update(delta: float) -> void:
	pass


## 处理命令的状态 hook；默认先交给 active_child，子类可覆写并返回 true 表示已消费。
func handle_command(command: GameCommand) -> bool:
	if active_child != null:
		if active_child.handle_command(command):
			return true
	return false


## 返回当前状态是否允许进入；StateMachine transition_to 会在进入链前调用。
func can_enter(context: Dictionary = {}) -> bool:
	return true


## 返回当前状态是否允许退出；StateMachine transition_to 会在离开链前调用。
func can_exit(context: Dictionary = {}) -> bool:
	return true


## 向所属 StateMachine 请求切换状态；没有绑定 state_machine 时返回 false。
func request_transition(target_path: String, context: Dictionary = {}) -> bool:
	if state_machine == null:
		return false
	return state_machine.transition_to(target_path, context)


## 返回从根状态到当前状态的 id 列表；用于构建层级路径和最近公共祖先计算。
func get_path_ids() -> Array[String]:
	var result: Array[String] = []
	var current: State = self
	while current != null:
		result.push_front(current.state_id)
		current = current.parent_state
	return result


## 返回以 `/` 拼接的完整状态路径，例如 `Root/Move/Attack`。
func get_full_path() -> String:
	return "/".join(get_path_ids())
