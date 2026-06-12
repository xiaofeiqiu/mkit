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

## 本篇路径

### Minimal path：脚本直接给目标上状态

1. 先按步骤 1 创建 `status.poison`，并把 `poison.tres` 加入 `ResourceDatabase`。
2. 在会中毒的实体 `Controllers/` 下加 `StatusEffectController`。
3. 测试脚本已拿到 `caster` 和 `target` 时，直接调用：

```gdscript
var status_ctrl := EntityContract.get_controller(target, "StatusEffectController") as StatusEffectController
if status_ctrl != null:
    status_ctrl.apply_status("status.poison", caster)
```

4. 运行后观察 `status_ctrl.has_status("status.poison")` 为 true，目标每秒掉血。
5. 这条路径是同步施加状态；不要为了普通 `apply_status()` 包 `GameAction`。

### Standard path：施法命令沿用 Recipe 05

1. 打开 Recipe 05 的 `fireball.tres`，在 `effects` 数组末尾加入 `ApplyStatusEffect`，`status_id = "status.poison"`。
2. 玩家输入仍然只发送 `cast_ability` 命令：

```gdscript
_send_command(BuiltinCommands.CAST_ABILITY, {"ability_id": "fireball"})
```

3. state 调 `AbilityController.cast("fireball", ctx)`；能力控制器检查冷却、费用和条件。
4. 技能执行到 effects 时，`ApplyStatusEffect` 从 `ctx.target` 找 `StatusEffectController` 并上毒。
5. 验证方式：火球命中后目标既受到直伤，又出现 `status.poison`。

这里仍然不需要 `CommandService`：调用方已经拿到玩家实体，只需把命令交给自己的 `CommandReceiver`。

### Advanced path：状态跟随 ability / action 生命周期

1. 施法有读条时，把 `fireball.tres.cast_time` 改成 `0.8`；状态会在 `CastAction` 完成时才跟随 effects 触发。
2. 普通攻击要附带中毒时，把 `ApplyStatusEffect` 放进 `TimedAttackAction.on_complete_effects` 或伤害 `on_hit_statuses`。
3. 如果动作被取消，complete effects 不执行，状态也不会施加。
4. 如果 effect 自身还有 `conditions`，`EffectService` 会在施加状态前先检查。
5. 验证方式：读条期间打断施法，目标不应中毒；完整施法完成后才中毒。

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
- `effect_id` = `"poison_tick"`, `base_amount` = `5.0`, `damage_type` = `"poison"`, `can_crit` = `false`（DOT 跳伤不吃暴击）

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

不想走技能 effect 链，也可以让普通攻击带毒。`DealDamageEffect` / `HitboxComponent` / `DamageRequest` 都有 `on_hit_statuses`（`Array[Dictionary]`）：

```
on_hit_statuses = [{"status_id": "status.poison", "chance": 0.5, "stacks": 1, "duration": -1.0}]
```

`CombatService.resolve()` 按 `chance` 掷骰，命中则写进 `DamageResult.status_applications`，最后由 `HealthComponent.apply_damage()` 通过 `EntityContract.get_controller(..., "StatusEffectController")` 转交。这条路适合"武器附带 X% 中毒"。

## 运行验证

1. 火球命中敌人 → 敌人 `StatusEffectController.has_status("status.poison")` 为真
2. 之后每秒敌人掉 5 血（叠 2 层则每跳 5 伤害仍按单 effect，叠层影响的是你在 effect 里读 `payload["stacks"]` 的逻辑）
3. 5 秒后 `status_removed` 触发，状态消失
4. 施加 `status.rage` → 目标 `attack_power` +10，8 秒后自动回落
5. `StatusEffectController` 的 `status_applied` / `status_ticked` / `status_removed` 信号可打 log 观察

## 字段参考

### StatusEffectDefinition

