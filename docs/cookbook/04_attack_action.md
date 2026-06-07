# Recipe 04：攻击动作时序 + Hitbox  ·  难度 ★★★  ·  预计 30 分钟

## 本篇结束后，你的项目新增了什么

玩家有攻击状态。按攻击键发出 `attack` 命令，进入攻击状态，`TimedAttackAction` 自动管理 startup → active → recovery 三段时序，active 窗口内 `HitboxComponent` 开启，命中 `HurtboxComponent` 后造成伤害。

## 前置

- 需完成：[Recipe 03](03_health_and_stats.md)（HealthComponent 已在玩家身上）
- 用到的概念：[concepts.md — 模型 1：标准管线](../concepts.md#模型-1标准管线时序图)（Action 段）

## 你负责 / mkit 负责

| 你写的 | mkit 处理的 |
|--------|------------|
| 添加 `HitboxComponent` 到玩家 `Components/` | — |
| 添加 `HurtboxComponent` 到玩家（或敌人）`Components/` | 检测与 HitboxComponent 的 Area2D 重叠 |
| 在 Attack 状态下 `ActionService.start_action(TimedAttackAction, ctx)` | 管理 Action 生命周期（update / complete / cancel）|
| 配置 `TimedAttackAction` 的时序参数 | startup → active（开 Hitbox）→ recovery → complete，自动 `_fire_effects` |
| 声明 `on_complete_effects`（含 `DealDamageEffect`）| 每帧 update，钩子后自动执行 effect 链 |

## 步骤

### 步骤 1：添加 HitboxComponent 到玩家

在 `PlayerEntity/Components/` 下添加节点：

**HitboxComponent**（内置脚本）：
- 继承 `Area2D`，添加 `CollisionShape2D`（设 disabled = true，由 Action 控制启用）
- 在 Inspector 设 `team` = `"player"`，`damage_tags` = `["melee"]`
- 将 HitboxComponent 连接伤害触发：

```gdscript
# HitboxComponent 在 _ready 时自动连接 area_entered 信号
# 当 Hurtbox 进入时，HitboxComponent 会调用其上注册的 on_hit_callback
```

HitboxComponent 的 `set_active(true/false)` 会切换 `CollisionShape2D.disabled`。`TimedAttackAction` 在 active 窗口自动调用此方法。

**HurtboxComponent**（内置脚本，加到玩家和将来的敌人）：
- 同样是 `Area2D` + `CollisionShape2D`
- 在 Inspector 设 `team` = `"player"`

> 注意：Hitbox 和 Hurtbox 的 collision layer/mask 需要在 Godot 物理层设置上互相可见，否则不触发重叠。

### 步骤 2：添加 Attack 状态

在 `StateMachine/Root/` 下新增 `Attack` State 节点（`state_id = "Attack"`）：

```gdscript
# res://game/player/states/player_attack_state.gd
class_name PlayerAttackState
extends State

var _action_svc: ActionService = null
var _current_action: GameAction = null


func _ready() -> void:
    _action_svc = ServiceRegistry.get_service("actions") as ActionService


func enter(_context: Dictionary = {}) -> void:
    var attack := TimedAttackAction.new()
    attack.startup_duration = 0.12
    attack.active_duration  = 0.10
    attack.recovery_duration = 0.25
    attack.hitbox_path = NodePath("Components/HitboxComponent")

    # 命中后执行的伤害效果（data-driven）
    var dmg := DealDamageEffect.new()
    dmg.effect_id = "player_melee_hit"
    dmg.base_amount = 15.0
    dmg.damage_type = "physical"
    attack.on_complete_effects = [dmg]

    var ctx := ActionContext.new()
    ctx.source = owner_entity
    ctx.ability_id = "melee_attack"

    _current_action = _action_svc.start_action(attack, ctx)
    if _current_action != null:
        _current_action.completed.connect(_on_attack_done)
        _current_action.cancelled.connect(_on_attack_done_or_cancelled)


func exit(_context: Dictionary = {}) -> void:
    if _current_action != null and not _current_action.is_finished():
        _current_action.cancel("state_exit")
    _current_action = null


func handle_command(command: GameCommand) -> bool:
    # 在 recovery 段可以取消以接受新输入（如果 cancel_tags 包含该 tag）
    return false


func _on_attack_done(_action: GameAction) -> void:
    request_transition("Root/Idle")


func _on_attack_done_or_cancelled(_action: GameAction, _reason: String) -> void:
    request_transition("Root/Idle")
```

### 步骤 3：在 Idle/Move 状态中响应攻击命令

```gdscript
# 在 PlayerIdleState.handle_command 中添加：
func handle_command(command: GameCommand) -> bool:
    match command.command_type:
        BuiltinCommands.MOVE:
            return request_transition("Root/Move", {"direction": command.get_vector2("direction")})
        BuiltinCommands.ATTACK:
            return request_transition("Root/Attack")
    return false
```

### 步骤 4：从输入发出攻击命令

```gdscript
# 在 PlayerInputController._process 中添加：
if Input.is_action_just_pressed("ui_select"):  # 或自定义攻击键
    var cmd := GameCommand.create(BuiltinCommands.ATTACK, "player", "player")
    _commands.dispatch(cmd)
```

### 步骤 5：让 HitboxComponent 知道攻击目标

`DealDamageEffect` 从 `context.target` 读取受击实体。`TimedAttackAction` 在 active 窗口启用 `HitboxComponent`；`HitboxComponent` 检测到 `HurtboxComponent` 进入时，需要将目标写入 context：

```gdscript
# HitboxComponent 的标准做法：在 area_entered 时填充 context.target
# 实际 HitboxComponent.gd 中已内置此逻辑：
# func _on_area_entered(area: Area2D) -> void:
#     if area is HurtboxComponent:
#         _notify_hit(area.owner)   # owner 是携带 HurtboxComponent 的实体
```

对于本 Recipe 的测试，你可以临时在 `PlayerAttackState.enter` 中硬编码 target：

```gdscript
ctx.target = get_tree().get_first_node_in_group("enemy")  # Recipe 06 会换成真实敌人
```

## 运行验证

1. 按攻击键（`ui_select`）
2. 控制台应打印 `HitboxComponent` 相关日志（若有调试输出）
3. `TimedAttackAction` 时序：startup 0.12s → hitbox 开 0.10s → recovery 0.25s → 自动 complete
4. `complete()` 后 `on_complete_effects` 中的 `DealDamageEffect` 被执行
5. 若 target 不为 null，`damage_applied` 事件触发，`entity_died` 在 HP=0 时触发

在 `_on_attack_done` 中加 `print("Attack complete")` 确认流程走通。

## 常见错误

| 现象 | 原因 | 修复 |
|------|------|------|
| Action 立即 complete，没有时序 | 未调 `_action_svc.start_action()`，直接 `action.start()` + `action.complete()` | 必须通过 `ActionService.start_action` 注册，才会每帧 `update` |
| Hitbox 不开启 | `hitbox_path` 路径不对 | 用 `NodePath("Components/HitboxComponent")` 且与场景树一致 |
| 攻击完成但无伤害 | `context.target` 为 null | 在 `ActionContext` 里赋 `ctx.target` |
| 状态无法进入 Attack | `can_enter()` 返回 false（默认 true，不应该出现）| 检查 State 节点是否正确挂在 Root 下 |
| 攻击动画不播放 | `Presentation/AnimationPlayer` 不存在或无 `"attack"` 动画 | `TimedAttackAction._play_animation` 会静默跳过，不影响逻辑 |

## 延伸阅读

- [GameAction ref](../ref/kernel/GameAction.md) — start / update / complete / cancel / _fire_effects
- [ActionService ref](../ref/kernel/ActionService.md) — start_action / cancel_actions_for_source
- [pipeline.md — Ability Cast](../pipeline.md#5-ability-cast) — instant vs timed 两条路径
- [cookbook/13_animation.md](13_animation.md) — 如何为攻击动作接入真实动画
