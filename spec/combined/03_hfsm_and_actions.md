# HFSM and Actions

---

# 4. HFSM 接口设计

---

## 4.1 State

### 概念说明

- 是什么：HFSM 中的一个行为模式。
- 负责什么：处理 enter、exit、update、physics_update、命令响应、守卫条件和状态转换请求。
- 为什么需要：Idle、Move、Attack、Cast、Dead、Paused 等行为如果混在一个脚本里会很难维护，拆成状态后逻辑边界更清楚。

### 文件

`res://addons/mkit/kernel/state_machine/state.gd`

```gdscript
class_name State
extends Node

@export var state_id: String = ""
@export var initial_child_state_id: String = ""

var parent_state: State = null
var state_machine: StateMachine = null
var owner_entity: Node = null
var active_child: State = null
var blackboard: Blackboard = null

func setup(machine: StateMachine, entity: Node, parent: State = null) -> void:
    state_machine = machine
    owner_entity = entity
    parent_state = parent
    blackboard = machine.blackboard

    for child in get_children():
        if child is State:
            child.setup(machine, entity, self)

func enter(context: Dictionary = {}) -> void:
    pass

func exit(context: Dictionary = {}) -> void:
    pass

func update(delta: float) -> void:
    pass

func physics_update(delta: float) -> void:
    pass

func handle_command(command: GameCommand) -> bool:
    if active_child != null:
        if active_child.handle_command(command):
            return true
    return false

func can_enter(context: Dictionary = {}) -> bool:
    return true

func can_exit(context: Dictionary = {}) -> bool:
    return true

func request_transition(target_path: String, context: Dictionary = {}) -> bool:
    if state_machine == null:
        return false
    return state_machine.transition_to(target_path, context)

func get_path_ids() -> Array[String]:
    var result: Array[String] = []
    var current: State = self
    while current != null:
        result.push_front(current.state_id)
        current = current.parent_state
    return result

func get_full_path() -> String:
    return "/".join(get_path_ids())
```

#### 字段说明
- **state_id**：稳定 ID 字段。例：State 通过 state_id 引用某个定义或运行时对象，避免直接保存节点路径。
- **initial_child_state_id**：稳定 ID 字段。例：State 通过 initial_child_state_id 引用某个定义或运行时对象，避免直接保存节点路径。
- **state_machine**：所属状态机引用。例：AttackState 完成后通过 state_machine 请求回到 Idle。
- **owner_entity**：拥有该组件或状态机的实体。例：PlayerMoveState 需要通过 owner_entity 读取 StatsComponent 并推动 CharacterBody2D。
#### 函数使用场景
- **setup()**：公开 API。实际例子：外部系统通过它请求 **State** 执行一个明确操作，并通过返回值、信号或状态变化确认结果。
- **enter()**：进入状态时调用。实际例子：Player 进入 AttackState 时播放攻击动画并启动 TimedAttackAction。
- **exit()**：离开状态时调用。实际例子：DashState 退出时关闭无敌标记或清理移动输入。
- **update()**：每帧逻辑更新。实际例子：StatusEffectController 每帧减少燃烧剩余时间。
- **physics_update()**：物理帧更新。实际例子：MoveState 在这里读取方向并调用 move_and_slide。
- **handle_command()**：处理命令。实际例子：MoveState 收到 attack 命令时请求切到 BasicAttack 状态。
- **can_enter()**：合法性检查。实际例子：释放技能前先调用 can_enter，失败时 UI 显示冷却中或目标太远。
- **can_exit()**：合法性检查。实际例子：释放技能前先调用 can_exit，失败时 UI 显示冷却中或目标太远。
- **request_transition()**：公开 API。实际例子：外部系统通过它请求 **State** 执行一个明确操作，并通过返回值、信号或状态变化确认结果。
- **get_path_ids()**：读取数据入口。实际例子：CombatResolver 通过 get_path_ids 获取最终攻击力，而不是直接读内部变量。
- **get_full_path()**：读取数据入口。实际例子：CombatResolver 通过 get_full_path 获取最终攻击力，而不是直接读内部变量。

---

### 27.14 State 使用示例

#### 详细实际用例

- 真实场景：玩家有 `IdleState`、`MoveState`、`BasicAttackState`。`MoveState` 收到 attack 命令时不自己扣血，而是请求切到 `Combat/BasicAttack`。
- 怎么使用：把“当前处于什么行为模式”写进 State；把伤害公式、掉落、背包修改留给对应系统。
- 验证重点：每个 State 的 enter/exit 都能在 DebugOverlay 中看到；当前状态不能处理的命令应被明确拒绝。
### Idle State

```gdscript
class_name PlayerIdleState
extends State

func enter(context: Dictionary = {}) -> void:
    owner_entity.velocity = Vector2.ZERO
    print("Enter Idle")

func handle_command(command: GameCommand) -> bool:
    if command.command_type == BuiltinCommands.MOVE:
        blackboard.set_value("move_direction", command.get_vector2("direction"))
        return request_transition("Player/Alive/Locomotion/Move", {"reason": "move"})

    if command.command_type == BuiltinCommands.ATTACK:
        return request_transition("Player/Alive/Combat/BasicAttack", {
            "reason": "attack",
            "command": command
        })

    return false
```

### Dead State

