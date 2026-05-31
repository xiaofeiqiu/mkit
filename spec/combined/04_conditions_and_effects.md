# Conditions and Effects

---

# 6. Condition 系统接口设计

---

## 6.1 Condition

### 概念说明

- 是什么：可复用的真假规则。
- 负责什么：判断技能能不能放、状态能不能切、奖励能不能出现、掉落项能不能进入池子等。
- 为什么需要：把规则做成 Resource 后，技能、装备、奖励、AI 都能共享同一套检查逻辑。

`res://addons/mkit/kernel/conditions/condition.gd`

```gdscript
class_name Condition
extends Resource

@export var condition_id: String = ""
@export var invert: bool = false

func evaluate(context: GameplayContext) -> bool:
    var result := _evaluate_impl(context)
    if invert:
        return not result
    return result

func _evaluate_impl(context: GameplayContext) -> bool:
    return true

func get_failure_reason(context: GameplayContext) -> String:
    return "Condition failed: %s" % condition_id
```

#### 字段说明
- **condition_id**：稳定 ID 字段。例：Condition 通过 condition_id 引用某个定义或运行时对象，避免直接保存节点路径。
#### 函数使用场景
- **evaluate()**：评估规则。实际例子：AbilityController 释放火球前评估 mana、cooldown、range 三个条件。
- **_evaluate_impl()**：内部辅助函数。实际例子：由 **Condition** 的公开流程调用，用来完成 $fn 对应的子步骤；外部系统通常不应该直接调用它。
- **get_failure_reason()**：读取数据入口。实际例子：CombatResolver 通过 get_failure_reason 获取最终攻击力，而不是直接读内部变量。

---

### 27.21 Condition 使用示例

#### 详细实际用例

- 真实场景：火球需要“冷却完成 + Mana 足够 + 目标在范围内”三个条件都满足。每个条件都是一个 `Condition`。
- 怎么使用：把可复用规则做成 Resource，挂到 AbilityDefinition、RewardDefinition 或 AI 规则上。
- 验证重点：条件失败要能说明原因，例如 `cooldown_not_ready` 或 `target_out_of_range`。
### 自定义 HasTagCondition

```gdscript
class_name HasTagCondition
extends Condition

@export var required_tag: String = ""

func _evaluate_impl(context: GameplayContext) -> bool:
    if context.target == null:
        return false
    var identity := context.target.get_node_or_null("EntityIdentity") as EntityIdentity
    return identity != null and identity.has_tag(required_tag)
```

### 使用在 AbilityDefinition 中

```gdscript
var condition := HasTagCondition.new()
condition.required_tag = "enemy"
fireball_definition.conditions.append(condition)
```

---

---

---

## 6.2 ConditionEvaluator

### 概念说明

- 是什么：条件列表的统一评估器。
- 负责什么：执行 all/any 规则，收集失败原因，并支持调试输出。
- 为什么需要：当技能不能释放或奖励没出现时，开发者需要知道具体是哪条规则失败。

```gdscript
class_name ConditionEvaluator
extends RefCounted

static func evaluate_all(conditions: Array[Condition], context: GameplayContext) -> bool:
    for condition in conditions:
        if condition == null:
            continue
        if not condition.evaluate(context):
            return false
    return true

static func collect_failures(conditions: Array[Condition], context: GameplayContext) -> Array[String]:
    var failures: Array[String] = []
    for condition in conditions:
        if condition != null and not condition.evaluate(context):
            failures.append(condition.get_failure_reason(context))
    return failures
```

#### 函数使用场景
- **evaluate_all()**：评估规则。实际例子：AbilityController 释放火球前评估 mana、cooldown、range 三个条件。
- **collect_failures()**：公开 API。实际例子：外部系统通过它请求 **ConditionEvaluator** 执行一个明确操作，并通过返回值、信号或状态变化确认结果。

---

### 27.22 ConditionEvaluator 使用示例

#### 详细实际用例

- 真实场景：玩家点火球按钮时，AbilityController 把火球的条件列表交给 ConditionEvaluator，一次性得到是否可释放和失败原因。
- 怎么使用：需要 all/any 条件时都走 evaluator，不要在 UI、AbilityController、AI 里各写一套循环。
- 验证重点：多个条件失败时能收集完整原因，UI 可以显示最重要的一条。
```gdscript
var ctx := GameplayContext.new()
ctx.source = player
ctx.target = enemy

if ConditionEvaluator.evaluate_all(ability_def.conditions, ctx):
    print("Ability can be used")
else:
    var failures := ConditionEvaluator.collect_failures(ability_def.conditions, ctx)
    print("Cannot cast: ", failures)
```

