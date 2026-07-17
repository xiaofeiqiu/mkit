class_name FsmState
extends Node
## 说明：`FsmState` 是 `Fsm` 的扁平状态节点，一组互斥状态中的一个，没有嵌套、LCA 或命令冒泡。
## 上游：通常作为实体场景 `StateMachine` 节点下挂 `Fsm` 时的直接子节点，由 `Fsm` 解析并驱动。
## 下游：会连接 mkit 的服务、组件、资源或事件管线，不直接依赖具体游戏内容。
## 使用：继承本类实现互斥状态逻辑；需要嵌套子状态时改用 `HfsmState`。
## 示例：`var instance := FsmState.new()`

## Fsm 内部引用该状态的稳定 id；同一状态机内应保持唯一。
@export var state_id: String = ""
## 绑定到同一实体的 Fsm 引用；准备阶段解析后用于请求转移。
var fsm: Fsm = null
## 拥有该运行时对象的实体节点；通常是 EntityRoot 或其子节点。
var owner_entity: Node = null
## 跨状态或 AI 决策共享的临时键值数据；由所属 Fsm 注入，所有状态共享。
var blackboard: Blackboard = null


## 绑定所属 Fsm、owner entity 和共享 blackboard；扁平状态不递归子节点。
func setup(machine: Fsm, entity: Node) -> void:
	fsm = machine
	owner_entity = entity
	blackboard = machine.blackboard


## 状态进入 hook；Fsm 完成 can_enter 检查后调用，子类在这里启动动画、action 或临时状态。
func enter(context: Dictionary = {}) -> void:
	pass


## 状态退出 hook；Fsm 切到其他状态前调用，子类在这里取消临时流程或清理状态。
func exit(context: Dictionary = {}) -> void:
	pass


## 每帧状态更新 hook；Fsm 只会对当前激活状态调用。
func update(delta: float) -> void:
	pass


## 按 physics delta 推进状态；由 Fsm 在物理帧对当前激活状态调用。
func physics_update(delta: float) -> void:
	pass


## 处理命令的状态 hook；默认不消费，子类覆写并返回 true 表示已消费。扁平 FSM 不向其他状态冒泡。
func handle_command(command: GameCommand) -> bool:
	return false


## 返回当前状态是否允许进入；Fsm transition_to 会在进入前调用。
func can_enter(context: Dictionary = {}) -> bool:
	return true


## 返回当前状态是否允许退出；Fsm transition_to 会在离开前调用。
func can_exit(context: Dictionary = {}) -> bool:
	return true


## 向所属 Fsm 请求按 state_id 切换状态；没有绑定 fsm 时返回 false。
func request_transition(target_id: String, context: Dictionary = {}) -> bool:
	if fsm == null:
		return false
	return fsm.transition_to(target_id, context)