```gdscript
class_name PlayerDeadState
extends State

func enter(context: Dictionary = {}) -> void:
    owner_entity.velocity = Vector2.ZERO
    var anim := owner_entity.get_node("Presentation/AnimationPlayer") as AnimationPlayer
    anim.play("death")

func can_exit(context: Dictionary = {}) -> bool:
    return context.get("allow_revive", false)
```

---

---

---

## 4.2 StateMachine

### 概念说明

- 是什么：当前行为状态和状态转换的拥有者。
- 负责什么：注册状态、跟踪当前状态路径、分发命令和 update、执行合法转换并暴露调试信息。
- 为什么需要：玩家、敌人、房间和 Run 都会有复杂状态，统一 StateMachine 能减少大量布尔变量组合。

### 文件

`res://addons/mkit/kernel/state_machine/state_machine.gd`

```gdscript
class_name StateMachine
extends Node

signal state_changed(previous_path: String, current_path: String)
signal transition_failed(from_path: String, to_path: String, reason: String)

@export var initial_state_path: String = ""
@export var auto_start: bool = true

var owner_entity: Node = null
var root_state: State = null
var current_leaf_state: State = null
var blackboard: Blackboard = Blackboard.new()
var previous_path: String = ""
var last_transition_reason: String = ""
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

func handle_command(command: GameCommand) -> bool:
    if current_leaf_state == null:
        return false

    var current: State = current_leaf_state
    while current != null:
        if current.handle_command(command):
            return true
        current = current.parent_state

    return false

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

func get_current_path() -> String:
    if current_leaf_state == null:
        return ""
    return current_leaf_state.get_full_path()

func find_state_by_path(path: String) -> State:
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

func _perform_lca_transition(from_state: State, to_state: State, context: Dictionary) -> void:
    if from_state == null:
        _enter_chain(null, to_state, context)
        return

    var lca := _find_lowest_common_ancestor(from_state, to_state)
    _exit_until(from_state, lca, context)
    _enter_chain(lca, to_state, context)

func _find_lowest_common_ancestor(a: State, b: State) -> State:
    var ancestors_a: Array[State] = []
    var current: State = a
    while current != null:
        ancestors_a.append(current)
        current = current.parent_state

    current = b
    while current != null:
        if ancestors_a.has(current):
            return current
        current = current.parent_state
    return null

func _exit_until(from_state: State, stop_state: State, context: Dictionary) -> void:
    var current := from_state
    while current != null and current != stop_state:
        current.exit(context)
        if current.parent_state != null and current.parent_state.active_child == current:
            current.parent_state.active_child = null
        current = current.parent_state

func _enter_chain(ancestor: State, target: State, context: Dictionary) -> void:
    var chain: Array[State] = []
    var current := target
    while current != null and current != ancestor:
        chain.push_front(current)
        current = current.parent_state

    for state in chain:
        if state.parent_state != null:
            state.parent_state.active_child = state
        state.enter(context)

func _enter_initial_children(state: State, context: Dictionary) -> State:
    var current := state
    while current.initial_child_state_id != "":
        var child := _find_child_state(current, current.initial_child_state_id)
        if child == null:
            break
        current.active_child = child
        child.enter(context)
        current = child
    return current

func _can_exit_chain(from_state: State, target_state: State, context: Dictionary) -> bool:
    var lca := _find_lowest_common_ancestor(from_state, target_state)
    var current := from_state
    while current != null and current != lca:
        if not current.can_exit(context):
            return false
        current = current.parent_state
    return true

func _can_enter_chain(from_state: State, target_state: State, context: Dictionary) -> bool:
    var lca: State = null
    if from_state != null:
        lca = _find_lowest_common_ancestor(from_state, target_state)
    var chain: Array[State] = []
    var current := target_state
    while current != null and current != lca:
        chain.push_front(current)
        current = current.parent_state
    for state in chain:
        if not state.can_enter(context):
            return false
    return true

func _update_state_chain(leaf: State, delta: float, physics: bool) -> void:
    var chain: Array[State] = []
    var current := leaf
    while current != null:
        chain.push_front(current)
        current = current.parent_state
    for state in chain:
        if physics:
            state.physics_update(delta)
        else:
            state.update(delta)

func _find_root_state() -> State:
    for child in get_children():
        if child is State:
            return child
    return null

func _find_child_state(parent: State, id: String) -> State:
    for child in parent.get_children():
        if child is State and child.state_id == id:
            return child
    return null

func _fail_transition(target_path: String, reason: String) -> void:
    last_failed_transition_reason = reason
    transition_failed.emit(get_current_path(), target_path, reason)
```