---

---

---

## 6.3 CooldownReadyCondition

### 概念说明

- 是什么：检查冷却是否就绪的条件。
- 负责什么：读取技能、物品或控制器中的 cooldown 状态。
- 为什么需要：冷却是最常见的技能门槛，统一条件能避免每个技能自己写一遍。

```gdscript
class_name CooldownReadyCondition
extends Condition

@export var ability_id: String = ""

func _evaluate_impl(context: GameplayContext) -> bool:
    if context.source == null:
        return false
    var controller := context.source.get_node_or_null("Controllers/AbilityController") as AbilityController
    if controller == null:
        return false
    var id := ability_id
    if id == "":
        id = context.ability_id
    return controller.is_cooldown_ready(id)

func get_failure_reason(context: GameplayContext) -> String:
    return "Ability cooldown is not ready: %s" % ability_id
```

#### 字段说明
- **ability_id**：技能定义 ID。例：ability.fireball_basic 让 AbilityController 找到火球定义并读取冷却、消耗和效果。
#### 函数使用场景
- **_evaluate_impl()**：内部辅助函数。实际例子：由 **CooldownReadyCondition** 的公开流程调用，用来完成 $fn 对应的子步骤；外部系统通常不应该直接调用它。
- **get_failure_reason()**：读取数据入口。实际例子：CombatResolver 通过 get_failure_reason 获取最终攻击力，而不是直接读内部变量。

---

### 27.23 CooldownReadyCondition 使用示例

#### 详细实际用例

- 真实场景：火球刚释放过，剩余冷却 1.8 秒。CooldownReadyCondition 返回 false，AbilityController 拒绝再次施法。
- 怎么使用：条件读取 AbilityInstance 或 cooldown storage，不直接依赖 UI 的冷却显示。
- 验证重点：冷却归零后条件变 true；冷却缩减属性变化后，剩余冷却行为符合设计。
```gdscript
var condition := CooldownReadyCondition.new()
condition.ability_id = "ability.fireball_basic"

var ctx := GameplayContext.new()
ctx.source = player

if condition.evaluate(ctx):
    print("Fireball is ready")
```

---

---

---

## 6.4 TargetInRangeCondition

### 概念说明

- 是什么：检查目标距离的条件。
- 负责什么：比较 source 和 target 的位置与配置范围。
- 为什么需要：攻击、互动、AI 决策和技能都需要距离检查，统一实现能保证行为一致。

```gdscript
class_name TargetInRangeCondition
extends Condition

@export var range: float = 64.0

func _evaluate_impl(context: GameplayContext) -> bool:
    if context.source == null or context.target == null:
        return false
    return context.source.global_position.distance_to(context.target.global_position) <= range
```

#### 字段说明
- **range**：作用范围。例：近战技能 range=48，火球 range=600。
#### 函数使用场景
- **_evaluate_impl()**：内部辅助函数。实际例子：由 **TargetInRangeCondition** 的公开流程调用，用来完成 $fn 对应的子步骤；外部系统通常不应该直接调用它。

---

---

### 27.24 TargetInRangeCondition 使用示例

#### 详细实际用例

- 真实场景：敌人在 600px 内时火球可释放，超过 600px 时按钮可以变灰或释放失败。
- 怎么使用：从 GameplayContext 读取 source/target 位置，比较配置 range。
- 验证重点：目标为空、目标死亡、目标刚好在边界距离时都有明确结果。
```gdscript
var condition := TargetInRangeCondition.new()
condition.range = 96.0

var ctx := GameplayContext.new()
ctx.source = player
ctx.target = enemy

if condition.evaluate(ctx):
    print("Enemy is in range")
```

---

---

---

# 7. Effect 系统接口设计

---

## 7.1 EffectResult

### 概念说明

- 是什么：效果执行后的结构化结果。
- 负责什么：记录成功与否、失败原因、影响目标、数值、标签和调试信息。
- 为什么需要：DebugOverlay、测试和战斗日志需要知道效果到底做了什么，而不是只看到 HP 变了。

`res://addons/mkit/kernel/effects/effect_result.gd`

