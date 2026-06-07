# StateMachine

**层：** Kernel  
**文件：** `addons/mkit/kernel/state_machine/state_machine.gd`  
**继承：** `extends Node`

## 职责

层级有限状态机（HFSM）。管理 State 节点树，处理 transition（LCA 算法确保正确 exit/enter 顺序），每帧驱动整条状态链的 update，将命令从叶状态向根冒泡直到被消费。

## 字段（@export 和 public var）

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `initial_state_path` | `String` | `""` | `_ready` 时自动进入的初始状态路径（如 `"Root/Idle"`）|
| `auto_start` | `bool` | `true` | 若 true 且 `initial_state_path` 非空，`_ready` 时自动 transition |
| `owner_entity` | `Node` | `null` | 挂载此状态机的实体（`owner`，由 `_ready` 注入）|
| `blackboard` | `Blackboard` | `Blackboard.new()` | 所有 State 共享的黑板 |
| `current_leaf_state` | `State` | `null` | 当前最深层活跃状态 |
| `previous_path` | `String` | `""` | 上一次 transition 前的状态路径 |
| `last_transition_reason` | `String` | `""` | 最近一次成功 transition 的 reason |
| `last_failed_transition_reason` | `String` | `""` | 最近一次失败 transition 的原因（调试用）|

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `transition_to(target_path: String, context: Dictionary = {}) -> bool` | `bool` | 跳转到指定路径；经过 can_exit / can_enter 检查，失败返回 false |
| `handle_command(command: GameCommand) -> bool` | `bool` | 从叶状态向根冒泡找 handler；通常由 `CommandReceiver` 调用 |
| `get_current_path() -> String` | `String` | 返回当前叶状态完整路径如 `"Root/Combat/Attack"` |
| `find_state_by_path(path: String) -> State` | `State` | 按路径字符串查找 State 节点 |

## 信号

| 信号名 | 参数 | 触发时机 |
|--------|------|----------|
| `state_changed` | `previous_path: String, current_path: String` | 每次成功 transition 后 |
| `transition_failed` | `from_path: String, to_path: String, reason: String` | transition 失败时（can_enter 返回 false 等）|

## 使用模式

### 最小示例（Level 1）

```gdscript
# 在 State 内部请求跳转（推荐方式）
func handle_command(command: GameCommand) -> bool:
    if command.command_type == BuiltinCommands.ATTACK:
        return request_transition("Root/Attack")   # State.request_transition 内部调 state_machine.transition_to
    return false
```

### 典型场景（Level 2）

```gdscript
# 外部代码（如 UI 系统）直接操作状态机
func _on_dialogue_started(_dialogue_id: String) -> void:
    var player := get_tree().get_first_node_in_group("player")
    if player == null:
        return
    var sm := player.get_node_or_null("StateMachine") as StateMachine
    if sm == null:
        return

    # 进入对话状态（锁定输入）
    var ok := sm.transition_to("Root/Dialogue")
    if not ok:
        push_warning("Cannot enter Dialogue state: %s" % sm.last_failed_transition_reason)


func _on_dialogue_ended(_dialogue_id: String) -> void:
    var player := get_tree().get_first_node_in_group("player")
    if player == null:
        return
    var sm := player.get_node_or_null("StateMachine") as StateMachine
    if sm == null:
        return
    sm.transition_to("Root/Idle")


# 监听状态切换（如 Debug UI 展示当前状态）
func _setup_sm_debug(sm: StateMachine) -> void:
    sm.state_changed.connect(func(prev: String, curr: String) -> void:
        print("State: %s → %s" % [prev, curr])
    )
    sm.transition_failed.connect(func(from: String, to: String, reason: String) -> void:
        push_warning("Transition %s→%s failed: %s" % [from, to, reason])
    )


# 检查当前状态（用于条件判断，不要 hardcode 路径字符串）
func _is_player_in_combat() -> bool:
    var player := get_tree().get_first_node_in_group("player")
    if player == null:
        return false
    var sm := player.get_node_or_null("StateMachine") as StateMachine
    if sm == null:
        return false
    return sm.get_current_path().begins_with("Root/Combat")
```

**State 节点树示例：**

```
StateMachine              initial_state_path = "Root/Idle"
└── Root  (State)         state_id = "Root"
    ├── Idle  (State)     state_id = "Idle"
    ├── Move  (State)     state_id = "Move"
    ├── Attack (State)    state_id = "Attack"
    └── Dead  (State)     state_id = "Dead"
```

## 相关

- → [State](State.md) — 状态节点，实现各类 override
- → [Blackboard](Blackboard.md) — 状态机共享的键值存储
- → [CommandReceiver](CommandReceiver.md) — 调用 `state_machine.handle_command`
- → [pipeline.md — HFSM Transition](../../pipeline.md#4-hfsm-transition)
- → [debugging.md](../../debugging.md) — `last_failed_transition_reason` 调试状态切换
- → [cookbook/02_player_entity.md](../../cookbook/02_player_entity.md)