#### 字段说明
- **initial_state_path**：资源或节点路径。例：用 initial_state_path 指向场景或节点，方便在 Inspector 中配置。
- **owner_entity**：拥有该组件或状态机的实体。例：PlayerMoveState 需要通过 owner_entity 读取 StatsComponent 并推动 CharacterBody2D。
- **previous_path**：资源或节点路径。例：用 previous_path 指向场景或节点，方便在 Inspector 中配置。
#### 信号说明
- **state_changed**：当 **StateMachine** 发生对应玩法事实时发出。实际例子：UI 或 FeedbackSystem 连接这个信号后刷新界面、播放音效或记录 Debug trace。
- **transition_failed**：当 **StateMachine** 发生对应玩法事实时发出。实际例子：UI 或 FeedbackSystem 连接这个信号后刷新界面、播放音效或记录 Debug trace。
#### 函数使用场景
- **_ready()**：Godot ready 生命周期回调。实际例子：**StateMachine** 在进入场景树后缓存子节点、生成默认 ID、连接需要的信号或执行自动注册；具体行为以代码为准，不等于所有组件都注册服务。
- **_process()**：内部辅助函数。实际例子：由 **StateMachine** 的公开流程调用，用来完成 $fn 对应的子步骤；外部系统通常不应该直接调用它。
- **_physics_process()**：内部辅助函数。实际例子：由 **StateMachine** 的公开流程调用，用来完成 $fn 对应的子步骤；外部系统通常不应该直接调用它。
- **handle_command()**：处理命令。实际例子：MoveState 收到 attack 命令时请求切到 BasicAttack 状态。
- **transition_to()**：公开 API。实际例子：外部系统通过它请求 **StateMachine** 执行一个明确操作，并通过返回值、信号或状态变化确认结果。
- **get_current_path()**：读取数据入口。实际例子：CombatResolver 通过 get_current_path 获取最终攻击力，而不是直接读内部变量。
- **find_state_by_path()**：公开 API。实际例子：外部系统通过它请求 **StateMachine** 执行一个明确操作，并通过返回值、信号或状态变化确认结果。
- **_perform_lca_transition()**：内部辅助函数。实际例子：由 **StateMachine** 的公开流程调用，用来完成 $fn 对应的子步骤；外部系统通常不应该直接调用它。
- **_find_lowest_common_ancestor()**：内部辅助函数。实际例子：由 **StateMachine** 的公开流程调用，用来完成 $fn 对应的子步骤；外部系统通常不应该直接调用它。
- **_exit_until()**：内部辅助函数。实际例子：由 **StateMachine** 的公开流程调用，用来完成 $fn 对应的子步骤；外部系统通常不应该直接调用它。
- **_enter_chain()**：内部辅助函数。实际例子：由 **StateMachine** 的公开流程调用，用来完成 $fn 对应的子步骤；外部系统通常不应该直接调用它。
- **_enter_initial_children()**：内部辅助函数。实际例子：由 **StateMachine** 的公开流程调用，用来完成 $fn 对应的子步骤；外部系统通常不应该直接调用它。
- **_can_exit_chain()**：内部辅助函数。实际例子：由 **StateMachine** 的公开流程调用，用来完成 $fn 对应的子步骤；外部系统通常不应该直接调用它。
- **_can_enter_chain()**：内部辅助函数。实际例子：由 **StateMachine** 的公开流程调用，用来完成 $fn 对应的子步骤；外部系统通常不应该直接调用它。
- **_update_state_chain()**：内部辅助函数。实际例子：由 **StateMachine** 的公开流程调用，用来完成 $fn 对应的子步骤；外部系统通常不应该直接调用它。
- **_find_root_state()**：内部辅助函数。实际例子：由 **StateMachine** 的公开流程调用，用来完成 $fn 对应的子步骤；外部系统通常不应该直接调用它。
- **_find_child_state()**：内部辅助函数。实际例子：由 **StateMachine** 的公开流程调用，用来完成 $fn 对应的子步骤；外部系统通常不应该直接调用它。
- **_fail_transition()**：内部辅助函数。实际例子：由 **StateMachine** 的公开流程调用，用来完成 $fn 对应的子步骤；外部系统通常不应该直接调用它。

---

---

### 27.15 StateMachine 使用示例

#### 详细实际用例

- 真实场景：玩家从 `Player/Alive/Locomotion/Move` 切到 `Player/Alive/Combat/BasicAttack` 时，StateMachine 退出 Move/Locomotion，进入 Combat/BasicAttack；如果期间死亡，直接切到 `Player/Dead`。
- 怎么使用：把状态层级组织成树，用 `transition_to()` 管理切换，不要在各个脚本里手动开关一堆 bool。
- 验证重点：LCA 转换顺序正确，exit/enter 调用顺序可追踪，失败转换能给出原因。
### 场景结构

```text
Player.tscn
  StateMachine
    Player
      Alive
        Locomotion
          Idle
          Move
          Dash
        Combat
          BasicAttack
          CastAbility
      Dead
```

### 初始化状态

```gdscript
func _ready() -> void:
    var sm := $StateMachine as StateMachine
    sm.initial_state_path = "Player/Alive/Locomotion/Idle"
    sm.state_changed.connect(_on_state_changed)

func _on_state_changed(previous: String, current: String) -> void:
    print("State changed: %s -> %s" % [previous, current])
```

### 强制切换到死亡状态

```gdscript
func _on_health_died(owner_entity: Node) -> void:
    var sm := owner_entity.get_node("StateMachine") as StateMachine
    sm.transition_to("Player/Dead", {"reason": "hp_zero"})
```

---

---

---

## 4.3 Player HFSM 建议结构

### 概念说明

- 是什么：玩家行为状态树的推荐组织方式。
- 负责什么：把 Alive/Dead、Locomotion、Combat、Cast、Dash 等层级拆清楚。
- 为什么需要：层级结构可以让死亡、眩晕等全局转换干净地覆盖移动或攻击中的子状态。