```gdscript
class_name EffectResult
extends RefCounted

var success: bool = true
var effect_id: String = ""
var failure_reason: String = ""
var payload: Dictionary = {}
var child_results: Array[EffectResult] = []

static func ok(id: String = "", data: Dictionary = {}) -> EffectResult:
    var r := EffectResult.new()
    r.success = true
    r.effect_id = id
    r.payload = data
    return r

static func fail(id: String, reason: String) -> EffectResult:
    var r := EffectResult.new()
    r.success = false
    r.effect_id = id
    r.failure_reason = reason
    return r
```

#### 字段说明
- **success**：状态标记。例：用它判断当前对象是否已经处理过，避免重复触发。
- **effect_id**：稳定 ID 字段。例：EffectResult 通过 effect_id 引用某个定义或运行时对象，避免直接保存节点路径。
- **payload**：扩展数据包。例：attack 命令可以放 direction，cast_ability 可以放 ability_id；MVP 阶段允许用它承载少量灵活数据。
#### 函数使用场景
- **ok()**：公开 API。实际例子：外部系统通过它请求 **EffectResult** 执行一个明确操作，并通过返回值、信号或状态变化确认结果。
- **fail()**：公开 API。实际例子：外部系统通过它请求 **EffectResult** 执行一个明确操作，并通过返回值、信号或状态变化确认结果。

---

### 27.25 EffectResult 使用示例

#### 详细实际用例

- 真实场景：HealEffect 尝试治疗玩家，但玩家已经满血。EffectResult 可以记录 success=true、amount=0 或 reason=`already_full`。
- 怎么使用：每个 Effect 返回结构化结果，DebugOverlay 和测试根据它判断效果是否按预期执行。
- 验证重点：失败时必须有 reason；成功时应记录影响目标和关键数值。
```gdscript
var result := EffectResult.ok("grant_gold", {"gold": 20})
print(result.success)
print(result.payload["gold"])
```

### 失败结果

```gdscript
var failed := EffectResult.fail("deal_damage", "Target has no HealthComponent")
push_warning(failed.failure_reason)
```

---

---

---

## 7.2 GameEffect

### 概念说明

- 是什么：声明式玩法结果。
- 负责什么：表达伤害、治疗、上状态、生成场景、给予物品、修改属性等结果。
- 为什么需要：技能、物品、奖励和状态都可以组合 Effect，减少一次性脚本。

`res://addons/mkit/kernel/effects/game_effect.gd`

```gdscript
class_name GameEffect
extends Resource

@export var effect_id: String = ""
@export var conditions: Array[Condition] = []
@export var tags: Array[String] = []

func apply(context: GameplayContext) -> EffectResult:
    if not ConditionEvaluator.evaluate_all(conditions, context):
        var failures := ConditionEvaluator.collect_failures(conditions, context)
        return EffectResult.fail(effect_id, ", ".join(failures))
    return _apply_impl(context)

func _apply_impl(context: GameplayContext) -> EffectResult:
    return EffectResult.ok(effect_id)
```

#### 字段说明
- **effect_id**：稳定 ID 字段。例：GameEffect 通过 effect_id 引用某个定义或运行时对象，避免直接保存节点路径。
- **conditions**：释放或生效条件。例：HasEnoughMana、CooldownReady、TargetInRange。
- **tags**：标签集合。例：enemy、boss、projectile、fire，条件和效果可以通过标签判断适用性。
#### 函数使用场景
- **apply()**：应用玩法结果。实际例子：RewardSystem 应用 +20% attack 的奖励 Effect。
- **_apply_impl()**：内部辅助函数。实际例子：由 **GameEffect** 的公开流程调用，用来完成 $fn 对应的子步骤；外部系统通常不应该直接调用它。

---

### 27.26 GameEffect 使用示例

#### 详细实际用例

- 真实场景：一个“燃烧火球”技能由 `DealDamageEffect` 和 `ApplyStatusEffect(status.burn)` 组成。Ability 不写具体扣血代码，只执行效果列表。
- 怎么使用：把“会发生什么”配置成 Effect Resource；“什么时候发生”交给 Action 或 AbilityController。
- 验证重点：同一个 Effect 能被技能、奖励、物品复用，且执行日志能看出来源。
### 自定义 GrantGoldEffect

```gdscript
class_name GrantGoldEffect
extends GameEffect

@export var amount: int = 10

func _apply_impl(context: GameplayContext) -> EffectResult:
    var progression := ServiceRegistry.get_service("progression") as ProgressionSystem
    if progression == null:
        return EffectResult.fail(effect_id, "Missing ProgressionSystem")

    progression.add_currency("gold", amount)
    return EffectResult.ok(effect_id, {"gold": amount})
```

