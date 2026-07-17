class_name Hfsm
extends StateMachineBase
## 说明：`Hfsm` 是 kernel 的层级状态机（Hierarchical FSM），驱动可嵌套状态的切换、命令冒泡和按帧更新。
## 上游：通常由实体场景的 `StateMachine` 节点承载，由 CommandReceiver、controller 或 AI 驱动。
## 下游：会连接 mkit 的服务、组件、资源或事件管线，不直接依赖具体游戏内容。
## 使用：当实体状态需要嵌套结构、层级路径寻址或命令向父状态冒泡时使用它；互斥的扁平状态请用 `Fsm`。
## 示例：`var instance := Hfsm.new()`

## 状态机启动时进入的状态节点路径；为空时使用第一个子状态或保持未启动。
@export var initial_state_path: String = ""
## 进入场景树后是否自动启动状态机；关闭后由调用方显式 start。
@export var auto_start: bool = true
## 状态机根状态节点；启动时解析并作为转移入口。
var root_state: HfsmState = null
## 当前处于激活链末端的叶子状态；命令优先交给它处理。
var current_leaf_state: HfsmState = null
## 上一次激活状态的路径字符串；用于调试转移和回退逻辑。
var previous_path: String = ""
## 最近一次成功转移的原因文本；用于调试和测试断言。
var last_transition_reason: String = ""
## 最近一次失败转移的原因文本；为空表示没有失败记录。
var last_failed_transition_reason: String = ""


func _ready() -> void:
	owner_entity = owner
	root_state = _find_root_state()
	if root_state != null:
		root_state.setup(self, owner_entity, null)
	if auto_start and initial_state_path != "":
		transition_to(initial_state_path, {"reason": "initial"})


func _process(delta: float) -> void:
	if current_leaf_state != null:
		_update_state_chain(current_leaf_state, delta, false)


func _physics_process(delta: float) -> void:
	if current_leaf_state != null:
		_update_state_chain(current_leaf_state, delta, true)


## 从当前叶子状态开始向父状态冒泡 GameCommand；任一 HfsmState.handle_command 返回 true 即停止并表示命令已消费。
func handle_command(command: GameCommand) -> bool:
	if current_leaf_state == null:
		return false
	var current: HfsmState = current_leaf_state
	while current != null:
		if current.handle_command(command):
			return true
		current = current.parent_state
	return false


## 按层级 path 切换到目标 HfsmState；会验证目标存在、当前链可退出、目标链可进入。
## 成功时执行最近公共祖先转移、更新 current_leaf_state 并发 `state_changed`；失败时记录 reason 并发 `transition_failed`。
func transition_to(target_path: String, context: Dictionary = {}) -> bool:
	var target := find_state_by_path(target_path)
	if target == null:
		_fail_transition(target_path, "Target state not found")
		return false
	if current_leaf_state == target:
		return true
	var from_path := get_current_path()
	if current_leaf_state != null and not _can_exit_chain(current_leaf_state, target, context):
		_fail_transition(target_path, "Current state chain cannot exit")
		return false
	if not _can_enter_chain(current_leaf_state, target, context):
		_fail_transition(target_path, "Target state chain cannot enter")
		return false
	_perform_lca_transition(current_leaf_state, target, context)
	previous_path = from_path
	current_leaf_state = _enter_initial_children(target, context)
	last_transition_reason = str(context.get("reason", ""))
	state_changed.emit(from_path, get_current_path())
	return true


## 返回当前叶子状态的完整层级路径；状态机尚未进入状态时返回空字符串。
func get_current_path() -> String:
	if current_leaf_state == null:
		return ""
	return current_leaf_state.get_full_path()


## 按层级路径查找状态节点；任一片段缺失时返回 null。
func find_state_by_path(path: String) -> HfsmState:
	if root_state == null:
		return null
	var parts := path.split("/", false)
	if parts.size() == 0:
		return null
	if parts[0] != root_state.state_id:
		return null
	var current := root_state
	for i in range(1, parts.size()):
		current = _find_child_state(current, parts[i])
		if current == null:
			return null
	return current


func _perform_lca_transition(from_state: HfsmState, to_state: HfsmState, context: Dictionary) -> void:
	if from_state == null:
		_enter_chain(null, to_state, context)
		return
	var lca := _find_lowest_common_ancestor(from_state, to_state)
	_exit_until(from_state, lca, context)
	_enter_chain(lca, to_state, context)


func _find_lowest_common_ancestor(a: HfsmState, b: HfsmState) -> HfsmState:
	var ancestors_a: Array[HfsmState] = []
	var current: HfsmState = a
	while current != null:
		ancestors_a.append(current)
		current = current.parent_state
	current = b
	while current != null:
		if ancestors_a.has(current):
			return current
		current = current.parent_state
	return null


func _exit_until(from_state: HfsmState, stop_state: HfsmState, context: Dictionary) -> void:
	var current := from_state
	while current != null and current != stop_state:
		current.exit(context)
		if current.parent_state != null and current.parent_state.active_child == current:
			current.parent_state.active_child = null
		current = current.parent_state


func _enter_chain(ancestor: HfsmState, target: HfsmState, context: Dictionary) -> void:
	var chain: Array[HfsmState] = []
	var current := target
	while current != null and current != ancestor:
		chain.push_front(current)
		current = current.parent_state
	for state in chain:
		if state.parent_state != null:
			state.parent_state.active_child = state
		state.enter(context)


func _enter_initial_children(state: HfsmState, context: Dictionary) -> HfsmState:
	var current := state
	while current.initial_child_state_id != "":
		var child := _find_child_state(current, current.initial_child_state_id)
		if child == null:
			break
		current.active_child = child
		child.enter(context)
		current = child
	return current


func _can_exit_chain(from_state: HfsmState, target_state: HfsmState, context: Dictionary) -> bool:
	var lca := _find_lowest_common_ancestor(from_state, target_state)
	var current := from_state
	while current != null and current != lca:
		if not current.can_exit(context):
			return false
		current = current.parent_state
	return true


func _can_enter_chain(from_state: HfsmState, target_state: HfsmState, context: Dictionary) -> bool:
	var lca: HfsmState = null
	if from_state != null:
		lca = _find_lowest_common_ancestor(from_state, target_state)
	var chain: Array[HfsmState] = []
	var current := target_state
	while current != null and current != lca:
		chain.push_front(current)
		current = current.parent_state
	for state in chain:
		if not state.can_enter(context):
			return false
	return true


func _update_state_chain(leaf: HfsmState, delta: float, physics: bool) -> void:
	var chain: Array[HfsmState] = []
	var current := leaf
	while current != null:
		chain.push_front(current)
		current = current.parent_state
	for state in chain:
		if physics:
			state.physics_update(delta)
		else:
			state.update(delta)


func _find_root_state() -> HfsmState:
	for child in get_children():
		if child is HfsmState:
			return child
	return null


func _find_child_state(parent: HfsmState, id: String) -> HfsmState:
	for child in parent.get_children():
		if child is HfsmState and child.state_id == id:
			return child
	return null


func _fail_transition(target_path: String, reason: String) -> void:
	last_failed_transition_reason = reason
	transition_failed.emit(get_current_path(), target_path, reason)