```text
Player
  Alive
    Locomotion
      Idle
      Move
      Dash
    Combat
      BasicAttack
      CastAbility
    Interacting
  Stunned
  Dead
```

### IdleState 伪代码

```gdscript
class_name PlayerIdleState
extends State

func enter(context: Dictionary = {}) -> void:
    owner_entity.velocity = Vector2.ZERO
    _play_animation("idle")

func handle_command(command: GameCommand) -> bool:
    match command.command_type:
        BuiltinCommands.MOVE:
            blackboard.set_value("move_direction", command.get_vector2("direction"))
            return request_transition("Player/Alive/Locomotion/Move", {"reason": "move_command"})
        BuiltinCommands.ATTACK:
            return request_transition("Player/Alive/Combat/BasicAttack", {"command": command, "reason": "attack_command"})
        BuiltinCommands.CAST_ABILITY:
            return request_transition("Player/Alive/Combat/CastAbility", {"command": command, "reason": "cast_command"})
        BuiltinCommands.DASH:
            return request_transition("Player/Alive/Locomotion/Dash", {"command": command, "reason": "dash_command"})
    return false

func _play_animation(name: String) -> void:
    var anim := owner_entity.get_node_or_null("Presentation/AnimationPlayer") as AnimationPlayer
    if anim != null:
        anim.play(name)
```

#### 函数使用场景
- **enter()**：进入状态时调用。实际例子：Player 进入 AttackState 时播放攻击动画并启动 TimedAttackAction。
- **handle_command()**：处理命令。实际例子：MoveState 收到 attack 命令时请求切到 BasicAttack 状态。
- **_play_animation()**：内部辅助函数。实际例子：由 **PlayerIdleState** 的公开流程调用，用来完成 $fn 对应的子步骤；外部系统通常不应该直接调用它。

### BasicAttackState 伪代码

```gdscript
class_name PlayerBasicAttackState
extends State

var current_action: GameAction = null

func enter(context: Dictionary = {}) -> void:
    var command := context.get("command") as GameCommand
    var action_context := ActionContext.from_command(command, owner_entity, null)
    action_context.payload["attack_definition_id"] = "basic_attack"

    current_action = TimedAttackAction.new()
    current_action.completed.connect(_on_action_completed)
    current_action.cancelled.connect(_on_action_cancelled)

    var runner := ServiceRegistry.get_service("actions") as ActionRunner
    runner.start_action(current_action, action_context)

func exit(context: Dictionary = {}) -> void:
    if current_action != null and not current_action.is_finished():
        current_action.cancel("state_exit")
    current_action = null

func handle_command(command: GameCommand) -> bool:
    # 可以加 animation cancel 逻辑，例如 attack recovery 期间允许 dash
    if command.command_type == BuiltinCommands.DASH:
        if current_action != null and current_action.can_cancel_with("dash"):
            return request_transition("Player/Alive/Locomotion/Dash", {"command": command, "reason": "attack_cancel_dash"})
    return false

func _on_action_completed(action: GameAction) -> void:
    request_transition("Player/Alive/Locomotion/Idle", {"reason": "attack_finished"})

func _on_action_cancelled(action: GameAction, reason: String) -> void:
    pass
```

#### 函数使用场景
- **enter()**：进入状态时调用。实际例子：Player 进入 AttackState 时播放攻击动画并启动 TimedAttackAction。
- **exit()**：离开状态时调用。实际例子：DashState 退出时关闭无敌标记或清理移动输入。
- **handle_command()**：处理命令。实际例子：MoveState 收到 attack 命令时请求切到 BasicAttack 状态。
- **_on_action_completed()**：内部辅助函数。实际例子：由 **PlayerBasicAttackState** 的公开流程调用，用来完成 $fn 对应的子步骤；外部系统通常不应该直接调用它。
- **_on_action_cancelled()**：内部辅助函数。实际例子：由 **PlayerBasicAttackState** 的公开流程调用，用来完成 $fn 对应的子步骤；外部系统通常不应该直接调用它。

---

---

# 5. Action 系统接口设计

---

## 5.1 ActionContext

### 概念说明

- 是什么：Action 执行时携带的上下文。
- 负责什么：提供 owner、source、target、direction、position、payload 和 GameplayContext 等执行数据。
- 为什么需要：Action 应该复用在不同实体上，所以不能直接依赖某一个 Player 脚本。

`res://addons/mkit/kernel/context/action_context.gd`

```gdscript
class_name ActionContext
extends GameplayContext

var action_id: String = ""
var duration: float = 0.0
var elapsed: float = 0.0
var phase: String = ""

static func from_command(command: GameCommand, source_node: Node = null, target_node: Node = null) -> ActionContext:
    var ctx := ActionContext.new()
    ctx.source = source_node
    ctx.target = target_node
    ctx.payload = command.payload.duplicate(true)
    ctx.direction = command.get_vector2("direction", Vector2.ZERO)
    ctx.position = command.get_vector2("position", Vector2.ZERO)
    ctx.ability_id = command.get_string("ability_id", "")
    ctx.item_id = command.get_string("item_id", "")
    return ctx
```