---

---

---

## 7.3 EffectExecutor

### 概念说明

- 是什么：Effect 的统一执行器。
- 负责什么：按顺序执行效果，记录 trace，返回结果，并限制任意系统随意修改玩法状态。
- 为什么需要：集中执行能让调试、回放、测试和数据驱动配置更可靠。

`res://addons/mkit/kernel/effects/effect_executor.gd`

```gdscript
class_name EffectExecutor
extends RefCounted

var trace_enabled: bool = true
var recent_results: Array[EffectResult] = []
var max_recent_results: int = 100

func execute(effect: GameEffect, context: GameplayContext) -> EffectResult:
    if effect == null:
        return EffectResult.fail("null_effect", "Effect is null")

    var result := effect.apply(context)
    _record_result(result)
    return result

func execute_many(effects: Array[GameEffect], context: GameplayContext, stop_on_failure: bool = false) -> Array[EffectResult]:
    var results: Array[EffectResult] = []
    for effect in effects:
        var result := execute(effect, context)
        results.append(result)
        if stop_on_failure and not result.success:
            break
    return results

func _record_result(result: EffectResult) -> void:
    if not trace_enabled:
        return
    recent_results.append(result)
    if recent_results.size() > max_recent_results:
        recent_results.pop_front()
```

#### 字段说明
- **trace_enabled**：状态标记。例：用它判断当前对象是否已经处理过，避免重复触发。
#### 函数使用场景
- **execute()**：公开 API。实际例子：外部系统通过它请求 **EffectExecutor** 执行一个明确操作，并通过返回值、信号或状态变化确认结果。
- **execute_many()**：公开 API。实际例子：外部系统通过它请求 **EffectExecutor** 执行一个明确操作，并通过返回值、信号或状态变化确认结果。
- **_record_result()**：内部辅助函数。实际例子：由 **EffectExecutor** 的公开流程调用，用来完成 $fn 对应的子步骤；外部系统通常不应该直接调用它。

---

### 27.27 EffectExecutor 使用示例

#### 详细实际用例

- 真实场景：玩家选择 “Power Up” 奖励后，RewardSystem 把奖励里的多个 Effect 交给 EffectExecutor 顺序执行：加攻击 modifier、播放音效、记录事件。
- 怎么使用：上层系统不要自己循环随意调用各种组件；统一通过 executor 收集结果和 trace。
- 验证重点：某个 Effect 失败时能知道失败位置；是否继续执行后续效果要有明确规则。
```gdscript
var executor := ServiceRegistry.get_service("effects") as EffectExecutor
var ctx := GameplayContext.new()
ctx.source = player
ctx.target = enemy

var results := executor.execute_many(ability_def.effects, ctx, true)
for result in results:
    if not result.success:
        print("Effect failed: ", result.failure_reason)
```

---

---

---

## 7.4 DealDamageEffect

### 概念说明

- 是什么：把效果转换成伤害请求的 Effect。
- 负责什么：用配置和 GameplayContext 创建 DamageRequest 并交给 CombatResolver。
- 为什么需要：技能和攻击不应该直接扣血，而应该走统一战斗公式。

`res://addons/mkit/kernel/effects/builtin/deal_damage_effect.gd`

```gdscript
class_name DealDamageEffect
extends GameEffect

@export var base_amount: float = 1.0
@export var damage_type: String = "physical"
@export var element_type: String = "none"
@export var can_crit: bool = true
@export var damage_tags: Array[String] = []
@export var on_hit_statuses: Array[Dictionary] = [] # 每项: {status_id, chance, stacks, duration}

func _apply_impl(context: GameplayContext) -> EffectResult:
    if context.source == null:
        return EffectResult.fail(effect_id, "Missing source")
    if context.target == null:
        return EffectResult.fail(effect_id, "Missing target")

    var request := DamageRequest.new()
    request.source = context.source
    request.target = context.target
    request.base_amount = base_amount
    request.damage_type = damage_type
    request.element_type = element_type
    request.can_crit = can_crit
    request.tags = damage_tags.duplicate()
    request.on_hit_statuses = on_hit_statuses.duplicate()

    var resolver := CombatResolver.get_default()
    var result := resolver.resolve(request)

    var health := context.target.get_node_or_null("Components/HealthComponent") as HealthComponent
    if health == null:
        return EffectResult.fail(effect_id, "Target has no HealthComponent")

    health.apply_damage(result)

    return EffectResult.ok(effect_id, {
        "final_amount": result.final_amount,
        "critical": result.was_critical,
        "lethal": result.was_lethal,
        "applied_status_effects": result.applied_status_effects
    })
```

