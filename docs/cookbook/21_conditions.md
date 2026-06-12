# Recipe 21：条件门禁（Condition）  ·  难度 ★★☆  ·  预计 20 分钟  ·  [扩展]

## 本篇结束后，你的项目新增了什么

技能、对话选项、商店条目、交互点等所有"数据驱动的入口"都可以挂**条件门禁**：火球术只能对射程内的目标施放；"处决"技能只在目标血量低于 30% 时可用。你会用上两个内置条件（`TargetInRangeCondition` / `CooldownReadyCondition`），并写一个自定义 `Condition` 子类。

条件系统是横切所有模块的机制：`AbilityDefinition.conditions`、`GameEffect.conditions`、`DialogueChoice.conditions`、`ShopEntry.conditions`、`Interactable.conditions`、`QuestDefinition.accept_conditions`、`LootEntry.conditions`、`RewardDefinition.conditions` 都是同一个 `Array[Condition]`，由同一个 `ConditionEvaluator.evaluate_all` 求值。学会一次，处处可用。

## 前置

- 需完成：[Recipe 05](05_ability.md)（有可施放的火球术）
- 用到的概念：[concepts.md — 模型 5：扩展点地图](../concepts.md#模型-5扩展点地图你写什么--mkit-管什么)

## 你负责 / mkit 负责

| 你写的 | mkit 处理的 |
|--------|------------|
| 创建 `Condition` 资源（内置或自定义子类），挂到任意 `conditions` 数组 | 各入口在执行前调用 `ConditionEvaluator.evaluate_all`，任一失败即拒绝 |
| 自定义条件：继承 `Condition`，override `_evaluate_impl(context)` | `evaluate()` 包装 `invert` 取反逻辑 |
| 可选：override `get_failure_reason(context)` 给出可读的失败原因 | `collect_failures` 收集所有失败原因（技能 cast 失败时进 `ability_failed` 信号）|

> `Condition` 继承 `Resource`（不是 `ContentDefinition`），**不需要**加入 `ResourceDatabase`，直接作为 `.tres` 子资源内嵌在定义里即可。

## 步骤

### 步骤 1：给火球术挂射程条件（TargetInRangeCondition）

打开 [Recipe 05](05_ability.md) 的 `fireball.tres`，在 `conditions` 数组里新增一个 `TargetInRangeCondition` 子资源：

| 字段 | 值 |
|------|----|
| `condition_id` | `"fireball_range"` |
| `range` | `200.0`（source 到 target 的距离 ≤ 200 像素才允许施放）|
| `invert` | `false` |

求值时机：`AbilityController.cast()` 在扣费**之前**调用 `get_cast_failure_reason()`，依次检查冷却 → cost → `conditions`。条件失败时 cast 返回 `false`，`ability_failed` 信号携带 `get_failure_reason()` 的返回值（这里是 `"target_out_of_range"`），费用不会被扣。

> `TargetInRangeCondition` 要求 `context.source` 和 `context.target` 都是 `Node2D`；任一为 null 时直接判 false。所以 Recipe 05 步骤 5 里 `ctx.target = _get_nearest_enemy()` 不能省。

### 步骤 2：连招门禁（CooldownReadyCondition）

做一个"火焰连击"技能，只有当**火球术冷却就绪**时才能施放（典型连招/派生技设计）。在 `fire_combo.tres` 的 `conditions` 里加 `CooldownReadyCondition`：

| 字段 | 值 |
|------|----|
| `condition_id` | `"combo_requires_fireball"` |
| `ability_id` | `"fireball"`（检查的是这个技能的冷却，不是自己的）|

实现细节（从源码核实）：

- `ability_id` 留空时回退读 `context.payload["ability_id"]`——而 `AbilityController` 求值条件前恰好会把**当前技能自己的 id** 写进 payload，所以留空等于"检查自己"（自己的冷却在条件之前已被检查过，留空没有意义）。**用于连招时务必显式填别的技能 id。**
- 它通过 `EntityContract.get_controller(context.source, "AbilityController")` 找控制器，所以 source 实体必须有 `AbilityController`，且目标技能已注册。
- "冷却就绪"的判定是 `current_charges > 0`（见 Recipe 05 字段参考的 `charges`）。

### 步骤 3：用 invert 取反——"脱战瞬移"

`invert` 把求值结果取反，"不满足时才通过"。例：瞬移技能只允许在**敌人不在近身范围**时使用：

`blink.tres` 的 `conditions` 挂一个 `TargetInRangeCondition`：

| 字段 | 值 |
|------|----|
| `condition_id` | `"no_enemy_nearby"` |
| `range` | `100.0` |
| `invert` | `true`（目标在 100 像素**以内**时反而禁止）|

> 注意 invert 也会反转 null 判定：source/target 任一为 null 时原始结果是 false，invert 后变 true（通过）。给会出现"无目标"的入口挂 invert 条件时要想清楚这一点。

### 步骤 4：自定义条件——"处决"（目标血量低于阈值）

继承 `Condition`，override `_evaluate_impl()`（不是 `evaluate()`——后者负责 invert 包装，不要碰）：

```gdscript
# res://game/conditions/target_hp_below_condition.gd
class_name TargetHpBelowCondition
extends Condition

## 目标血量百分比低于该值才通过；0.3 = 30%。
@export var hp_percent: float = 0.3


func _evaluate_impl(context: GameplayContext) -> bool:
    if context.target == null:
        return false
    var health := EntityContract.get_component(context.target, "HealthComponent") as HealthComponent
    if health == null or health.get_max_hp() <= 0.0:
        return false
    return health.current_hp / health.get_max_hp() < hp_percent


func get_failure_reason(context: GameplayContext) -> String:
    return "target_hp_not_low_enough"
```

挂到 `execute.tres`（处决技能）的 `conditions` 上，`hp_percent = 0.3`。同一个条件资源也可以挂到对话选项（"看你伤得不轻……"）或交互点上——条件只依赖 `GameplayContext`，不关心入口是谁。

> 更多自定义条件思路见 [Recipe 20 步骤 5](20_custom_service.md)：`ReputationCondition` 读自定义服务的声望值，挂到对话/商店/交互上。「持有某物品」「任务已完成」同理——在 `_evaluate_impl` 里查对应组件或服务即可。

### 步骤 5：失败原因排查

```gdscript
# 任意位置手动求值（也是测试条件的最快方式）：
var ctx := GameplayContext.from_nodes(player, enemy)
var conditions: Array[Condition] = [my_condition]
print(ConditionEvaluator.evaluate_all(conditions, ctx))      # false
print(ConditionEvaluator.collect_failures(conditions, ctx))  # ["target_out_of_range"]
```

技能入口已经替你做了这件事：cast 失败时 `ability_failed` 信号的 reason 就是 `collect_failures` 的逗号拼接结果（见 Recipe 05 步骤 7）。

## 求值时机一览

同一个 `Condition` 资源挂在不同入口，求值时机和 context 内容不同：

| 入口 | 求值时机 | context.source / target | 失败表现 |
|------|---------|------------------------|---------|
| `AbilityDefinition.conditions` | `cast()` 扣费前 | 施法者 / 调用方设置的目标 | cast 返回 false，`ability_failed` 携带原因 |
| `GameEffect.conditions` | **每个** effect `apply()` 时 | 随 effect 链传入 | 该 effect 返回 `EffectResult.fail`，链上其他 effect 不受影响 |
| `DialogueChoice.conditions` | `get_available_choices()` 列出选项时 | 对话发起时的 context | 选项**不显示** |
| `ShopEntry.conditions` | 购买前检查 | 买家 / null | 返回 "Entry locked"，购买失败 |
| `Interactable.conditions` | `interact()` 入口 | 交互发起者 / 通常为交互物 | `try_interact()` 返回 false |
| `QuestDefinition.accept_conditions` | `can_accept()` / `accept_quest()` | 调用方传入 | 接取失败 |
| `LootEntry.conditions` | roll 前过滤掉落池 | 掉落触发时的 context | 该条目**不进入**本次 roll |
| `RewardDefinition.conditions` | 生成三选一候选时 | 同上 | 该奖励不进入候选池 |
| `ItemDefinition.use_conditions` | 游戏代码手动求值（[Recipe 16](16_items_and_inventory.md) 步骤 4）| 使用者 / 自定 | 由你的代码决定 |

注意两类失败表现的区别：**门禁类**（技能/交互/任务/商店）失败会给出原因；**过滤类**（对话选项/掉落/奖励）失败是静默排除——调试掉落"为什么不掉"时记得检查 `LootEntry.conditions`。

## 字段参考

### Condition（基类，所有子类都继承这两个字段）

| 字段 | 类型/默认 | 含义 | 什么时候改 |
|------|----------|------|-----------|
| `condition_id` | String = "" | 调试与 trace 用的标识；默认失败原因是 `"Condition failed: <condition_id>"` | 建议总是填，否则失败日志无法定位是哪个条件 |
| `invert` | bool = false | 取反："不满足时才通过"。注意 null source/target 导致的 false 也会被反转成 true | 见步骤 3 |

### TargetInRangeCondition

| 字段 | 类型/默认 | 含义 | 什么时候改 |
|------|----------|------|-----------|
| `range` | float = 64.0 | `source.global_position` 到 `target.global_position` 的距离 ≤ range 时通过；source/target 任一不是 Node2D（或为 null）时判 false | 近战技能 ~80，远程 200+；配合 `invert` 可做"脱离距离"判定 |

### CooldownReadyCondition

| 字段 | 类型/默认 | 含义 | 什么时候改 |
|------|----------|------|-----------|
| `ability_id` | String = "" | 检查 `context.source` 实体 `AbilityController` 上该技能的冷却是否就绪（`current_charges > 0`）。留空时回退读 `payload["ability_id"]`——在技能 conditions 里留空等于检查自己，没有意义 | 连招/派生技：填**前置技能**的 id |

## 运行验证

1. 远离敌人按火球键：`Ability fireball failed: target_out_of_range`，魔法值**没有**被扣
2. 走近到 200 像素内：火球正常施放
3. 火球冷却中按连击键：`Ability fire_combo failed: Cooldown not ready: fireball`
4. 对满血敌人按处决键：`Ability execute failed: target_hp_not_low_enough`；打到残血后可施放
5. 手动跑步骤 5 的代码片段，确认 `collect_failures` 输出符合预期

## 常见错误

| 现象 | 原因 | 修复 |
|------|------|------|
| 条件永远失败 | `context.target` 为 null（`TargetInRangeCondition` 等依赖 target 的条件直接判 false）| 确认调用方设置了 `ctx.target`（Recipe 05 步骤 5）|
| 失败原因是 `"Condition failed: "`（空 id）| 没填 `condition_id` 且没 override `get_failure_reason` | 填 `condition_id`，自定义条件建议 override `get_failure_reason` |
| `CooldownReadyCondition` 永远失败 | source 实体没有 `AbilityController`，或目标技能未注册 | 确认控制器存在且 `ability_id` 在 `starting_ability_ids` 里 |
| invert 后行为反直觉 | null 判定也被反转（无目标时反而通过）| 在 `_evaluate_impl` 里先处理 null，或避免给可能无目标的入口挂 invert 条件 |
| 自定义条件不生效 | override 了 `evaluate()` 而不是 `_evaluate_impl()` | 只 override `_evaluate_impl()`；`evaluate()` 负责 invert 包装 |
| 掉落/对话选项"凭空消失" | 过滤类入口的条件失败是静默的 | 临时打印 `ConditionEvaluator.collect_failures(entry.conditions, ctx)` 排查 |

## 延伸阅读

- [Condition ref](../generated/html/classes/Condition.html) — evaluate / _evaluate_impl / get_failure_reason
- [ConditionEvaluator ref](../generated/html/classes/ConditionEvaluator.html) — evaluate_all / collect_failures
- [Recipe 20 — 自定义服务](20_custom_service.md) — `ReputationCondition`：条件接入自定义服务
- [Recipe 16 — 物品](16_items_and_inventory.md) — `use_conditions` 的手动求值模式
- [Recipe 17 — 交互区域](17_interaction_area.md) — `Interactable.conditions` 实战