#### 字段说明
- **action_id**：稳定 ID 字段。例：ActionContext 通过 action_id 引用某个定义或运行时对象，避免直接保存节点路径。
- **duration**：时间相关字段。例：控制持续时间、tick 间隔或动作阶段，便于暂停、调试和调参。
#### 函数使用场景
- **from_command()**：从命令构造上下文。实际例子：CastAbilityCommand 到达玩家后，用命令 payload 创建 GameplayContext 或 ActionContext。

---

### 27.16 ActionContext 使用示例

#### 详细实际用例

- 真实场景：`BasicAttackState` 创建 `ActionContext`，里面有 owner=玩家、direction=面朝方向、source=玩家。`TimedAttackAction` 用它决定 hitbox 朝哪里打开。
- 怎么使用：状态负责组装 Context，Action 只读 Context 执行时间过程，避免 Action 直接找玩家输入或 UI。
- 验证重点：同一个 DashAction 能用于玩家和敌人，只要传入不同 owner 和 direction。
```gdscript
var action_context := ActionContext.new()
action_context.source = player
action_context.target = enemy
action_context.direction = Vector2.RIGHT
action_context.duration = 0.25
action_context.payload["combo_index"] = 1
```

### 从 command 创建

```gdscript
var ctx := ActionContext.from_command(command, owner_entity, target_enemy)
ctx.duration = 0.3
```

---

---

---

## 5.2 GameAction

### 概念说明

- 是什么：一个随时间推进的玩法过程。
- 负责什么：表达攻击前摇/生效/后摇、Dash 持续时间、施法时间、延迟生成、等待动画等过程。
- 为什么需要：State 表示当前模式，Action 表示正在执行的时间过程，分开后行为更容易取消、调试和复用。

`res://addons/mkit/kernel/actions/game_action.gd`

```gdscript
class_name GameAction
extends RefCounted

signal completed(action: GameAction)
signal cancelled(action: GameAction, reason: String)

var action_id: String = ""
var context: ActionContext = null
var elapsed: float = 0.0
var finished: bool = false
var cancelled_flag: bool = false
var cancel_tags: Array[String] = []

func start(ctx: ActionContext) -> void:
    context = ctx
    elapsed = 0.0
    finished = false
    cancelled_flag = false
    _on_start()

func update(delta: float) -> void:
    if finished or cancelled_flag:
        return
    elapsed += delta
    _on_update(delta)

func cancel(reason: String = "") -> void:
    if finished or cancelled_flag:
        return
    cancelled_flag = true
    _on_cancel(reason)
    cancelled.emit(self, reason)

func complete() -> void:
    if finished or cancelled_flag:
        return
    finished = true
    _on_complete()
    completed.emit(self)

func is_finished() -> bool:
    return finished or cancelled_flag

func can_cancel_with(tag: String) -> bool:
    return cancel_tags.has(tag)

func _on_start() -> void:
    pass

func _on_update(delta: float) -> void:
    pass

func _on_cancel(reason: String) -> void:
    pass

func _on_complete() -> void:
    pass
```

#### 字段说明
- **action_id**：稳定 ID 字段。例：GameAction 通过 action_id 引用某个定义或运行时对象，避免直接保存节点路径。
#### 信号说明
- **completed**：当 **GameAction** 发生对应玩法事实时发出。实际例子：UI 或 FeedbackSystem 连接这个信号后刷新界面、播放音效或记录 Debug trace。
- **cancelled**：当 **GameAction** 发生对应玩法事实时发出。实际例子：UI 或 FeedbackSystem 连接这个信号后刷新界面、播放音效或记录 Debug trace。
#### 函数使用场景
- **start()**：启动流程。实际例子：RunDirector.start_run 创建 RunState 并进入第一个房间。
- **update()**：每帧逻辑更新。实际例子：StatusEffectController 每帧减少燃烧剩余时间。
- **cancel()**：取消流程。实际例子：玩家被眩晕时取消正在施法的 CastAction。
- **complete()**：完成当前流程。实际例子：Action 到达结束条件后调用，发出 completed 信号并让状态机进入下一状态。
- **is_finished()**：状态查询。实际例子：AI 调用 is_finished 判断目标是不是敌对阵营或 Action 是否结束。
- **can_cancel_with()**：合法性检查。实际例子：释放技能前先调用 can_cancel_with，失败时 UI 显示冷却中或目标太远。
- **_on_start()**：内部辅助函数。实际例子：由 **GameAction** 的公开流程调用，用来完成 $fn 对应的子步骤；外部系统通常不应该直接调用它。
- **_on_update()**：内部辅助函数。实际例子：由 **GameAction** 的公开流程调用，用来完成 $fn 对应的子步骤；外部系统通常不应该直接调用它。
- **_on_cancel()**：内部辅助函数。实际例子：由 **GameAction** 的公开流程调用，用来完成 $fn 对应的子步骤；外部系统通常不应该直接调用它。
- **_on_complete()**：内部辅助函数。实际例子：由 **GameAction** 的公开流程调用，用来完成 $fn 对应的子步骤；外部系统通常不应该直接调用它。

---

### 27.17 GameAction 使用示例

#### 详细实际用例

- 真实场景：玩家攻击不是瞬间发生，而是 0.1 秒前摇、0.15 秒有效帧、0.2 秒后摇。这个时间过程就是一个 `GameAction`。
- 怎么使用：State 启动 Action，Action 负责随时间推进并在完成/取消时发信号。Effect 只在 Action 的指定时机触发。
- 验证重点：被眩晕时 Action 能取消；暂停时 Action 不应继续推进；完成后状态能回到 Idle。
### 自定义 WaitThenPrintAction

