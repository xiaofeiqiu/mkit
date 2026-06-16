class_name Fsm
extends StateMachineBase
## 说明：`Fsm` 是 kernel 的扁平有限状态机（Flat FSM），管理一组互斥状态，按 `state_id` 单步转移，无嵌套、LCA 或命令冒泡。
## 上游：通常由实体场景的 `StateMachine` 节点承载，由 CommandReceiver、controller 或 AI 驱动。
## 下游：会连接 mkit 的服务、组件、资源或事件管线，不直接依赖具体游戏内容。
## 使用：当实体状态互斥且不需要层级时使用它；需要嵌套结构或命令向父状态冒泡时改用 `Hfsm`。
## 示例：`var instance := Fsm.new()`

## 状态机启动时进入的状态 id；为空时保持未启动。
@export var initial_state_id: String = ""
## 进入场景树后是否自动启动状态机；关闭后由调用方显式调用 transition_to。
@export var auto_start: bool = true
## 当前激活的状态；尚未启动或转移失败时为 null。
var current_state: FsmState = null
## 上一次激活状态的 id；用于调试转移和回退逻辑。
var previous_id: String = ""
## 最近一次成功转移的原因文本；用于调试和测试断言。
var last_transition_reason: String = ""
## 最近一次失败转移的原因文本；为空表示没有失败记录。
var last_failed_transition_reason: String = ""


func _ready() -> void:
	owner_entity = owner
	for child in get_children():
		if child is FsmState:
			child.setup(self, owner_entity)
	if auto_start and initial_state_id != "":
		transition_to(initial_state_id, {"reason": "initial"})


func _process(delta: float) -> void:
	if current_state != null:
		current_state.update(delta)


func _physics_process(delta: float) -> void:
	if current_state != null:
		current_state.physics_update(delta)


## 把 GameCommand 交给当前激活状态处理；没有激活状态时返回 false。扁平 FSM 不向其他状态冒泡，命中与否完全由当前状态决定。
func handle_command(command: GameCommand) -> bool:
	if current_state == null:
		return false
	return current_state.handle_command(command)


## 按 state_id 单步切换到目标状态；目标不存在或 can_exit/can_enter 拒绝时记录 reason 并发 `transition_failed` 返回 false。
## 成功时退出当前状态、更新 previous_id、进入目标状态并发 `state_changed`；切到同一状态视为成功的空操作。
func transition_to(target_id: String, context: Dictionary = {}) -> bool:
	var target := find_state(target_id)
	if target == null:
		_fail_transition(target_id, "Target state not found")
		return false
	if current_state == target:
		return true
	if current_state != null and not current_state.can_exit(context):
		_fail_transition(target_id, "Current state cannot exit")
		return false
	if not target.can_enter(context):
		_fail_transition(target_id, "Target state cannot enter")
		return false
	var from_id := get_current_id()
	if current_state != null:
		current_state.exit(context)
	previous_id = from_id
	current_state = target
	current_state.enter(context)
	last_transition_reason = str(context.get("reason", ""))
	state_changed.emit(from_id, target_id)
	return true


## 返回当前激活状态的 state_id；尚未进入状态时返回空字符串。
func get_current_id() -> String:
	if current_state == null:
		return ""
	return current_state.state_id


## 按 state_id 在直接子状态中查找；未找到时返回 null。
func find_state(target_id: String) -> FsmState:
	for child in get_children():
		if child is FsmState and child.state_id == target_id:
			return child
	return null


func _fail_transition(target_id: String, reason: String) -> void:
	last_failed_transition_reason = reason
	transition_failed.emit(get_current_id(), target_id, reason)
