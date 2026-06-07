# Recipe 12：状态效果（DOT / buff）  ·  难度 ★★☆  ·  预计 20 分钟  ·  [扩展]

## 本篇结束后，你的项目新增了什么

技能命中后给目标挂一个**中毒**状态：每秒掉血、持续 5 秒、可叠加 3 层；还有一个**狂暴** buff：临时提升攻击力。状态由 `.tres` 配置，`StatusEffectController` 每帧 tick，到期自动移除并回收属性加成。

## 前置

- 需完成：[Recipe 05](05_ability.md)（有一个能挂 effect 的技能）
- 用到的概念：[concepts.md — 模型 5：扩展点地图](../concepts.md#模型-5扩展点地图你写什么--mkit-管什么)

## 你负责 / mkit 负责

| 你写的 | mkit 处理的 |
|--------|------------|
| 创建 `StatusEffectDefinition` (.tres)：时长 / tick / 叠加规则 / effect 链 | `StatusEffectController._process()` 每帧推进、按 `tick_interval` 触发、到期移除 |
| 给可被施加状态的实体挂 `StatusEffectController` | `apply_status()` 按 `stack_rule` 叠加；`stat_modifiers` 自动挂到 `StatsComponent` |
| 在技能 effect 链挂 `ApplyStatusEffect`（或用伤害的 `on_hit_statuses`）| 把 effect 派发到目标的 `StatusEffectController` |

## 步骤

### 步骤 1：创建中毒（DOT）StatusEffectDefinition

新建 Resource → `StatusEffectDefinition`，存为 `res://data/status/poison.tres`：

| 字段 | 值 |
|------|----|
| `status_id` | `"status.poison"` |
| `display_name` | `"中毒"` |
| `duration` | `5.0` |
| `tick_interval` | `1.0`（每秒一跳）|
| `max_stacks` | `3` |
| `stack_rule` | `ADD_STACK`（再次施加叠层并刷新时长）|
| `effects_on_tick` | `[res://data/effects/poison_tick.tres]` |

`poison_tick.tres` 是一个 `DealDamageEffect`：
- `effect_id` = `"poison_tick"`, `base_amount` = `5.0`, `damage_type` = `"poison"`

> tick 时 `StatusEffectController` 用 `source=施加者`、`target=被施加者（owner）` 构造 context 执行 `effects_on_tick`，所以 `DealDamageEffect` 正好打在中毒目标自己身上。

加入 `ResourceDatabase.resources`。

### 步骤 2：创建狂暴（buff）StatusEffectDefinition

再建 `res://data/status/rage.tres`：

| 字段 | 值 |
|------|----|
| `status_id` | `"status.rage"` |
| `duration` | `8.0` |
| `tick_interval` | `0.0`（不 tick，纯属性 buff）|
| `max_stacks` | `1` |
| `stack_rule` | `REFRESH_DURATION` |
| `stat_modifiers` | `[StatModifierDefinition(stat_id="attack_power", operation=FLAT_ADD, value=10)]` |

`stat_modifiers` 在 `apply_status()` 时被挂到目标 `StatsComponent`，到期移除时自动卸下（`remaining_duration` 作为 modifier 的存活时间）。同样入库。

### 步骤 3：给实体挂 StatusEffectController

在会"中毒/狂暴"的实体（敌人、玩家）`Controllers/` 下加 `StatusEffectController` 节点。它依赖同实体的 `Components/StatsComponent`（buff 用）和 `Components/HealthComponent`（DOT 掉血用）。

```
EnemyEntity
├── Components/
│   ├── StatsComponent
│   └── HealthComponent
└── Controllers/
    └── StatusEffectController   # ← 新增
```

### 步骤 4：让技能施加状态

打开 [Recipe 05](05_ability.md) 的 `fireball.tres`，往 `effects` 里追加一个 `ApplyStatusEffect`：

- `status_id` = `"status.poison"`, `stacks` = `1`, `duration_override` = `-1.0`（用定义里的 5 秒）

`ApplyStatusEffect` 以 `context.target` 为目标，找它的 `Controllers/StatusEffectController` 并 `apply_status()`。火球现在"直伤 + 上毒"。

> 给玩家自己上狂暴：做一个 `buff_rage` 技能，effect 用 `ApplyStatusEffect(status_id="status.rage")`，并把 cast 时的 `ctx.target` 设成玩家自己。

### 步骤 5：（替代路径）用伤害的 on_hit_statuses

不想走技能 effect 链，也可以让普通攻击带毒。`DealDamageEffect` / `HitboxComponent` / `DamageRequest` 都有 `on_hit_statuses`（`Array[Dictionary]`）。结算时它会进入 `DamageIntent.on_hit_statuses`：

```
on_hit_statuses = [{"status_id": "status.poison", "chance": 0.5, "stacks": 1, "duration": -1.0}]
```

`CombatService.resolve()` 按 `chance` 掷骰，命中则写进 `DamageResolution.applied_status_effects`，再映射到 `DamageResult.status_applications`，最后由 `HealthComponent.apply_damage()` 通过 `EntityContract.get_controller(..., "StatusEffectController")` 转交。这条路适合"武器附带 X% 中毒"。

## 运行验证

1. 火球命中敌人 → 敌人 `StatusEffectController.has_status("status.poison")` 为真
2. 之后每秒敌人掉 5 血（叠 2 层则每跳 5 伤害仍按单 effect，叠层影响的是你在 effect 里读 `payload["stacks"]` 的逻辑）
3. 5 秒后 `status_removed` 触发，状态消失
4. 施加 `status.rage` → 目标 `attack_power` +10，8 秒后自动回落
5. `StatusEffectController` 的 `status_applied` / `status_ticked` / `status_removed` 信号可打 log 观察

## 常见错误

| 现象 | 原因 | 修复 |
|------|------|------|
| `apply_failed:status.poison` | 目标没有 `Controllers/StatusEffectController` | 给目标挂上该控制器 |
| 中毒不掉血 | `effects_on_tick` 里的 `DealDamageEffect` 找不到 `HealthComponent` | 目标需有 `Components/HealthComponent` |
| buff 不生效/不回落 | 没有 `StatsComponent`，或 `tick_interval` 设错 | buff 走 `stat_modifiers`，需 `StatsComponent`；纯 buff 设 `tick_interval=0` |
| 叠加不符合预期 | `stack_rule` 选错 | DOT 常用 `ADD_STACK`，buff 常用 `REFRESH_DURATION` |
| 读档后状态丢了 | `StatusEffectController` 是 `SaveableComponent` | 用 [Recipe 11](11_progression_and_save.md) 步骤 4 的代理收集它 |

## 延伸阅读

- [StatusEffectDefinition ref](../ref/modules/StatusEffectDefinition.md) — StackRule 全枚举
- [StatusEffectController ref](../ref/modules/StatusEffectController.md) · [ApplyStatusEffect ref](../ref/modules/ApplyStatusEffect.md)
- [pipeline.md — Status Effect Tick](../pipeline.md#19-status-effect-tick)
- [CombatService ref](../ref/modules/CombatService.md) — on_hit_statuses 掷骰