```gdscript
class_name WaitThenPrintAction
extends GameAction

var duration: float = 1.0

func _on_start() -> void:
    print("Wait action started")

func _on_update(delta: float) -> void:
    if elapsed >= duration:
        complete()

func _on_complete() -> void:
    print("Wait action completed")
```

### 启动 Action

```gdscript
var action := WaitThenPrintAction.new()
var ctx := ActionContext.new()
ctx.source = player
ServiceRegistry.get_service("actions").start_action(action, ctx)
```

---

---

---

## 5.3 ActionRunner

### 概念说明

- 是什么：所有活动 Action 的更新器。
- 负责什么：启动、更新、取消、完成并清理 Action，同时提供信号和调试信息。
- 为什么需要：如果每个状态自己写 timer 和 update，后续取消、暂停、调试都会变得分散。

`res://addons/mkit/kernel/actions/action_runner.gd`

```gdscript
class_name ActionRunner
extends Node

signal action_started(action: GameAction)
signal action_completed(action: GameAction)
signal action_cancelled(action: GameAction, reason: String)

var active_actions: Array[GameAction] = []

func start_action(action: GameAction, context: ActionContext) -> GameAction:
    active_actions.append(action)
    action.completed.connect(_on_action_completed)
    action.cancelled.connect(_on_action_cancelled)
    action.start(context)
    action_started.emit(action)
    return action

func _process(delta: float) -> void:
    var time: TimeService = null
    if ServiceRegistry.has_service("time"):
        time = ServiceRegistry.get_service("time") as TimeService
    var scaled_delta := time.get_scaled_delta(delta) if time != null else delta
    for action in active_actions.duplicate():
        action.update(scaled_delta)
        if action.is_finished():
            active_actions.erase(action)

func cancel_actions_for_source(source: Node, reason: String = "") -> void:
    for action in active_actions.duplicate():
        if action.context != null and action.context.source == source:
            action.cancel(reason)

func _on_action_completed(action: GameAction) -> void:
    action_completed.emit(action)

func _on_action_cancelled(action: GameAction, reason: String) -> void:
    action_cancelled.emit(action, reason)
```

#### 信号说明
- **action_started**：当 **ActionRunner** 发生对应玩法事实时发出。实际例子：UI 或 FeedbackSystem 连接这个信号后刷新界面、播放音效或记录 Debug trace。
- **action_completed**：当 **ActionRunner** 发生对应玩法事实时发出。实际例子：UI 或 FeedbackSystem 连接这个信号后刷新界面、播放音效或记录 Debug trace。
- **action_cancelled**：当 **ActionRunner** 发生对应玩法事实时发出。实际例子：UI 或 FeedbackSystem 连接这个信号后刷新界面、播放音效或记录 Debug trace。
#### 函数使用场景
- **start_action()**：启动流程。实际例子：RunDirector.start_run 创建 RunState 并进入第一个房间。
- **_process()**：每帧推进 Action。实际例子：读取 TimeService 的 scaled delta，暂停时不推进攻击、施法和 Dash。
- **cancel_actions_for_source()**：取消流程。实际例子：玩家被眩晕时取消正在施法的 CastAction。
- **_on_action_completed()**：内部辅助函数。实际例子：由 **ActionRunner** 的公开流程调用，用来完成 $fn 对应的子步骤；外部系统通常不应该直接调用它。
- **_on_action_cancelled()**：内部辅助函数。实际例子：由 **ActionRunner** 的公开流程调用，用来完成 $fn 对应的子步骤；外部系统通常不应该直接调用它。

---

### 27.18 ActionRunner 使用示例

#### 详细实际用例

- 真实场景：场景里同时有玩家 DashAction、敌人 AttackAction、一个延迟爆炸 Action。ActionRunner 每帧统一更新它们。
- 怎么使用：把正在运行的 Action 注册到 runner，runner 负责 update、完成清理和取消，不要每个状态自己写计时器。
- 验证重点：多个 Action 同时运行时互不覆盖；取消一个 Action 不影响其他 Action。
```gdscript
func start_dash(player: Node, direction: Vector2) -> void:
    var action := DashAction.new()
    var ctx := ActionContext.new()
    ctx.source = player
    ctx.direction = direction

    var runner := ServiceRegistry.get_service("actions") as ActionRunner
    runner.start_action(action, ctx)
```

### 取消某个实体的所有 Action

```gdscript
func stun_entity(entity: Node) -> void:
    var runner := ServiceRegistry.get_service("actions") as ActionRunner
    runner.cancel_actions_for_source(entity, "stunned")
```

---

---

---

## 5.4 TimedAttackAction

### 概念说明

- 是什么：带前摇、生效和后摇窗口的攻击 Action。
- 负责什么：只在 active window 打开 hitbox，结束后通知状态机回到可行动状态。
- 为什么需要：动作 RPG 的近战攻击需要清晰的时间窗口，否则手感和判定都很难调。

### 功能

攻击分三段：startup、active、recovery。

```text
startup: 不能造成伤害
active: 打开 hitbox
recovery: 关闭 hitbox，等待恢复
```

