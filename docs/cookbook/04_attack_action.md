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
- 在 Inspector 设 `target_factions` = `["enemy"]`（按受击方 `EntityIdentity.faction` 过滤，默认值即此），`hit_tags` = `["melee"]`
- 命中流程已内置：`_ready` 自动连接 `area_entered`，active 期间检测到 `HurtboxComponent` 进入时构造 `DamageRequest` → `CombatService.resolve()` → 目标 `HealthComponent.apply_damage()`

HitboxComponent 的 `set_active(true/false)` 切换命中检测开关（开启瞬间会清空"已命中"名单并扫描当前重叠区域）。`TimedAttackAction` 在 active 窗口自动调用此方法。

**HurtboxComponent**（内置脚本，加到玩家和将来的敌人）：
- 同样是 `Area2D` + `CollisionShape2D`
- `owner_path` 保持默认 `../..`（Hurtbox 放在 `Components/` 下时正好指回实体根节点）
- 阵营不配在 Hurtbox 上——攻击方 `target_factions` 对照的是受击实体 `EntityIdentity.faction`（Recipe 02 配过）

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
    _action_svc = Mkit.actions()


func enter(_context: Dictionary = {}) -> void:
    var attack := TimedAttackAction.new()
    attack.startup_duration = 0.12
    attack.active_duration  = 0.10
    attack.recovery_duration = 0.25
    attack.hitbox_path = NodePath("Components/HitboxComponent")
    # 若你的场景中 hitbox 节点命名非标准，可继续保留 hitbox_component_name 兼容

    # 命中后执行的伤害效果（data-driven）
    var dmg := DealDamageEffect.new()
    dmg.effect_id = "player_melee_hit"
    dmg.base_amount = 15.0
    dmg.damage_type = "physical"
    attack.on_complete_effects = [dmg]

    var ctx := ActionContext.new()
    ctx.source = owner_entity
    ctx.payload["ability_id"] = "melee_attack"

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
    _receiver.receive_command(cmd)
