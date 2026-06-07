# Recipe 06：敌人实体 + AI Brain  ·  难度 ★★★  ·  预计 25 分钟

## 本篇结束后，你的项目新增了什么

敌人实体出现在场景中，携带 `SimpleAIEnemyBrain`。Brain 每 0.2s 决策一次：距离玩家 > `detection_range` 时 Idle；在范围内追击（Move）；进入 `attack_range` 后发出 `attack` 命令攻击玩家。玩家血量随敌人攻击减少。

## 前置

- 需完成：[Recipe 04](04_attack_action.md)（HurtboxComponent 挂在玩家身上）
- 用到的概念：[concepts.md — 模型 5：扩展点地图](../concepts.md#模型-5扩展点地图你写什么--mkit-管什么)（Brain 行）

## 你负责 / mkit 负责

| 你写的 | mkit 处理的 |
|--------|------------|
| 构建敌人实体场景树（与玩家同样的 EntityRoot 布局）| — |
| 添加 `SimpleAIEnemyBrain` 并配置 `detection_range` / `attack_range` | 每 `think_interval` 调用 `think()`，根据距离发 MOVE / ATTACK / STOP 命令 |
| 在敌人 StateMachine 中实现 Idle / Move / Attack 状态 | — |
| 实现敌人 Attack 状态（类似玩家，使用 `TimedAttackAction`）| — |
| 可选：继承 `Brain` 实现自定义决策逻辑 | `think()` 每帧由 `Brain._process` 按间隔调用 |

## 步骤

### 步骤 1：构建敌人场景树

新建场景，与玩家实体完全相同的布局：

```
EnemyEntity  (EntityRoot)
├── EntityIdentity        # faction = "enemy", tags = ["enemy"]
├── StateMachine          # initial_state_path = "Root/Idle"
│   └── Root  (State)     # state_id = "Root"
│       ├── Idle  (State)
│       ├── Move  (State)
│       └── Attack (State)
├── CommandReceiver       # receiver_id 留空（从 EntityIdentity.entity_id 自动填充）
├── Components/
│   ├── StatsComponent    # max_hp=60, attack_power=8, defense=0
│   ├── HealthComponent   # current_hp=60, destroy_on_death=true
│   └── HurtboxComponent  # team="enemy"
├── Controllers/
│   └── SimpleAIEnemyBrain   # ← 新增
└── Presentation/
```

**HurtboxComponent** 让敌人可以被玩家攻击命中。

### 步骤 2：配置 SimpleAIEnemyBrain

`SimpleAIEnemyBrain` 是内置类，直接附加到 `Controllers/SimpleAIEnemyBrain` 节点：

- `detection_range` = `240.0`（像素）
- `attack_range` = `48.0`
- `target_group` = `"player"`（通过 `get_first_node_in_group("player")` 找玩家）
- `think_interval` = `0.2`（每 0.2 秒决策一次）

`SimpleAIEnemyBrain` 内部逻辑：
- 距离 > detection_range → `STOP_MOVE`
- 距离 ≤ detection_range 且 > attack_range → `MOVE`（方向朝向玩家）
- 距离 ≤ attack_range → `ATTACK`

命令发给**自身**（`target_id = self.entity_id`），由敌人自己的 `CommandReceiver` 接收。

### 步骤 3：实现敌人状态

敌人的 Idle / Move 状态与玩家完全相同（可复用或各自实现）：

```gdscript
# res://game/enemy/states/enemy_idle_state.gd
class_name EnemyIdleState
extends State

func enter(_context: Dictionary = {}) -> void:
    var body := owner_entity as CharacterBody2D
    if body != null:
        body.velocity = Vector2.ZERO

func handle_command(command: GameCommand) -> bool:
    match command.command_type:
        BuiltinCommands.MOVE:
            return request_transition("Root/Move", {"direction": command.get_vector2("direction")})
        BuiltinCommands.ATTACK:
            return request_transition("Root/Attack")
    return false
```

```gdscript
# res://game/enemy/states/enemy_move_state.gd
class_name EnemyMoveState
extends State

var _direction: Vector2 = Vector2.ZERO

func enter(context: Dictionary = {}) -> void:
    _direction = context.get("direction", Vector2.ZERO)

func update(_delta: float) -> void:
    var body := owner_entity as CharacterBody2D
    if body == null:
        return
    var speed := 80.0  # 敌人移速较慢
    body.velocity = _direction * speed
    body.move_and_slide()

func handle_command(command: GameCommand) -> bool:
    match command.command_type:
        BuiltinCommands.MOVE:
            _direction = command.get_vector2("direction")
            return true
        BuiltinCommands.STOP_MOVE:
            return request_transition("Root/Idle")
        BuiltinCommands.ATTACK:
            return request_transition("Root/Attack")
    return false
```

**敌人 Attack 状态**（与玩家相似，但 target 是玩家）：

```gdscript
# res://game/enemy/states/enemy_attack_state.gd
class_name EnemyAttackState
extends State

var _action_svc: ActionService = null
var _current_action: GameAction = null


func _ready() -> void:
    _action_svc = ServiceRegistry.get_port(ServiceRegistry.SERVICE_ACTIONS) as ActionService


func enter(_context: Dictionary = {}) -> void:
    var attack := TimedAttackAction.new()
    attack.startup_duration = 0.15
    attack.active_duration  = 0.12
    attack.recovery_duration = 0.35
    attack.hitbox_path = NodePath("Components/HitboxComponent")

    var dmg := DealDamageEffect.new()
    dmg.effect_id = "enemy_melee_hit"
    dmg.base_amount = 8.0
    dmg.damage_type = "physical"
    attack.on_complete_effects = [dmg]

    var ctx := ActionContext.new()
    ctx.source = owner_entity
    ctx.target = get_tree().get_first_node_in_group("player")

    _current_action = _action_svc.start_action(attack, ctx)
    if _current_action != null:
        _current_action.completed.connect(func(_a): request_transition("Root/Idle"))
        _current_action.cancelled.connect(func(_a, _r): request_transition("Root/Idle"))


func exit(_context: Dictionary = {}) -> void:
    if _current_action != null and not _current_action.is_finished():
        _current_action.cancel("state_exit")
    _current_action = null
```

> 如果敌人没有 HitboxComponent，`TimedAttackAction` 内的 `_set_hitbox_enabled` 会找不到节点并静默跳过。攻击仍然在 `complete()` 时通过 `on_complete_effects` 直接对 `ctx.target` 造成伤害（target 是硬编码的玩家节点），不依赖物理碰撞。

### 步骤 4：将敌人实体加入游戏场景

实例化敌人场景，放在玩家可见范围内。确认 `EntityIdentity.faction = "enemy"` 且未加入 `"player"` group。

### 步骤 5：（可选）实现自定义 Brain

若需要更复杂的 AI 行为（巡逻、技能轮转、多目标）：

```gdscript
# res://game/enemy/my_boss_brain.gd
class_name MyBossBrain
extends Brain

@export var skill_ability_id: String = "boss_shockwave"


func think() -> void:
    var player := _get_player()
    if player == null:
        return
    var distance := (owner as Node2D).global_position.distance_to((player as Node2D).global_position)

    if distance <= 80.0:
        # 近身时随机使用技能或普攻
        var roll := randf()
        if roll < 0.3:
            issue_command(BuiltinCommands.CAST_ABILITY, {"ability_id": skill_ability_id})
        else:
            issue_command(BuiltinCommands.ATTACK)
    elif distance <= detection_range:
        var dir := ((player as Node2D).global_position - (owner as Node2D).global_position).normalized()
        issue_command(BuiltinCommands.MOVE, {"direction": dir})
    else:
        issue_command(BuiltinCommands.STOP_MOVE)


func _get_player() -> Node:
    return get_tree().get_first_node_in_group("player")
```

## 运行验证

1. 运行场景，敌人实体出现
2. 玩家靠近敌人到 `detection_range` 以内：敌人开始移动追击
3. 进入 `attack_range`：敌人进入 Attack 状态，`damage_applied` 事件触发
4. 玩家血量减少（在 Remote 面板查看 `HealthComponent.current_hp`）
5. 玩家 HP 归零：`entity_died` 触发

在 `SimpleAIEnemyBrain.think()` 中添加 `print` 确认决策流程：
```gdscript
print("Brain: intent=%s dist=%.1f" % [blackboard.get_value("intent", "?"), distance])
```

## 常见错误

| 现象 | 原因 | 修复 |
|------|------|------|
| 敌人不动 | Brain 无法找到玩家 | 确认玩家节点已加入 `"player"` group（Scene → Groups）|
| 命令发出但敌人状态不切换 | `CommandReceiver.receiver_id` 未正确初始化 | 检查 `EntityIdentity.entity_id` 非空；`auto_register = true` |
| 敌人攻击但玩家不掉血 | `ctx.target` 不是带 HealthComponent 的节点 | 确认 `get_first_node_in_group("player")` 返回的是 EntityRoot 节点 |
| `think_interval` 为 0 → 卡死 | `Brain._process` 每帧都调 `think()` | 保持 `think_interval > 0`（默认 0.2 即可）|
| 敌人追到玩家但超出 attack_range 时没切回 Move | 状态机处于 Attack 中，Brain 发的 MOVE 命令未被 Attack 状态处理 | 在 `EnemyAttackState.handle_command` 中处理 MOVE 命令，或 action complete 后自动回 Idle |

## 延伸阅读

- [Brain ref](../ref/modules/Brain.md) — think_interval / issue_command / blackboard
- [SimpleAIEnemyBrain ref](../ref/modules/SimpleAIEnemyBrain.md) — 内置简单 AI 策略
- [EntitySpawner ref](../ref/modules/EntitySpawner.md) — 在运行时动态 spawn 敌人
- [cookbook/07_room.md](07_room.md) — 将敌人放进房间系统，由 RoomController 管理 spawn