### 文件

`res://addons/mkit/kernel/actions/builtin/timed_attack_action.gd`

```gdscript
class_name TimedAttackAction
extends GameAction

var startup_duration: float = 0.12
var active_duration: float = 0.10
var recovery_duration: float = 0.25
var hitbox_path: NodePath = NodePath("Components/HitboxEmitter")
var _hitbox_enabled: bool = false

func _on_start() -> void:
    action_id = "timed_attack"
    cancel_tags = ["dash", "stun", "death"]
    _play_animation("attack")
    _set_hitbox_enabled(false)

func _on_update(delta: float) -> void:
    var total_active_start := startup_duration
    var total_active_end := startup_duration + active_duration
    var total_end := startup_duration + active_duration + recovery_duration

    if elapsed >= total_active_start and elapsed < total_active_end:
        if not _hitbox_enabled:
            _set_hitbox_enabled(true)
    else:
        if _hitbox_enabled:
            _set_hitbox_enabled(false)

    if elapsed >= total_end:
        complete()

func _on_cancel(reason: String) -> void:
    _set_hitbox_enabled(false)

func _on_complete() -> void:
    _set_hitbox_enabled(false)

func _set_hitbox_enabled(enabled: bool) -> void:
    _hitbox_enabled = enabled
    if context == null or context.source == null:
        return
    var hitbox := context.source.get_node_or_null(hitbox_path) as HitboxComponent
    if hitbox != null:
        hitbox.set_active(enabled)

func _play_animation(name: String) -> void:
    if context == null or context.source == null:
        return
    var anim := context.source.get_node_or_null("Presentation/AnimationPlayer") as AnimationPlayer
    if anim != null:
        anim.play(name)
```

#### 字段说明
- **startup_duration**：时间相关字段。例：控制持续时间、tick 间隔或动作阶段，便于暂停、调试和调参。
- **active_duration**：时间相关字段。例：控制持续时间、tick 间隔或动作阶段，便于暂停、调试和调参。
- **recovery_duration**：时间相关字段。例：控制持续时间、tick 间隔或动作阶段，便于暂停、调试和调参。
- **hitbox_path**：资源或节点路径。例：用 hitbox_path 指向场景或节点，方便在 Inspector 中配置。
#### 函数使用场景
- **_on_start()**：内部辅助函数。实际例子：由 **TimedAttackAction** 的公开流程调用，用来完成 $fn 对应的子步骤；外部系统通常不应该直接调用它。
- **_on_update()**：内部辅助函数。实际例子：由 **TimedAttackAction** 的公开流程调用，用来完成 $fn 对应的子步骤；外部系统通常不应该直接调用它。
- **_on_cancel()**：内部辅助函数。实际例子：由 **TimedAttackAction** 的公开流程调用，用来完成 $fn 对应的子步骤；外部系统通常不应该直接调用它。
- **_on_complete()**：内部辅助函数。实际例子：由 **TimedAttackAction** 的公开流程调用，用来完成 $fn 对应的子步骤；外部系统通常不应该直接调用它。
- **_set_hitbox_enabled()**：内部辅助函数。实际例子：由 **TimedAttackAction** 的公开流程调用，用来完成 $fn 对应的子步骤；外部系统通常不应该直接调用它。
- **_play_animation()**：内部辅助函数。实际例子：由 **TimedAttackAction** 的公开流程调用，用来完成 $fn 对应的子步骤；外部系统通常不应该直接调用它。

---

### 27.19 TimedAttackAction 使用示例

#### 详细实际用例

- 真实场景：玩家挥剑时，前摇阶段不能打中敌人，active 阶段打开剑的 Hitbox，后摇阶段关闭 Hitbox 但角色还不能立刻移动。
- 怎么使用：配置 startup/active/recovery 时间，active 开始时启用 hitbox，active 结束时关闭 hitbox，recovery 完成后发 completed。
- 验证重点：敌人只在 active window 内被命中；挥剑动画和 hitbox 时机一致。
```gdscript
func start_basic_attack(player: Node) -> void:
    var action := TimedAttackAction.new()
    action.startup_duration = 0.12
    action.active_duration = 0.08
    action.recovery_duration = 0.25
    action.hitbox_path = NodePath("Components/HitboxComponent")

    var ctx := ActionContext.new()
    ctx.source = player
    ctx.direction = Vector2.RIGHT

    var runner := ServiceRegistry.get_service("actions") as ActionRunner
    runner.start_action(action, ctx)
```

---

---

---

## 5.5 DashAction

### 概念说明

- 是什么：短时间位移爆发 Action。
- 负责什么：按方向和速度推动实体一小段时间，并在结束或取消时释放控制权。
- 为什么需要：Dash 在动作 roguelike 中很常见，应该作为复用 Action，而不是写死在 PlayerMovement 里。

```gdscript
class_name DashAction
extends GameAction

var duration: float = 0.18
var speed: float = 480.0
var direction: Vector2 = Vector2.ZERO

func _on_start() -> void:
    action_id = "dash"
    cancel_tags = ["stun", "death"]
    direction = context.direction.normalized()
    if direction == Vector2.ZERO:
        direction = Vector2.RIGHT

func _on_update(delta: float) -> void:
    if context.source == null:
        complete()
        return

    var body := context.source as CharacterBody2D
    if body != null:
        body.velocity = direction * speed
        body.move_and_slide()

    if elapsed >= duration:
        complete()

func _on_complete() -> void:
    if context.source is CharacterBody2D:
        context.source.velocity = Vector2.ZERO
```

