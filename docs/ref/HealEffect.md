# HealEffect

## 概念说明

HealEffect 是恢复生命值的内置 Effect。它通过 HealthComponent 应用治疗并产出事件和结果。药水、奖励、状态、治疗技能都需要同一条治疗路径。

## 设计目的

提供一个统一的治疗 Effect，使所有治疗来源（消耗品、技能、奖励）都通过 HealthComponent.heal() 执行，保证 UI 事件、满血限制和存档同步一致。

## 文件

`res://addons/mkit/kernel/effects/builtin/heal_effect.gd`

## 接口

```gdscript
class_name HealEffect
extends GameEffect

@export var amount: float = 1.0
@export var use_source_healing_multiplier: bool = true

func _apply_impl(context: GameplayContext) -> EffectResult: ...
```

## 函数使用场景

- **`_apply_impl(context)`**：内部实现方法。若 `use_source_healing_multiplier=true`，从 context.source 的 StatsComponent 读取 `healing_multiplier` 属性并乘以 amount，得到 final_amount；再调用 context.target 的 HealthComponent.heal(final_amount)。返回 EffectResult.ok 含实际治疗量，或 EffectResult.fail（缺少 target/HealthComponent）。

## 使用示例

```gdscript
var heal := HealEffect.new()
heal.effect_id = "effect.small_heal"
heal.amount = 30.0
heal.use_source_healing_multiplier = true

var ctx := GameplayContext.new()
ctx.source = player
ctx.target = player

var result := heal.apply(ctx)
print(result.payload) # {"amount": 30.0}
```
