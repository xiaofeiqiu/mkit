# State

**层：** Kernel  
**文件：** `addons/mkit/kernel/state_machine/state.gd`  
**继承：** `extends Node`

## 职责

HFSM（层级有限状态机）的节点单元。挂在 `StateMachine` 节点树下，实现游戏逻辑的状态分支。命令从叶状态向上冒泡，第一个返回 `true` 的 State 消费该命令。

## 字段（@export 和 public var）

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `state_id` | `String` | `""` | 状态唯一标识（在同父级下唯一即可）|
| `initial_child_state_id` | `String` | `""` | 进入此状态时自动进入的子状态 ID |
| `parent_state` | `State` | `null` | 父状态，由 `StateMachine.setup` 注入 |
| `state_machine` | `StateMachine` | `null` | 所属状态机，由 `setup` 注入 |
| `owner_entity` | `Node` | `null` | 携带此状态机的实体节点 |
| `active_child` | `State` | `null` | 当前活跃的子状态（用于层级路由）|
| `blackboard` | `Blackboard` | `null` | 与状态机共享的黑板，由 `setup` 注入 |

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `enter(context: Dictionary = {}) -> void` | `void` | **override**：进入此状态时调用（父先子后）|
| `exit(context: Dictionary = {}) -> void` | `void` | **override**：离开此状态时调用（子先父后）|
| `update(delta: float) -> void` | `void` | **override**：每帧逻辑（由 StateMachine._process 调用）|
| `physics_update(delta: float) -> void` | `void` | **override**：物理帧逻辑 |
| `handle_command(command: GameCommand) -> bool` | `bool` | **override**：处理命令；返回 true 消费命令，false 继续向上冒泡 |
| `can_enter(context: Dictionary = {}) -> bool` | `bool` | **override**：返回 false 时阻止进入此状态（默认 true）|
| `can_exit(context: Dictionary = {}) -> bool` | `bool` | **override**：返回 false 时阻止离开此状态（默认 true）|
| `request_transition(target_path: String, context: Dictionary = {}) -> bool` | `bool` | 请求状态机跳转；`target_path` 格式为 `"Root/Idle"` |
| `get_full_path() -> String` | `String` | 返回此状态的完整路径如 `"Root/Combat/Attack"` |

## 使用模式

### 最小示例（Level 1）

```gdscript
class_name IdleState
extends State

func handle_command(command: GameCommand) -> bool:
    if command.command_type == BuiltinCommands.MOVE:
        return request_transition("Root/Move", {"direction": command.get_vector2("direction")})
    return false
```

### 典型场景（Level 2）

```gdscript
# 带进入/退出、条件保护、黑板写入的完整状态
class_name CombatState
extends State

var _action_svc: ActionService = null
var _current_action: GameAction = null


func _ready() -> void:
    _action_svc = ServiceRegistry.get_port(ServiceRegistry.SERVICE_ACTIONS) as ActionService


func can_enter(_context: Dictionary = {}) -> bool:
    # 死亡时无法进入战斗状态
    var health := EntityContract.get_component(owner_entity, "HealthComponent") as HealthComponent
    return health != null and not health.dead


func enter(context: Dictionary = {}) -> void:
    blackboard.set_value("in_combat", true)
    _start_attack_action()


func exit(_context: Dictionary = {}) -> void:
    blackboard.set_value("in_combat", false)
    if _current_action != null and not _current_action.is_finished():
        _current_action.cancel("state_exit")
    _current_action = null


func handle_command(command: GameCommand) -> bool:
    match command.command_type:
        BuiltinCommands.STOP_MOVE:
            return request_transition("Root/Idle")
        "die":
            return request_transition("Root/Dead")
    return false


func _start_attack_action() -> void:
    if _action_svc == null:
        return
    var attack := TimedAttackAction.new()
    attack.startup_duration  = 0.12
    attack.active_duration   = 0.10
    attack.recovery_duration = 0.25

    var ctx := ActionContext.new()
    ctx.source = owner_entity
    ctx.target = blackboard.get_value("target", null) as Node

    _current_action = _action_svc.start_action(attack, ctx)
    if _current_action != null:
        _current_action.completed.connect(func(_a): request_transition("Root/Idle"))
```

## 相关

- → [StateMachine](StateMachine.md) — 管理所有 State，处理 transition
- → [Blackboard](Blackboard.md) — 状态间共享数据
- → [GameCommand](GameCommand.md) — handle_command 的参数
- → [pipeline.md — HFSM Transition](../../pipeline.md#4-hfsm-transition)
- → [cookbook/02_player_entity.md](../../cookbook/02_player_entity.md)
