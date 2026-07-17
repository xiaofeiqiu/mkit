# Recipe 05：可配置技能（AbilityDefinition）  ·  难度 ★★★  ·  预计 30 分钟

## 本篇结束后，你的项目新增了什么

玩家有一个 "火球" 技能，通过 `.tres` 配置冷却、魔法消耗、效果。`AbilityController` 管理注册与冷却。按技能键施放：条件通过 → 扣费 → 执行 effect，冷却进入倒计时。重复按键时冷却中提示失败原因。

## 前置

- 需完成：[Recipe 03](03_health_and_stats.md)（StatsComponent / HealthComponent 已有）
- 用到的概念：[concepts.md — 模型 3：内容注册与查询](../concepts.md#模型-3内容注册与查询contentservice--resourcedatabase)

## 你负责 / mkit 负责

| 你写的 | mkit 处理的 |
|--------|------------|
| 创建 `AbilityDefinition` (.tres)，配置 id / 冷却 / cost / effects | — |
| 将 `.tres` 加入 `ResourceDatabase` | — |
| 在 `Controllers/` 下添加 `AbilityController`，设 `starting_ability_ids` | 从 `ContentService` 拉取 definition，创建 `AbilityInstance`，每帧 tick 冷却 |
| 在 State 中调用 `ability_ctrl.cast(ability_id, ctx)` | 条件检查、cost 扣除、CastAction（有 cast_time）或 instant GameAction，`_fire_effects` |
| 可选：添加 `ResourcePoolComponent` 管理魔法值 | — |

## 本篇路径

### Minimal path：只验证技能 effect

1. 先创建 `res://data/effects/fireball_damage.tres`，类型为 `DealDamageEffect`，`base_amount = 30`。
2. 在测试脚本导出这个资源，并准备 caster / target 两个节点。
3. 按键时执行：

```gdscript
var ctx := GameplayContext.from_nodes(caster, target)
Mkit.effects().execute(fireball_damage, ctx)
```

4. 目标扣血、`EffectService.recent_results` 有成功记录，即说明 effect 本身没问题。
5. 这条路径不检查 `AbilityDefinition`、冷却、费用、`cast_time`，只用来验证效果资源。

### Standard path：输入或 AI 发施法命令

1. 按步骤 1-4 创建 `fireball.tres`、配置 `ResourcePoolComponent`，并在 `PlayerEntity/Controllers/AbilityController.starting_ability_ids` 填 `["fireball"]`。
2. 在 Recipe 02 的 `player_input.gd` 里增加技能键：

```gdscript
if Input.is_action_just_pressed("cast_fireball"):
    _send_command(BuiltinCommands.CAST_ABILITY, {"ability_id": "fireball"})
```

3. 在 `Idle` / `Move` state 的 `handle_command()` 里处理 `BuiltinCommands.CAST_ABILITY`，调用本篇步骤 5 的 `_try_cast_ability(command)`。
4. 运行后按技能键：魔法值减少、目标扣血、冷却开始；冷却中再按会走 `ability_failed`。

### Advanced path：`AbilityController` 统一处理 cast time 和 effects

1. 在 state 里先找施法目标，例如最近敌人；没有目标就返回 `false`。
2. 用命令、施法者和目标构造上下文：

```gdscript
var ctx := GameplayContext.from_command(command, owner_entity, target)
```

3. 调用：

```gdscript
var ability_id := str(command.payload.get("ability_id", ""))
return ability_ctrl.cast(ability_id, ctx)
```

4. `fireball.tres.cast_time = 0` 时，`AbilityController` 会创建 instant action 并同帧完成。
5. 把 `cast_time` 改成 `0.8` 再运行，施法会交给 `CastAction` / `ActionService` 跨帧推进；这时才需要关心取消和施法动画。

## 步骤

### 步骤 1：创建 AbilityDefinition 资源

新建 Resource → `AbilityDefinition`，保存为 `res://data/abilities/fireball.tres`：

| 字段 | 值 |
|------|----|
| `ability_id` | `"fireball"` |
| `display_name` | `"火球术"` |
| `cooldown` | `2.0` |
| `charges` | `1` |
| `cost_type` | `"mana"` |
| `cost_amount` | `20.0` |
| `cast_time` | `0.0`（瞬发；改为 > 0 则走 CastAction 时序）|
| `conditions` | `[TargetInRangeCondition(range=200.0)]`（目标在 200 像素内才允许施放，详见 [Recipe 21](21_conditions.md)）|
| `effects` | `[res://data/effects/fireball_damage.tres]` |

创建效果资源 `fireball_damage.tres`（`DealDamageEffect`）：
- `effect_id` = `"fireball_damage"`
- `base_amount` = `30.0`
- `damage_type` = `"magic"`

### 步骤 2：将 AbilityDefinition 加入 ResourceDatabase

打开 `res://data/main_database.tres`，在 `resources` 数组中添加 `fireball.tres`（和 `fireball_damage.tres` 若 effect 也继承 ContentDefinition）。

> `DealDamageEffect` 继承 `GameEffect extends Resource`，不继承 `ContentDefinition`，无需加入数据库。只有继承 `ContentDefinition` 的资源才需要注册。

### 步骤 3：添加 ResourcePoolComponent（魔法值）

资源池的**上限**来自 `StatsComponent` 的 `max_<资源id>` 属性，**当前值**来自 `ResourcePoolComponent.starting_values`。两步配置：

1. 在 `StatsComponent.base_stats` 里设 `"max_mana": 100.0`（Recipe 03 的默认表里它是 0，必须改）
2. 在 `PlayerEntity/Components/` 下添加 `ResourcePoolComponent` 节点，Inspector 设 `starting_values`（Dictionary，key 为资源 id，value 为初始当前值）：

```
{"mana": 100.0}
```

> `starting_values` 里不写的资源，当前值默认回退到上限（即满值开局）。所以 `max_mana` 配好后 `starting_values` 留空也能用；想做"半蓝开局"才需要显式写 `{"mana": 50.0}`。字段语义详见 [Recipe 03 字段参考](03_health_and_stats.md#字段参考)。

### 步骤 4：添加 AbilityController

在 `PlayerEntity/Controllers/` 下添加 `AbilityController` 节点：

- `starting_ability_ids` = `["fireball"]`

`AbilityController._ready` 会自动从 `ContentService` 拉取 `fireball` 的 `AbilityDefinition` 并创建 `AbilityInstance`。

### 步骤 5：在状态中施放技能

在 `PlayerIdleState.handle_command` 中响应技能命令：

```gdscript
func handle_command(command: GameCommand) -> bool:
    match command.command_type:
        BuiltinCommands.MOVE:
            return request_transition("Root/Move", {"direction": command.get_vector2("direction")})
        BuiltinCommands.ATTACK:
            return request_transition("Root/Attack")
        BuiltinCommands.CAST_ABILITY:
            return _try_cast_ability(command)
    return false


func _try_cast_ability(command: GameCommand) -> bool:
    var ability_id := command.get_string("ability_id", "")
    if ability_id == "":
        return false

    var ctrl := EntityContract.get_controller(owner_entity, "AbilityController") as AbilityController
    if ctrl == null:
        return false

    var ctx := GameplayContext.new()
    ctx.source = owner_entity
    ctx.target = _get_nearest_enemy()  # 按实际目标逻辑实现
    ctx.payload["ability_id"] = ability_id

    if not ctrl.cast(ability_id, ctx):
        # cast 失败时 ability_failed 信号会携带原因
        return false
    return true


func _get_nearest_enemy() -> Node:
    return get_tree().get_first_node_in_group("enemy")  # 简化实现
```

### 步骤 6：发出技能命令

在输入控制器中监听技能键：

```gdscript
# 在 PlayerInputController._process 中：
if Input.is_action_just_pressed("ability_1"):
    var cmd := GameCommand.create(
        BuiltinCommands.CAST_ABILITY, "player", "player", {"ability_id": "fireball"}
    )
    _receiver.receive_command(cmd)
```

### 步骤 7：（可选）监听施放失败原因

```gdscript
# 在 AbilityController 信号连接处：
var ctrl := EntityContract.get_controller(self, "AbilityController") as AbilityController
ctrl.ability_failed.connect(func(id: String, reason: String) -> void:
    print("Ability %s failed: %s" % [id, reason])
)
ctrl.ability_cast_finished.connect(func(id: String) -> void:
    print("Ability %s cast complete" % id)
)
```

### 步骤 8：（可选）验证双层充能

把 `fireball.tres` 临时改成：

| 字段 | 值 |
|------|----|
| `charges` | `2` |
| `cooldown` | `3.0` |

运行时连续按两次技能键：前两次都应该成功，第三次才失败 `on_cooldown: fireball`。3 秒后回充 1 层，可以再施放一次；再等 3 秒回到满层。这个机制常用于闪避、短冲刺、连发法术等"可攒次数"技能；`AbilityController` 只管理充能和冷却，具体移动/伤害仍由你的 action/effect 链决定。

## 运行验证

1. 按技能键：`fireball` 触发，`fireball_damage` effect 执行（若有 target）
2. 冷却期间再次按技能键：控制台打印 `Ability fireball failed: on_cooldown: fireball`
3. 魔法值不足时：打印 `Ability fireball failed: insufficient_mana`
4. 等待 2 秒冷却结束后可再次施放

检查点：
- `AbilityController.get_cooldown_remaining("fireball")` 在冷却期应 > 0
- `EffectService.recent_results` 包含 `fireball_damage` 的执行结果

## 字段参考

### AbilityDefinition

| 字段 | 类型/默认 | 含义 | 什么时候改 |
|------|----------|------|-----------|
| `ability_id` | String = "" | ContentService 注册与查询用的稳定 id（`get_content_id()` 返回它）| 必填，全局唯一；见步骤 1 |
| `display_name` | String = "" | UI 显示名；不参与注册，留空时 UI 可回退到 id | 做技能栏/提示时填 |
| `description` | String = "" | 面向玩家的说明文案；mkit 不读取，纯 UI 用 | 做 tooltip 时填 |
| `icon` | Texture2D = null | 技能栏图标；mkit 不读取，由 HUD 代码取用（[Recipe 18](18_ui_hud.md)）| 做技能栏 UI 时填 |
| `cooldown` | float = 1.0 | 施放后的冷却秒数；受 `StatsComponent` 的 `cooldown_reduction` 缩减（`cd × (1 - cdr)`）| 见步骤 1 |
| `charges` | int = 1 | 可储存的使用层数。1 = 普通冷却；>1 时每次 cast 扣 1 层、可连续施放，冷却周期结束回充 1 层再继续充下一层。"冷却就绪" = 剩余层数 > 0。剩余层数随存档（`AbilityController.to_save_data` 的 `charges`）| 闪避/连发类技能设 2–3 |
| `cost_type` | String = "none" | 消耗的资源池 id，对应 `ResourcePoolComponent` 的池（如 `"mana"`、`"stamina"`）。`"none"` 或 `cost_amount ≤ 0` = 无消耗。**实体没有 ResourcePoolComponent 或池不存在/不足时 cast 失败 `insufficient_<cost_type>`** | 见步骤 1、3 |
| `cost_amount` | float = 0.0 | 每次施放扣多少；条件检查通过后、effect 执行前扣除 | 见步骤 1 |
| `cast_time` | float = 0.0 | 前摇秒数。0 = 瞬发（同帧执行 effects）；>0 走 `CastAction`，结束才触发 effects，期间可被取消（`cast_cancelled:<reason>`）| 吟唱类技能设 0.5–2.0 |
| `tags` | Array[String] = [] | 标签；供查询过滤、事件追踪、UI 分组，mkit 不做规则判定 | 做"沉默禁用法术类技能"等机制时配合自定义逻辑用 |
| `conditions` | Array[Condition] = [] | cast 前的门禁：冷却 → cost → conditions 依次检查，任一失败则不扣费不施放，失败原因进 `ability_failed`。全部条件类型见 [Recipe 21](21_conditions.md) | 见步骤 1 |
| `effects` | Array[GameEffect] = [] | 条件通过、扣费后按顺序执行的效果链（瞬发时同帧、有 cast_time 时在前摇结束后）| 见步骤 1 |

## 常见错误

| 现象 | 原因 | 修复 |
|------|------|------|
| `ability failed: target_out_of_range` | 步骤 1 挂的 `TargetInRangeCondition` 不满足，或 `ctx.target` 为 null | 靠近目标；确认步骤 5 设置了 `ctx.target`（详见 [Recipe 21](21_conditions.md)）|
| `ability failed: not_registered: fireball` | `AbilityDefinition` 不在 ContentService 中 | 确认 `fireball.tres` 已加入 `ResourceDatabase.resources`，且 Bootstrap 先于玩家场景加载 |
| `ability failed: insufficient_mana` | 实体没有 `ResourcePoolComponent`，或 `StatsComponent` 缺 `max_mana`（上限 0 = 池不存在）| 按步骤 3 配 `max_mana` + `starting_values` |
| Cast 成功但无伤害 | `context.target` 为 null | 确认 `ctx.target` 指向有 HealthComponent 的节点 |
| Effect 未触发 | `cast_time = 0` 下 instant GameAction 走完了但 `on_complete_effects` 为空 | `AbilityDefinition.effects` 是否正确赋值 |
| 冷却时间不对 | 没有 `StatsComponent` 上的 `cooldown_reduction` | 无需处理，`AbilityController` 若无 StatsComponent 则 cdr=0 |

## 延伸阅读

- [AbilityController ref](../generated/html/classes/AbilityController.html) — register / cast / cooldown / save
- [AbilityDefinition ref](../generated/html/classes/AbilityDefinition.html) — 所有配置字段
- [ContentService ref](../generated/html/classes/ContentService.html) — get_resource / has / validate_all
- [pipeline.md — Ability Cast](../pipeline.md#5-ability-cast) — instant vs CastAction 两条路径完整图
- [cookbook/12_status_effects.md](12_status_effects.md) — 为技能添加 DOT / buff 效果
- [cookbook/21_conditions.md](21_conditions.md) — 条件门禁：射程、连招、自定义条件