| 字段 | 类型/默认 | 含义 | 什么时候改 |
|------|----------|------|-----------|
| `status_id` | String = "" | ContentService 注册用稳定 id；同一实体上同 id 状态只存在一个实例 | 必填，见步骤 1 |
| `display_name` | String = "" | UI 显示名（状态图标栏等）；mkit 不读取 | 做 buff 栏 UI 时填 |
| `duration` | float = 5.0 | 默认持续秒数；可被 `ApplyStatusEffect.duration_override` 覆盖。**注意：负数当前不会永久——`_process` 每帧减时长，≤0 即移除**，"永久状态"需设一个超大值 | 见步骤 1 |
| `tick_interval` | float = 1.0 | 每隔几秒触发一次 `effects_on_tick`；≤ 0 = 从不 tick（纯属性 buff 用）| DOT 设 0.5–2，buff 设 0（步骤 2）|
| `max_stacks` | int = 1 | `ADD_STACK` 规则下的层数上限；1 = 不可叠加 | 见步骤 1 |
| `stack_rule` | enum = REFRESH_DURATION | 状态**已存在**时再次施加的处理规则，6 个取值：<br>`REFRESH_DURATION` — 层数不变，剩余时间重置为 duration（buff 续杯）<br>`ADD_STACK` — 层数 +stacks（夹到 max_stacks）**且**重置剩余时间（可叠 DOT）<br>`REPLACE` — 层数直接改成本次的 stacks、时间重置（覆盖式，新施加无视旧层数）<br>`IGNORE` — 完全忽略本次施加，旧状态原样继续<br>`EXTEND_DURATION` — 层数不变，剩余时间**累加** duration（续时不刷新）<br>`INDEPENDENT_STACKS` — **预留值，当前实现等同 IGNORE**（实例按 status_id 单槽存储，暂不支持同 id 多实例）| DOT 用 ADD_STACK，buff 用 REFRESH_DURATION，霸体类一次性状态用 IGNORE |
| `tags` | Array[String] = [] | 标签；供"驱散所有 debuff"之类的自定义逻辑查询，mkit 不做规则判定 | 设 `["debuff"]` 等 |
| `effects_on_apply` | Array[GameEffect] = [] | 状态**首次施加**瞬间执行的 effect 链（叠层/刷新不会再触发）| 冰冻上身时播放定身 effect |
| `effects_on_tick` | Array[GameEffect] = [] | 每个 tick 周期执行的 effect 链 | 见步骤 1 |
| `effects_on_remove` | Array[GameEffect] = [] | 到期或被 `remove_status()` 移除瞬间执行的 effect 链 | 死亡绽放：中毒结束时爆炸 |
| `stat_modifiers` | Array[StatModifierDefinition] = [] | 状态期间挂到 `StatsComponent` 的属性修饰；施加时自动挂上、移除时自动卸下（字段语义见 [Recipe 03 字段参考](03_health_and_stats.md#字段参考)）| 见步骤 2 |

三段 effect 钩子的生命周期对比：

| 钩子 | 触发时机 | 触发次数 | context 内容 |
|------|---------|---------|-------------|
| `effects_on_apply` | 首次 `apply_status()`，挂上 stat_modifiers 之后 | 整个状态生命周期 1 次（叠层不重触发）| `source`=施加者，`target`=持有者，payload 带 `status_id` / `stacks` / `source_id` |
| `effects_on_tick` | 每 `tick_interval` 秒 | duration / tick_interval 次 | 同上（`stacks` 是当下层数，DOT 想按层数加伤就在自定义 effect 里读它）|
| `effects_on_remove` | 到期或手动移除，卸下 stat_modifiers 之前 | 1 次 | 同上 |

### ApplyStatusEffect（往 effect 链里塞"上状态"）

| 字段 | 类型/默认 | 含义 | 什么时候改 |
|------|----------|------|-----------|
| `effect_id` / `conditions` / `tags` | 继承 GameEffect | 同所有 effect：id 用于日志，conditions 是 apply 前门禁（[Recipe 21](21_conditions.md)）| — |
| `status_id` | String = "" | 要施加的 `StatusEffectDefinition` id；目标（`context.target`）需挂 `StatusEffectController`，否则失败 `no_status_controller` | 必填，见步骤 4 |
| `stacks` | int = 1 | 一次施加几层；首次施加直接成为初始层数，已存在时按 `stack_rule` 处理（`ADD_STACK` 下加这么多层）| "重毒"技能一次上 3 层毒 |
| `duration_override` | float = -1.0 | 覆盖定义的 `duration`；负数 = 用定义默认值 | 同一个毒，精英怪上 10 秒、小怪上 5 秒 |

## 常见错误

| 现象 | 原因 | 修复 |
|------|------|------|
| `apply_failed:status.poison` | 目标没有 `Controllers/StatusEffectController` | 给目标挂上该控制器 |
| 中毒不掉血 | `effects_on_tick` 里的 `DealDamageEffect` 找不到 `HealthComponent` | 目标需有 `Components/HealthComponent` |
| buff 不生效/不回落 | 没有 `StatsComponent`，或 `tick_interval` 设错 | buff 走 `stat_modifiers`，需 `StatsComponent`；纯 buff 设 `tick_interval=0` |
| 叠加不符合预期 | `stack_rule` 选错 | DOT 常用 `ADD_STACK`，buff 常用 `REFRESH_DURATION` |
| 读档后状态丢了 | `StatusEffectController` 是 `SaveableComponent` | 用 [Recipe 11](11_progression_and_save.md) 步骤 4 的 `EntitySaveAgent` 收集它 |

## 延伸阅读

- [StatusEffectDefinition ref](../generated/html/classes/StatusEffectDefinition.html) — StackRule 全枚举
- [StatusEffectController ref](../generated/html/classes/StatusEffectController.html) · [ApplyStatusEffect ref](../generated/html/classes/ApplyStatusEffect.html)
- [pipeline.md — Status Effect Tick](../pipeline.md#19-status-effect-tick)
- [CombatService ref](../generated/html/classes/CombatService.html) — on_hit_statuses 掷骰
