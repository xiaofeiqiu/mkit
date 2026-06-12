# Recipe 02：玩家实体 + StateMachine + 输入命令  ·  难度 ★★☆  ·  预计 30 分钟

## 本篇结束后，你的项目新增了什么

玩家实体出现在场景中。按 WASD 发出 `move` 命令，玩家进入 Move 状态并移动；松开 WASD 发出 `stop_move` 命令，返回 Idle 状态。控制台打印状态切换日志。

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
| 挂 `CommandReceiver`，按需设置 `receiver_id` | 接收命令并交给 `StateMachine`；按 id 路由时可自动注册到 `CommandService` |
| 发出 `GameCommand` → `CommandReceiver.receive_command` | 将命令交给同实体状态机入口 |

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

var _receiver: CommandReceiver = null
var _was_moving: bool = false


func _ready() -> void:
    _receiver = EntityContract.get_command_receiver(self)


func _process(_delta: float) -> void:
    if _receiver == null:
        _receiver = EntityContract.get_command_receiver(self)
    if _receiver == null:
        return
    var dir := Vector2.ZERO
    if Input.is_key_pressed(KEY_A):
        dir.x -= 1.0
    if Input.is_key_pressed(KEY_D):
        dir.x += 1.0
    if Input.is_key_pressed(KEY_W):
        dir.y -= 1.0
    if Input.is_key_pressed(KEY_S):
        dir.y += 1.0
    if dir != Vector2.ZERO:
        var cmd := GameCommand.create(BuiltinCommands.MOVE, "player", "player", {"direction": dir})
        _receiver.receive_command(cmd)
        _was_moving = true
    elif _was_moving:
        var cmd := GameCommand.create(BuiltinCommands.STOP_MOVE, "player", "player")
        _receiver.receive_command(cmd)
        _was_moving = false
```

将 `PlayerInputController` 挂到主场景或玩家实体的子节点。

### 步骤 5：将玩家实体加入游戏场景

在 Bootstrap 的 `initial_scene_path` 指向的游戏场景中，实例化玩家实体，放置在可见位置。

## 运行验证

按 F5 运行，按 WASD：

- 玩家节点应移动（Move 状态的 `move_and_slide` 生效）
- 松开 WASD 后停止移动
- 在 Remote 调试器 → Nodes 面板，可看到 `StateMachine` 内当前叶状态

在 `PlayerIdleState.enter` 或 `PlayerMoveState.enter` 添加 `print` 可确认状态切换：

```gdscript
func enter(context: Dictionary = {}) -> void:
    print("Enter Idle")
```

## 字段参考

### EntityIdentity

| 字段 | 类型/默认 | 含义 | 什么时候改 |
|------|----------|------|-----------|
| `entity_id` | String | 运行时实体 id；存档、命令路由、事件归因都用它定位实体。留空时自动生成唯一 id | 长期实体（玩家、Boss）填稳定值（见步骤 1）；一次性小怪可留空 |
| `definition_id` | String = "" | 绑定的 `EntityDefinition` id；由 `EntitySpawner` spawn 时自动写入（[Recipe 07](07_room.md)），任务"击杀某种敌人"按它匹配 | 手摆的实体想参与定义匹配时手填 |
| `display_name` | String = "" | UI 显示名，不参与路由 | 需要在 UI 上显示实体名时 |
| `faction` | String = "neutral" | 阵营标识；`HitboxComponent.target_factions` 过滤、AI 敌友判断都读它 | 玩家 `"player"`、敌人 `"enemy"`（[Recipe 04](04_attack_action.md)）|
| `tags` | Array[String] = [] | 标签集合，供条件筛选、事件追踪、UI 分组 | 自定义 Condition / 查询要按标签过滤时 |

### StateMachine

| 字段 | 类型/默认 | 含义 | 什么时候改 |
|------|----------|------|-----------|
| `initial_state_path` | String = "" | 启动时进入的状态路径（`"Root/Idle"` 格式，按 `state_id` 用 `/` 拼接）；留空进第一个子状态 | 见步骤 1 |
| `auto_start` | bool = true | 进入场景树后是否自动启动；关掉后状态机保持未启动，需手动调 `start()` | 进入初始状态前有前置流程时（如等出生动画播完再 `state_machine.start()`）|

### State

| 字段 | 类型/默认 | 含义 | 什么时候改 |
|------|----------|------|-----------|
| `state_id` | String = "" | StateMachine 内引用该状态的 id，transition 路径由它拼成；同级状态必须唯一 | 必填（见步骤 1）|
| `initial_child_state_id` | String = "" | HFSM 复合状态：transition 只到达本状态（如 `"Root/Combat"`）时，默认进入的子状态 id；留空则停在本状态不下钻 | 复合状态有多个子状态、想要默认入口时（如 Combat 默认进 `"Approach"`）|

### CommandReceiver

| 字段 | 类型/默认 | 含义 | 什么时候改 |
|------|----------|------|-----------|
| `receiver_id` | String = "" | `CommandService.dispatch(target_id, ...)` 按它路由命令；留空时 `_ready` 自动取 `EntityIdentity.entity_id` | 跨实体按 id 发命令（AI 指挥单位、剧情控制 NPC）且想用别名时显式填 |
| `auto_register` | bool = true | 进入场景树时是否自动注册到 `CommandService`；关掉后该实体收不到按 id 路由的命令，只能直接调 `receive_command()` | 临时实体不想占用全局 id 注册表时关掉 |

## 常见错误

| 现象 | 原因 | 修复 |
|------|------|------|
| 命令发出但状态没切换 | `CommandReceiver` 缺失，或 `State.handle_command` 未处理该类型 | 确认实体有 `CommandReceiver`，并检查当前 State 的 `handle_command` |
| `CommandService.dispatch` 返回 `false`（仅按 id 路由时） | `target_id` 为空或 `CommandReceiver` 未注册到 `CommandService` | 检查 `receiver_id` / `auto_register`，且 Bootstrap 先于玩家场景运行 |
| 玩家不移动 | `CharacterBody2D` 未调 `move_and_slide()` | 在 `update()` 中调用 `body.move_and_slide()` |
| `StateMachine` 找不到初始状态 | `initial_state_path` 路径拼错 | 路径格式为 `"Root/Idle"`（与节点 `state_id` 一致，用 `/` 分隔）|
| `handle_command` 返回 true 但没跳转 | `request_transition` 的路径不存在 | 确认目标 State 节点存在且 `state_id` 正确 |

## 延伸阅读

- [StateMachine ref](../generated/html/classes/StateMachine.html) — transition 路由、can_enter/can_exit、blackboard
- [State ref](../generated/html/classes/State.html) — 所有可 override 的方法
- [GameCommand ref](../generated/html/classes/GameCommand.html) — 创建命令、payload 读取
- [CommandService ref](../generated/html/classes/CommandService.html) — 按 id dispatch、注册/注销
- [pipeline.md — Command Dispatch](../pipeline.md#3-command-dispatch) — 命令分发完整时序图
- [pipeline.md — HFSM Transition](../pipeline.md#4-hfsm-transition) — 状态切换时序
