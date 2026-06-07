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
| `effects` | `[res://data/effects/fireball_damage.tres]` |

创建效果资源 `fireball_damage.tres`（`DealDamageEffect`）：
- `effect_id` = `"fireball_damage"`
- `base_amount` = `30.0`
- `damage_type` = `"magic"`

### 步骤 2：将 AbilityDefinition 加入 ResourceDatabase

打开 `res://data/main_database.tres`，在 `resources` 数组中添加 `fireball.tres`（和 `fireball_damage.tres` 若 effect 也继承 ContentDefinition）。

> `DealDamageEffect` 继承 `GameEffect extends Resource`，不继承 `ContentDefinition`，无需加入数据库。只有继承 `ContentDefinition` 的资源才需要注册。

### 步骤 3：添加 ResourcePoolComponent（魔法值）

在 `PlayerEntity/Components/` 下添加 `ResourcePoolComponent` 节点：

在 Inspector 设 `pools`（Dictionary）：
```
"mana": {"current": 100.0, "max": 100.0}
```

或在 `_ready` 中代码初始化：

```gdscript
func _ready() -> void:
    var pool := EntityContract.get_component(self, "ResourcePoolComponent") as ResourcePoolComponent
    if pool != null:
        pool.add_pool("mana", 100.0, 100.0)
```

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
    ctx.ability_id = ability_id

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
    _commands.dispatch(cmd)
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

## 运行验证

1. 按技能键：`fireball` 触发，`fireball_damage` effect 执行（若有 target）
2. 冷却期间再次按技能键：控制台打印 `Ability fireball failed: on_cooldown: fireball`
3. 魔法值不足时：打印 `Ability fireball failed: insufficient_mana`
4. 等待 2 秒冷却结束后可再次施放

检查点：
- `AbilityController.get_cooldown_remaining("fireball")` 在冷却期应 > 0
- `EffectService.recent_results` 包含 `fireball_damage` 的执行结果

## 常见错误

| 现象 | 原因 | 修复 |
|------|------|------|
| `ability failed: not_registered: fireball` | `AbilityDefinition` 不在 ContentService 中 | 确认 `fireball.tres` 已加入 `ResourceDatabase.resources`，且 Bootstrap 先于玩家场景加载 |
| `ability failed: insufficient_mana` | `ResourcePoolComponent` 无 `mana` pool 或初始值为 0 | 在 `ResourcePoolComponent` 设 mana 初始值 |
| Cast 成功但无伤害 | `context.target` 为 null | 确认 `ctx.target` 指向有 HealthComponent 的节点 |
| Effect 未触发 | `cast_time = 0` 下 instant GameAction 走完了但 `on_complete_effects` 为空 | `AbilityDefinition.effects` 是否正确赋值 |
| 冷却时间不对 | 没有 `StatsComponent` 上的 `cooldown_reduction` | 无需处理，`AbilityController` 若无 StatsComponent 则 cdr=0 |

## 延伸阅读

- [AbilityController ref](../ref/modules/AbilityController.md) — register / cast / cooldown / save
- [AbilityDefinition ref](../ref/modules/AbilityDefinition.md) — 所有配置字段
- [ContentService ref](../ref/kernel/ContentService.md) — get_resource / has / validate_all
- [pipeline.md — Ability Cast](../pipeline.md#5-ability-cast) — instant vs CastAction 两条路径完整图
- [cookbook/12_status_effects.md](12_status_effects.md) — 为技能添加 DOT / buff 效果