```

### 步骤 5：理清两条伤害路径

本 Recipe 里实际存在两条独立的伤害路径，别混淆：

1. **Hitbox 直伤（区域命中）**：active 窗口内 `HurtboxComponent` 进入 → `HitboxComponent` 用自己的 `base_damage` / `damage_type` / `element_type` 构造 `DamageRequest`，直接打在被碰到的实体上。**不经过 effect 链，也不需要 context.target**——目标就是碰到的那个 Hurtbox 的拥有者。
2. **完成钩子 effect（`on_complete_effects` 里的 `DealDamageEffect`）**：action complete 时执行，从 `context.target` 读取目标。target 为 null 时该 effect 失败（`no_target`），但不影响路径 1。

只想要"挥刀命中区域内敌人"时，配好路径 1 即可（在 Inspector 设 `HitboxComponent.base_damage = 15.0`），可以删掉步骤 2 里的 `on_complete_effects`。要测试路径 2，临时在 `PlayerAttackState.enter` 中硬编码 target：

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

## 字段参考

### HitboxComponent（攻击判定区，挂在攻击方）

| 字段 | 类型/默认 | 含义 | 什么时候改 |
|------|----------|------|-----------|
| `active` | bool = false | 是否参与命中检测；由 `TimedAttackAction` 在 active 窗口经 `set_active()` 自动开关 | 一般不手改；持续伤害区可在代码里常开 |
| `base_damage` | float = 1.0 | 直伤路径的基础伤害（× 受击方 `damage_multiplier` 后进 `DamageRequest`，由 `CombatService` 继续结算防御/暴击）| 见步骤 5 路径 1 |
| `damage_type` | String = "physical" | 伤害类型 id；进 `DamageRequest`，参与抗性/格挡规则与事件标签 | 魔法武器设 `"magic"` 等 |
| `element_type` | String = "none" | 元素类型 id；`"none"` = 无元素。进 `DamageRequest`，供弱点/抗性规则使用（见 [pipeline.md — Damage Resolution](../pipeline.md#7-damage-resolution)）| 火焰剑设 `"fire"` |
| `hit_once_per_activation` | bool = true | 同一次激活内同一目标只结算一次（按 `EntityIdentity.entity_id` 去重，`set_active(true)` 时重置）。设 `false` = 重叠期间每次 `area_entered` 都结算，适合持续伤害区 | 岩浆地板/激光设 `false` |
| `target_factions` | Array[String] = ["enemy"] | 允许命中的阵营白名单，对照受击实体 `EntityIdentity.faction`。默认 `["enemy"]` 是"玩家打敌人"；**敌人的 hitbox 必须改成 `["player"]`**。受击方没有 EntityIdentity 时不过滤（一律可命中）；受击方有 EntityIdentity 时，空数组会拒绝所有阵营，不表示"全阵营" | 敌人实体（[Recipe 06](06_ai_enemy.md)）|
| `hit_tags` | Array[String] = [] | 随本次命中写入 `DamageRequest.tags` 的标签（会再拼上 Hurtbox 的 `damage_tags`）；供条件、状态和事件过滤 | 见步骤 1 |
| `on_hit_statuses` | Array[Dictionary] = [] | 命中后尝试施加的状态列表，每项形如 `{"status_id": "status.poison", "chance": 0.5, "stacks": 1, "duration": -1.0}`，由 `CombatService` 掷骰（详见 [Recipe 12](12_status_effects.md) 步骤 5）| 武器附带中毒/减速时 |

### HurtboxComponent（受击判定区，挂在受击方）

| 字段 | 类型/默认 | 含义 | 什么时候改 |
|------|----------|------|-----------|
| `owner_path` | NodePath = "../.." | 从 Hurtbox 节点向上指到"受击归属实体"的路径；伤害最终落到该实体的 `HealthComponent`。默认值适配 `实体/Components/HurtboxComponent` 的标准布局 | Hurtbox 不在标准层级时（如挂在骨骼下）显式指回实体根 |
| `can_receive_damage` | bool = true | 无敌开关；`false` 时所有传入命中被直接忽略 | 翻滚无敌帧、剧情无敌时在代码里切 |
| `damage_multiplier` | float = 1.0 | 部位倍率，乘在 `base_damage` 上：爆头 Hurtbox 设 `2.0`，护甲部位 `0.5`，`0` = 免疫 | 多 Hurtbox 部位伤害时 |
| `damage_tags` | Array[String] = [] | 该部位为传入伤害补充的标签（拼进 `DamageRequest.tags`）| 配合 `"headshot"` 之类的标签做事件/成就 |

### DealDamageEffect（effect 链路径，对照步骤 2）

| 字段 | 类型/默认 | 含义 | 什么时候改 |
|------|----------|------|-----------|
| `effect_id` | String = "" | 日志/调试用 id（继承自 GameEffect）| 建议总是填 |
| `conditions` | Array[Condition] = [] | apply 前的门禁，失败返回 `EffectResult.fail`（继承自 GameEffect，见 [Recipe 21](21_conditions.md)）| "仅对燃烧目标生效"之类 |
| `tags` | Array[String] = [] | effect 自身的分类标签，mkit 不做规则判定（继承自 GameEffect）| 一般留空 |
| `base_amount` | float = 10.0 | 基础伤害，进 `DamageRequest.base_amount` | 见步骤 2 |
| `damage_type` | String = "physical" | 同 Hitbox 的 `damage_type` | — |
| `element_type` | String = "none" | 同 Hitbox 的 `element_type`；在伤害管线的抗性步骤参与计算 | — |
| `can_crit` | bool = true | 是否参与暴击掷骰（用 source 的 `crit_chance` / `crit_damage`）；`false` 则跳过暴击步骤——DOT tick 伤害通常关掉 | [Recipe 12](12_status_effects.md) 的 `poison_tick` 设 `false` |
| `hit_tags` | Array[String] = [] | 写入 `DamageRequest.tags` | — |
| `on_hit_statuses` | Array[Dictionary] = [] | 同 Hitbox 的 `on_hit_statuses` | — |

> 对比：`HitboxComponent` 是"碰到谁打谁"（区域、不要 target），`DealDamageEffect` 是"打 context.target"（点名、可进任意 effect 链）。两者最终都汇入同一条 `DamageRequest → CombatService.resolve → DamageResult` 管线。

## 常见错误

| 现象 | 原因 | 修复 |
|------|------|------|
| Hitbox 重叠但不掉血 | `target_factions` 与受击方 `EntityIdentity.faction` 不匹配 | 玩家打敌人保持默认 `["enemy"]`；敌人打玩家改 `["player"]` |
| Action 立即 complete，没有时序 | 未调 `_action_svc.start_action()`，直接 `action.start()` + `action.complete()` | 必须通过 `ActionService.start_action` 注册，才会每帧 `update` |
| Hitbox 不开启 | `hitbox_path` 为空或命名不匹配 | 1) 用 `NodePath("Components/HitboxComponent")` ；2) 保留 `hitbox_component_name` 为默认组件名 |
| 攻击完成但无伤害 | `context.target` 为 null | 在 `ActionContext` 里赋 `ctx.target` |
| 状态无法进入 Attack | `can_enter()` 返回 false（默认 true，不应该出现）| 检查 State 节点是否正确挂在 Root 下 |
| 攻击动画不播放 | `Presentation/AnimationPlayer` 不存在或无 `"attack"` 动画 | `TimedAttackAction._play_animation` 会静默跳过，不影响逻辑 |

## 延伸阅读

- [GameAction ref](../generated/html/classes/GameAction.html) — start / update / complete / cancel / _fire_effects
- [ActionService ref](../generated/html/classes/ActionService.html) — start_action / cancel_actions_for_source
- [pipeline.md — Ability Cast](../pipeline.md#5-ability-cast) — instant vs timed 两条路径
- [cookbook/13_animation.md](13_animation.md) — 如何为攻击动作接入真实动画
