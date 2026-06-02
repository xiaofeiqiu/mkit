# ApplyStatusEffect

## 概念说明

ApplyStatusEffect 是给目标附加状态的内置 Effect。它通过 StatusEffectController 创建、刷新或叠加状态。燃烧、中毒、减速、护盾、眩晕等都需要统一的持续时间和叠加逻辑。

## 设计目的

提供一个可配置化的状态附加 Effect，使任何技能、装备或奖励都能通过配置 status_id 来附加状态，而不需要为每种状态写专用脚本；实际的叠加规则和生命周期由 StatusEffectController 和 StatusEffectDefinition 决定。

## 文件

`res://addons/mkit/kernel/effects/builtin/apply_status_effect.gd`

## 接口

```gdscript
class_name ApplyStatusEffect
extends GameEffect

@export var status_id: String = ""
@export var duration_override: float = -1.0
@export var stacks: int = 1

func _apply_impl(context: GameplayContext) -> EffectResult: ...
```

## 函数使用场景

- **`_apply_impl(context)`**：内部实现方法。从 context.target 获取 StatusEffectController，调用 controller.apply_status(status_id, context.source, stacks, duration_override)，返回成功或失败的 EffectResult。`duration_override=-1` 表示使用 StatusEffectDefinition 中配置的默认持续时间。

## 使用示例

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