#### 字段说明
- **duration**：时间相关字段。例：控制持续时间、tick 间隔或动作阶段，便于暂停、调试和调参。
- **direction**：方向。例：玩家按右方向释放火球，direction=Vector2.RIGHT。
#### 函数使用场景
- **_on_start()**：内部辅助函数。实际例子：由 **DashAction** 的公开流程调用，用来完成 $fn 对应的子步骤；外部系统通常不应该直接调用它。
- **_on_update()**：内部辅助函数。实际例子：由 **DashAction** 的公开流程调用，用来完成 $fn 对应的子步骤；外部系统通常不应该直接调用它。
- **_on_complete()**：内部辅助函数。实际例子：由 **DashAction** 的公开流程调用，用来完成 $fn 对应的子步骤；外部系统通常不应该直接调用它。

---

---

### 27.20 DashAction 使用示例

#### 详细实际用例

- 真实场景：玩家按闪避键后向当前方向冲刺 0.2 秒，期间可能无敌，结束后回到移动状态。
- 怎么使用：DashState 创建 DashAction 并传入 direction/speed/duration；Action 推动 owner 的位置或 velocity。
- 验证重点：Dash 期间输入不会让角色突然转向；撞墙、取消、冷却和无敌帧都有明确行为。
```gdscript
func handle_dash_command(command: GameCommand) -> void:
    var dash := DashAction.new()
    dash.duration = 0.18
    dash.speed = 520.0

    var ctx := ActionContext.from_command(command, owner_entity, null)
    ctx.source = owner_entity

    ServiceRegistry.get_service("actions").start_action(dash, ctx)
```

---

---

---

## 5.6 CastAction

### 概念说明

- 是什么：带施法时间、可取消和完成回调的 Action。
- 负责什么：推进 cast_time，期间播放施法表现，完成后通知 AbilityController 执行效果。
- 为什么需要：AbilityController 已经支持 `cast_time`，但没有 CastAction 时，读条、打断、暂停和完成顺序都没有统一落点。

`res://addons/mkit/kernel/actions/builtin/cast_action.gd`

```gdscript
class_name CastAction
extends GameAction

var duration: float = 0.0
var animation_name: String = "cast"
var _started_animation: bool = false

func _on_start() -> void:
    action_id = "cast"
    cancel_tags = ["stun", "death", "silence"]
    context.duration = duration
    _play_animation()

func _on_update(delta: float) -> void:
    if context == null or context.source == null:
        cancel("missing_source")
        return
    context.elapsed = elapsed
    if elapsed >= duration:
        complete()

func _on_cancel(reason: String) -> void:
    _stop_cast_feedback()

func _on_complete() -> void:
    _stop_cast_feedback()

func _play_animation() -> void:
    if _started_animation or context == null or context.source == null:
        return
    var anim := context.source.get_node_or_null("Presentation/AnimationPlayer") as AnimationPlayer
    if anim != null and animation_name != "":
        anim.play(animation_name)
    _started_animation = true

func _stop_cast_feedback() -> void:
    if context == null or context.source == null:
        return
    if "on_cast_action_finished" in context.source:
        context.source.on_cast_action_finished(self)
```

#### 字段说明
- **duration**：施法时间。例：火球 cast_time=0.35，期间被眩晕会取消。
- **animation_name**：施法动画名。例：法师播放 cast 动画直到 Action 完成或取消。
#### 函数使用场景
- **_on_start()**：启动施法。实际例子：AbilityController 创建 CastAction 后开始读条。
- **_on_update()**：推进施法时间。实际例子：elapsed 到达 duration 后 complete。
- **_on_cancel()**：取消施法。实际例子：被 stun 打断时停止施法反馈且不执行效果。
- **_on_complete()**：完成施法。实际例子：AbilityController 监听 completed 后执行 ability effects。
- **_play_animation()**：内部播放动画。实际例子：进入施法后播放 Presentation/AnimationPlayer 的 cast。
- **_stop_cast_feedback()**：内部停止反馈。实际例子：读条 UI 或角色脚本收到结束通知后隐藏施法条。

---

### 27.90 CastAction 使用示例

#### 详细实际用例

- 真实场景：玩家释放火球需要 0.35 秒。CastAction 开始后播放施法动画；如果期间被眩晕，ActionRunner 取消该 source 的 action，AbilityController 不执行火球效果，也不进入完整释放流程。
- 怎么使用：AbilityController 只负责创建并监听 CastAction；Action 本身不直接扣 mana、不生成投射物，也不决定技能效果。
- 验证重点：施法完成才执行 effects；取消施法不会执行 effects；暂停时施法进度不推进。

```gdscript
var action := CastAction.new()
action.duration = fireball_definition.cast_time
action.completed.connect(func(_action):
    _execute_ability_effects(fireball_definition, ctx)
)

var action_context := ActionContext.new()
action_context.source = player
action_context.ability_id = "ability.fireball_basic"
ServiceRegistry.get_service("actions").start_action(action, action_context)
```

---

