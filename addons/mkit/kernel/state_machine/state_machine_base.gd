class_name StateMachineBase
extends Node
## 说明：`StateMachineBase` 是状态机的共享契约基类，统一命令入口与转移信号，让 `Hfsm` 与 `Fsm` 都能挂到 `EntityRoot/StateMachine` 节点上被命令管线驱动。
## 上游：通常由 CommandReceiver、controller、组件或内容资源通过 handle_command 调用。
## 下游：会连接 mkit 的服务、组件、资源或事件管线，不直接依赖具体游戏内容。
## 使用：实体接线层（EntityRoot / CommandReceiver / EntityContract）面向本基类编程，不关心具体是层级还是扁平状态机。
## 示例：`var machine: StateMachineBase = entity.get_state_machine_node()`

## 状态切换成功后发出，携带切换前后的状态标识（HFSM 为层级路径，FSM 为单个 state_id），供 UI、音频、VFX、任务或测试订阅。
signal state_changed(previous: String, current: String)
## 转移被拒绝或目标不存在时发出，携带来源、目标标识和失败原因，供调试和测试订阅。
signal transition_failed(from: String, to: String, reason: String)

## 拥有该状态机的实体节点；通常是 EntityRoot 或其子节点，转移和状态 hook 通过它访问组件与控制器。
var owner_entity: Node = null
## 跨状态或 AI 决策共享的临时键值数据；同一状态机生命周期内的所有状态共享读写。
var blackboard: Blackboard = Blackboard.new()


## 把 GameCommand 交给当前激活状态处理的统一入口；基类默认不消费任何命令并返回 false，子类按各自的命令分发策略覆写。
func handle_command(command: GameCommand) -> bool:
	return false