#### 字段说明
- **base_amount**：基础伤害/治疗数值。例：火球基础伤害 20，最终伤害还要经过攻击力、暴击和防御计算。
- **damage_type**：伤害类型。例：physical、magic、true，用于不同防御规则。
- **element_type**：元素类型。例：fire、ice、poison，用于抗性、弱点或状态联动。
- **can_crit**：是否允许暴击。例：普通攻击可以暴击，持续毒伤通常不暴击。
- **on_hit_statuses**：命中时尝试附加的状态（含概率/层数/时长），交给 CombatResolver 掷定、HealthComponent 施加。例：燃烧火球可不再单独配 ApplyStatusEffect，直接写 `[{"status_id":"status.burn","chance":0.3}]`，让伤害和上状态共享同一次命中判定。
#### 函数使用场景
- **_apply_impl()**：内部辅助函数。实际例子：由 **DealDamageEffect** 的公开流程调用，用来完成 $fn 对应的子步骤；外部系统通常不应该直接调用它。

---

### 27.28 DealDamageEffect 使用示例

#### 详细实际用例

- 真实场景：火球命中 goblin 后，DealDamageEffect 创建 DamageRequest，base_amount=20，element_type=fire，然后交给 CombatResolver 算最终伤害。
- 怎么使用：Effect 只描述“造成伤害”这件事，不自己读防御、暴击或扣 HP。
- 验证重点：同一个 DealDamageEffect 用在剑击、火球、陷阱时都走同一套 DamageResult。
```gdscript
var effect := DealDamageEffect.new()
effect.effect_id = "effect.fireball_damage"
effect.base_amount = 25.0
effect.damage_type = "magic"
effect.element_type = "fire"
effect.can_crit = true

var ctx := GameplayContext.new()
ctx.source = player
ctx.target = enemy

var result := effect.apply(ctx)
print(result.payload)
```

---

---

---

## 7.5 HealEffect

### 概念说明

- 是什么：恢复生命值的 Effect。
- 负责什么：通过 HealthComponent 应用治疗并产出事件和结果。
- 为什么需要：药水、奖励、状态、治疗技能都需要同一条治疗路径。

```gdscript
class_name HealEffect
extends GameEffect

@export var amount: float = 1.0
@export var use_source_healing_multiplier: bool = true

func _apply_impl(context: GameplayContext) -> EffectResult:
    if context.target == null:
        return EffectResult.fail(effect_id, "Missing target")

    var final_amount := amount
    if use_source_healing_multiplier and context.source != null:
        var stats := context.source.get_node_or_null("Components/StatsComponent") as StatsComponent
        if stats != null:
            final_amount *= stats.get_stat_value("healing_multiplier", 1.0)

    var health := context.target.get_node_or_null("Components/HealthComponent") as HealthComponent
    if health == null:
        return EffectResult.fail(effect_id, "Target has no HealthComponent")

    health.heal(final_amount, context.source)
    return EffectResult.ok(effect_id, {"amount": final_amount})
```

#### 字段说明
- **amount**：通用数值。例：HealEffect 可以把 amount 当治疗量，RewardEffect 可以把 amount 当金币数量。
#### 函数使用场景
- **_apply_impl()**：内部辅助函数。实际例子：由 **HealEffect** 的公开流程调用，用来完成 $fn 对应的子步骤；外部系统通常不应该直接调用它。

---

### 27.29 HealEffect 使用示例

#### 详细实际用例

- 真实场景：玩家使用小药水，HealEffect 读取 amount=30，把玩家 HP 从 40/100 恢复到 70/100，并发出 healed 事件。
- 怎么使用：治疗通过 HealthComponent 执行，不能直接改 `current_hp`，否则 UI、事件和存档可能不同步。
- 验证重点：满血、死亡状态、治疗倍率、最大 HP 限制都有一致处理。
```gdscript
var heal := HealEffect.new()
heal.effect_id = "effect.small_heal"
heal.amount = 30.0

var ctx := GameplayContext.new()
ctx.source = player
ctx.target = player

heal.apply(ctx)
```

---

---

---

## 7.6 ApplyStatusEffect

### 概念说明

