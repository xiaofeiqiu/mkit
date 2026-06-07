# Recipe 02：玩家实体 + StateMachine + 输入命令  ·  难度 ★★☆  ·  预计 30 分钟

## 本篇结束后，你的项目新增了什么

玩家实体出现在场景中。按方向键发出 `move` 命令，玩家进入 Move 状态并移动；松开方向键发出 `stop_move` 命令，返回 Idle 状态。控制台打印状态切换日志。

## 前置

- 需完成：[Recipe 01](01_bootstrap.md)（Bootstrap 场景已跑通）
- 用到的概念：[concepts.md — 模型 1：标准管线](../concepts.md#模型-1标准管线时序图)

## 你负责 / mkit 负责

| 你写的 | mkit 处理的 |
|--------|------------|
| EntityRoot 场景树（默认布局） | `EntityContract` / `EntityRoot.get_component()` / `get_controller()` 语义入口 |
| `EntityIdentity` 设 `entity_id` | 自动生成唯一 ID（若留空）|
| 继承 `State`，实现 `handle_command` / `enter` / `exit` / `update` | HFSM 层级路由、LCA transition |
| 在 `StateMachine` 上设 `initial_state_path` | 自动在 `_ready` 时进入初始状态 |
| 在 `CommandReceiver` 上设 `receiver_id` | 自动注册到 `CommandService` |
| 发出 `GameCommand` → `CommandService.dispatch` | 路由命令到对应 `CommandReceiver` |

## 步骤

### 步骤 1：构建玩家实体场景树

新建场景，根节点选 `EntityRoot`（或使用 CharacterBody2D 并附加 EntityRoot 脚本）。

**默认布局（模块通过 `EntityContract` 语义入口访问，布局仍应保持一致）：**

```
PlayerEntity  (EntityRoot / CharacterBody2D)
├── EntityIdentity        # export entity_id = "player"
├── StateMachine          # export initial_state_path = "Root/Idle"
│   └── Root  (State)     # export state_id = "Root"
│       ├── Idle  (State) # export state_id = "Idle"
│       └── Move  (State) # export state_id = "Move"
├── CommandReceiver       # export receiver_id = "player", auto_register = true
├── Components/           # Node，暂时空着（Recipe 03 添加组件）
├── Controllers/          # Node，暂时空着
└── Presentation/         # Node，暂时空着（Recipe 13 添加动画）
```

> `CommandReceiver` 在 `_ready` 时自动从 `EntityIdentity.entity_id` 读取 `receiver_id`（若留空），并向 `CommandService` 注册自身。

### 步骤 2：实现 Idle 状态

```gdscript
# res://game/player/states/player_idle_state.gd
class_name PlayerIdleState
extends State

func enter(_context: Dictionary = {}) -> void:
    if owner_entity is CharacterBody2D:
        (owner_entity as CharacterBody2D).velocity = Vector2.ZERO

func handle_command(command: GameCommand) -> bool:
    if command.command_type == BuiltinCommands.MOVE:
        return request_transition("Root/Move", {"direction": command.get_vector2("direction")})
    return false
```

### 步骤 3：实现 Move 状态

```gdscript
# res://game/player/states/player_move_state.gd
class_name PlayerMoveState
extends State

var _direction: Vector2 = Vector2.ZERO

func enter(context: Dictionary = {}) -> void:
    _direction = context.get("direction", Vector2.ZERO)

func update(_delta: float) -> void:
    var body := owner_entity as CharacterBody2D
    if body == null:
        return
    body.velocity = _direction * 160.0
    body.move_and_slide()

func handle_command(command: GameCommand) -> bool:
    match command.command_type:
        BuiltinCommands.MOVE:
            _direction = command.get_vector2("direction")
            return true
        BuiltinCommands.STOP_MOVE:
            return request_transition("Root/Idle")
    return false
```

### 步骤 4：发出输入命令

在主场景或玩家 Controller 脚本中处理输入，发出 `GameCommand`：

```gdscript
# res://game/player/player_input_controller.gd
extends Node

var _commands: CommandService = null


func _ready() -> void:
    _commands = ServiceRegistry.get_port(ServiceRegistry.SERVICE_COMMANDS) as CommandService


func _process(_delta: float) -> void:
    if _commands == null:
        return
    var dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
    if dir != Vector2.ZERO:
        var cmd := GameCommand.create(BuiltinCommands.MOVE, "player", "player", {"direction": dir})
        _commands.dispatch(cmd)
    elif Input.is_action_just_released("ui_left") or Input.is_action_just_released("ui_right") \
            or Input.is_action_just_released("ui_up") or Input.is_action_just_released("ui_down"):
        var cmd := GameCommand.create(BuiltinCommands.STOP_MOVE, "player", "player")
        _commands.dispatch(cmd)
```

将 `PlayerInputController` 挂到主场景或玩家实体的子节点。

### 步骤 5：将玩家实体加入游戏场景

在 Bootstrap 的 `initial_scene_path` 指向的游戏场景中，实例化玩家实体，放置在可见位置。

## 运行验证

按 F5 运行，按方向键：

- 玩家节点应移动（Move 状态的 `move_and_slide` 生效）
- 松开所有方向键后停止移动
- 在 Remote 调试器 → Nodes 面板，可看到 `StateMachine` 内当前叶状态

在 `PlayerIdleState.enter` 或 `PlayerMoveState.enter` 添加 `print` 可确认状态切换：

```gdscript
func enter(context: Dictionary = {}) -> void:
    print("Enter Idle")
```

## 常见错误

| 现象 | 原因 | 修复 |
|------|------|------|
| 命令发出但状态没切换 | `CommandReceiver.receiver_id` 与命令的 `target_id` 不匹配 | 确认两者均为 `"player"` |
| `CommandService.dispatch` 返回 `false` | `CommandReceiver` 未注册到 `CommandService` | 检查 `auto_register = true`，且 Bootstrap 先于玩家场景运行 |
| 玩家不移动 | `CharacterBody2D` 未调 `move_and_slide()` | 在 `update()` 中调用 `body.move_and_slide()` |
| `StateMachine` 找不到初始状态 | `initial_state_path` 路径拼错 | 路径格式为 `"Root/Idle"`（与节点 `state_id` 一致，用 `/` 分隔）|
| `handle_command` 返回 true 但没跳转 | `request_transition` 的路径不存在 | 确认目标 State 节点存在且 `state_id` 正确 |

## 延伸阅读

- [StateMachine ref](../ref/kernel/StateMachine.md) — transition 路由、can_enter/can_exit、blackboard
- [State ref](../ref/kernel/State.md) — 所有可 override 的方法
- [GameCommand ref](../ref/kernel/GameCommand.md) — 创建命令、payload 读取
- [CommandService ref](../ref/kernel/CommandService.md) — dispatch、broadcast、注册/注销
- [pipeline.md — Command Dispatch](../pipeline.md#3-command-dispatch) — 命令分发完整时序图
- [pipeline.md — HFSM Transition](../pipeline.md#4-hfsm-transition) — 状态切换时序
