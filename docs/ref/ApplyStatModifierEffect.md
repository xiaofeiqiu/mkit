# ApplyStatModifierEffect

## 概念说明

ApplyStatModifierEffect 是把一个 StatModifier 应用到目标 StatsComponent 的内置 Effect。它用配置创建运行时 StatModifier，加到 source 或 target 的 StatsComponent；支持永久（duration=-1）或限时。roguelike 的核心奖励/升级（+20% attack、+10 max hp）都需要改属性；RewardDefinition 和 UpgradeDefinition 都依赖它。

## 设计目的

提供一个配置化的属性修改 Effect，使奖励、升级和 Buff 都通过同一个 Effect 修改属性，确保所有属性变化走 StatsComponent 的 modifier 系统，支持持续时间到期后自动恢复。

## 文件

`res://addons/mkit/kernel/effects/builtin/apply_stat_modifier_effect.gd`

## 字段说明

- **stat_id**：要修改的属性。例：attack_power、max_hp、move_speed。
- **operation**：修改方式，复用 StatModifierDefinition.Operation。
- **value**：修改值。例：PERCENT_ADD + 0.20 表示 +20%。
- **duration**：持续时间，-1 表示本局永久（直到来源被移除）。
- **stacking_rule**：代码字段。叠加规则。
- **apply_to_source**：奖励通常作用于 source（玩家）；诅咒类可作用于 target。

## 接口

```gdscript
class_name ApplyStatModifierEffect
extends GameEffect
@export var stat_id: String = ""
@export var operation: StatModifierDefinition.Operation = StatModifierDefinition.Operation.FLAT_ADD
@export var value: float = 0.0
@export var duration: float = -1.0
@export var stacking_rule: StatModifierDefinition.StackingRule = StatModifierDefinition.StackingRule.STACK
@export var apply_to_source: bool = true
```

## 函数使用场景

- **`_apply_impl(context)`**：内部实现方法。根据 `apply_to_source` 决定接收者（source 或 target），查找其 StatsComponent，动态创建 StatModifierDefinition 和 StatModifier，通过 stats.add_modifier() 添加。返回含 stat_id、value、duration 的 EffectResult.ok，或在缺少接收者/StatsComponent 时返回 EffectResult.fail。`duration=-1` 表示本局永久（直到来源被移除）。

## 使用示例

### 清房间奖励：永久攻击加成

```gdscript
var mod_effect := ApplyStatModifierEffect.new()
mod_effect.effect_id = "reward.attack_plus_20"
mod_effect.stat_id = "attack_power"
mod_effect.operation = StatModifierDefinition.Operation.PERCENT_ADD
mod_effect.value = 0.20
mod_effect.duration = -1.0
mod_effect.apply_to_source = true

var ctx := GameplayContext.new()
ctx.source = player
mod_effect.apply(ctx)
```

### 限时 buff：5 秒攻击加速

```gdscript
var speed_buff := ApplyStatModifierEffect.new()
speed_buff.stat_id = "attack_speed"
speed_buff.operation = StatModifierDefinition.Operation.PERCENT_ADD
speed_buff.value = 0.50
speed_buff.duration = 5.0
```