- 是什么：给目标附加状态的 Effect。
- 负责什么：通过 StatusEffectController 创建、刷新或叠加状态。
- 为什么需要：燃烧、中毒、减速、护盾、眩晕等都需要统一的持续时间和叠加逻辑。

```gdscript
class_name ApplyStatusEffect
extends GameEffect

@export var status_id: String = ""
@export var duration_override: float = -1.0
@export var stacks: int = 1

func _apply_impl(context: GameplayContext) -> EffectResult:
    if context.target == null:
        return EffectResult.fail(effect_id, "Missing target")

    var controller := context.target.get_node_or_null("Controllers/StatusEffectController") as StatusEffectController
    if controller == null:
        return EffectResult.fail(effect_id, "Target has no StatusEffectController")

    var applied := controller.apply_status(status_id, context.source, stacks, duration_override)
    if not applied:
        return EffectResult.fail(effect_id, "Status was not applied: %s" % status_id)

    return EffectResult.ok(effect_id, {"status_id": status_id, "stacks": stacks})
```

#### 字段说明
- **status_id**：状态定义 ID。例：status.burn 用于创建燃烧状态实例。
- **duration_override**：时间相关字段。例：控制持续时间、tick 间隔或动作阶段，便于暂停、调试和调参。
#### 函数使用场景
- **_apply_impl()**：内部辅助函数。实际例子：由 **ApplyStatusEffect** 的公开流程调用，用来完成 $fn 对应的子步骤；外部系统通常不应该直接调用它。

---

---

### 27.30 ApplyStatusEffect 使用示例

#### 详细实际用例

- 真实场景：火球有 30% 概率给敌人挂 `status.burn`，Burn 每秒造成一次火焰伤害，持续 4 秒。
- 怎么使用：ApplyStatusEffect 找到目标的 StatusEffectController，让 controller 决定是新增、刷新还是叠层。
- 验证重点：重复施加燃烧时叠加规则正确；状态过期后 modifier 和 tick 都被清理。
```gdscript
var burn := ApplyStatusEffect.new()
burn.effect_id = "effect.apply_burn"
burn.status_id = "status.burn"
burn.stacks = 1
burn.duration_override = 4.0

var ctx := GameplayContext.new()
ctx.source = player
ctx.target = enemy

burn.apply(ctx)
```

---

---

---

## 7.7 SpawnSceneEffect

### 概念说明

- 是什么：生成一个场景实例的通用 Effect。
- 负责什么：从 scene_path 或 ObjectPool 创建节点，设置位置/方向，并把 GameplayContext 传给生成物。
- 为什么需要：投射物、地面掉落、陷阱、召唤物和一次性 VFX 都可能由技能或奖励触发；用通用生成效果比写死投射物专用效果更可复用。

```gdscript
class_name SpawnSceneEffect
extends GameEffect

@export var scene_path: String = ""
@export var use_object_pool: bool = true
@export var parent_group: String = ""
@export var position_offset: Vector2 = Vector2.ZERO
@export var inherit_direction: bool = true

func _apply_impl(context: GameplayContext) -> EffectResult:
    if scene_path == "":
        return EffectResult.fail(effect_id, "Missing scene_path")

    var parent := _resolve_parent(context)
    if parent == null:
        return EffectResult.fail(effect_id, "Missing spawn parent")

    var spawned := _spawn_node(parent)
    if spawned == null:
        return EffectResult.fail(effect_id, "Cannot spawn scene: %s" % scene_path)

    _initialize_spawned(spawned, context)
    return EffectResult.ok(effect_id, {
        "scene_path": scene_path,
        "spawned": spawned
    })

func _resolve_parent(context: GameplayContext) -> Node:
    if context.payload.has("spawn_parent") and context.payload["spawn_parent"] is Node:
        return context.payload["spawn_parent"]
    if parent_group != "" and context.source != null:
        return context.source.get_tree().get_first_node_in_group(parent_group)
    if context.source != null:
        return context.source.get_parent()
    return null

func _spawn_node(parent: Node) -> Node:
    if use_object_pool and ServiceRegistry.has_service("pool"):
        var pool := ServiceRegistry.get_service("pool") as ObjectPool
        if pool != null:
            return pool.acquire(scene_path, parent)

    var scene := load(scene_path) as PackedScene
    if scene == null:
        return null
    var node := scene.instantiate()
    parent.add_child(node)
    return node

func _initialize_spawned(spawned: Node, context: GameplayContext) -> void:
    if spawned is Node2D:
        var origin := context.position
        if origin == Vector2.ZERO and context.source is Node2D:
            origin = context.source.global_position
        spawned.global_position = origin + position_offset

    if inherit_direction and "direction" in spawned:
        spawned.direction = context.direction
    if spawned.has_method("setup"):
        spawned.setup(context)
```

#### 字段说明
- **scene_path**：要生成的场景路径。例：火球技能生成 `res://game/projectiles/fireball.tscn`。
- **use_object_pool**：是否优先使用 ObjectPool。例：投射物和 VFX 高频生成时设为 true。
- **parent_group**：生成父节点组名。例：ProjectilesRoot 节点加入 `projectiles` group。
- **position_offset**：生成位置偏移。例：从角色前方 16px 处生成 projectile。
- **inherit_direction**：是否把 context.direction 写给生成物。例：投射物沿施法方向飞行。
#### 函数使用场景
- **_apply_impl()**：执行生成。实际例子：AbilityController 执行 fireball 的 SpawnSceneEffect。
- **_resolve_parent()**：查找父节点。实际例子：优先使用 context.payload.spawn_parent，其次找 parent_group。
- **_spawn_node()**：创建节点。实际例子：从 ObjectPool acquire 火球，否则 instantiate 场景。
- **_initialize_spawned()**：初始化生成物。实际例子：设置位置、方向并调用 setup(context)。

---

### 27.91 SpawnSceneEffect 使用示例

#### 详细实际用例

- 真实场景：火球 AbilityDefinition 的 effects 里放一个 SpawnSceneEffect，scene_path 指向 FireballProjectile。CastAction 完成后，EffectExecutor 执行它，在玩家面前生成投射物。
- 怎么使用：生成节点只负责把场景放出来；投射物命中后仍然通过 Hitbox/Hurtbox、DealDamageEffect 或 CombatResolver 处理伤害。
- 验证重点：缺失 parent、缺失 scene_path、对象池为空时都有明确结果；生成物方向来自 GameplayContext。

```gdscript
var spawn := SpawnSceneEffect.new()
spawn.effect_id = "effect.spawn_fireball"
spawn.scene_path = "res://game/projectiles/fireball.tscn"
spawn.parent_group = "projectiles"
spawn.position_offset = Vector2(16, 0)

var ctx := GameplayContext.new()
ctx.source = player
ctx.direction = Vector2.RIGHT
spawn.apply(ctx)
```

---

---

---

## 7.8 GrantItemEffect

### 概念说明

- 是什么：把物品实例加入目标背包的 Effect。
- 负责什么：创建 ItemInstance，查找 InventoryController，执行 can_add/add_item，并返回结构化结果。
- 为什么需要：奖励、宝箱、任务、掉落拾取和消耗品转换都可能给予物品；统一 Effect 可以避免 UI 或交互对象直接改背包。

```gdscript
class_name GrantItemEffect
extends GameEffect

@export var item_id: String = ""
@export var quantity: int = 1
@export var give_to_source: bool = true

func _apply_impl(context: GameplayContext) -> EffectResult:
    if item_id == "":
        return EffectResult.fail(effect_id, "Missing item_id")

    var receiver := context.source if give_to_source else context.target
    if receiver == null:
        return EffectResult.fail(effect_id, "Missing receiver")

    var inventory := receiver.get_node_or_null("Controllers/InventoryController") as InventoryController
    if inventory == null:
        return EffectResult.fail(effect_id, "Receiver has no InventoryController")

    var item := ItemInstance.create(item_id, quantity)
    if not inventory.can_add_item(item):
        return EffectResult.fail(effect_id, "Inventory cannot accept item: %s" % item_id)

    inventory.add_item(item)
    return EffectResult.ok(effect_id, {
        "item_id": item_id,
        "quantity": quantity,
        "instance_id": item.instance_id
    })
```

#### 字段说明
- **item_id**：物品定义 ID。例：item.potion_small。
- **quantity**：给予数量。例：奖励给 3 瓶小药水。
- **give_to_source**：接收者选择。例：奖励通常给 source，偷取类效果可以给 target。
#### 函数使用场景
- **_apply_impl()**：执行给物品。实际例子：RewardSystem 应用 RewardOption 时把物品加入玩家背包。

---

### 27.92 GrantItemEffect 使用示例

#### 详细实际用例

- 真实场景：宝箱奖励里有 `GrantItemEffect(item.potion_small, 3)`。玩家打开宝箱后，EffectExecutor 执行效果，InventoryController 负责堆叠或找空格。
- 怎么使用：Effect 只请求给物品；背包容量、堆叠和失败处理仍由 InventoryController 决定。
- 验证重点：满包时 EffectResult 失败且宝箱/奖励流程能保留未领取状态；成功时 inventory_changed 事件发出。

```gdscript
var grant := GrantItemEffect.new()
grant.effect_id = "effect.reward_potions"
grant.item_id = "item.potion_small"
grant.quantity = 3

var ctx := GameplayContext.new()
ctx.source = player
grant.apply(ctx)
```

---

---

---

## 7.9 ApplyStatModifierEffect

### 概念说明

- 是什么：把一个 StatModifier 应用到目标 StatsComponent 的 Effect。
- 负责什么：用配置创建运行时 StatModifier，加到 source 或 target 的 StatsComponent；支持永久（duration=-1）或限时。
- 为什么需要：roguelike 的核心奖励/升级（+20% attack、+10 max hp）都需要改属性；RewardDefinition 和 UpgradeDefinition 都依赖它。没有它，奖励循环无法落地。

`res://addons/mkit/kernel/effects/builtin/apply_stat_modifier_effect.gd`

```gdscript
class_name ApplyStatModifierEffect
extends GameEffect

@export var stat_id: String = ""
@export var operation: StatModifierDefinition.Operation = StatModifierDefinition.Operation.FLAT_ADD
@export var value: float = 0.0
@export var duration: float = -1.0 # -1 = 本局/永久（直到来源被移除）
@export var stacking_rule: StatModifierDefinition.StackingRule = StatModifierDefinition.StackingRule.STACK
@export var apply_to_source: bool = true

func _apply_impl(context: GameplayContext) -> EffectResult:
    if stat_id == "":
        return EffectResult.fail(effect_id, "Missing stat_id")

    var receiver := context.source if apply_to_source else context.target
    if receiver == null:
        return EffectResult.fail(effect_id, "Missing receiver for stat modifier")

    var stats := receiver.get_node_or_null("Components/StatsComponent") as StatsComponent
    if stats == null:
        return EffectResult.fail(effect_id, "Receiver has no StatsComponent")

    var mod_def := StatModifierDefinition.new()
    mod_def.modifier_id = effect_id if effect_id != "" else "mod.%s" % stat_id
    mod_def.stat_id = stat_id
    mod_def.operation = operation
    mod_def.value = value
    mod_def.stacking_rule = stacking_rule

    # source_id 用 modifier_id，方便卸下来源时按 source 移除（如限时 buff 过期）。
    var modifier := StatModifier.from_definition(mod_def, mod_def.modifier_id, duration)
    stats.add_modifier(modifier)
    return EffectResult.ok(effect_id, {"stat_id": stat_id, "value": value, "duration": duration})
```

#### 字段说明
- **stat_id**：要修改的属性。例：attack_power、max_hp、move_speed。
- **operation**：修改方式，复用 StatModifierDefinition.Operation。
- **value**：修改值。例：PERCENT_ADD + 0.20 表示 +20%。
- **duration**：持续时间，-1 表示本局永久（直到来源被移除）。
- **apply_to_source**：奖励通常作用于 source（玩家）；诅咒类可作用于 target。

#### 函数使用场景
- **_apply_impl()**：执行属性修改。实际例子：RewardSystem 应用 “+20% attack” 奖励、ProgressionSystem 应用永久升级效果。

---

### 27.100 ApplyStatModifierEffect 使用示例

#### 详细实际用例

- 真实场景：清房间后玩家选择 “Power Up”，RewardDefinition.effects 里就是一个 `ApplyStatModifierEffect(stat_id="attack_power", operation=PERCENT_ADD, value=0.20, duration=-1)`，应用到玩家本局属性。
- 怎么使用：奖励、升级、状态加成都用它写属性变化；不要让奖励直接改 base_stats 或绕过 StatsComponent。
- 验证重点：限时 buff 过期后属性恢复；同一来源重复应用遵循 stacking_rule。

```gdscript
var mod_effect := ApplyStatModifierEffect.new()
mod_effect.effect_id = "reward.attack_plus_20"
mod_effect.stat_id = "attack_power"
mod_effect.operation = StatModifierDefinition.Operation.PERCENT_ADD
mod_effect.value = 0.20
mod_effect.duration = -1.0

var ctx := GameplayContext.new()
ctx.source = player
mod_effect.apply(ctx)
```

---

