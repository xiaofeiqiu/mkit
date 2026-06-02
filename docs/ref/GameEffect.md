# GameEffect

## 概念说明

GameEffect 是声明式玩法结果的基类 Resource。负责表达伤害、治疗、上状态、生成场景、给予物品、修改属性等结果。技能、物品、奖励和状态都可以组合 Effect，减少一次性脚本。

## 设计目的

将"会发生什么"配置为 Effect Resource，与"什么时候发生"分离（由 Action 或 AbilityController 决定触发时机）。Effect 通过内置的条件检查决定是否执行，子类只需覆盖 `_apply_impl`。

## 文件

`res://addons/mkit/kernel/effects/game_effect.gd`

## 接口

```gdscript
class_name GameEffect
extends Resource

@export var effect_id: String = ""
@export var conditions: Array[Condition] = []
@export var tags: Array[String] = []

func apply(context: GameplayContext) -> EffectResult

func _apply_impl(context: GameplayContext) -> EffectResult
```

## 函数使用场景

- **apply()**：对外暴露的执行入口，先检查所有条件，条件不满足时返回失败结果，通过时调用 `_apply_impl`。例：EffectExecutor 执行每个 Effect 时调用此方法。
- **_apply_impl()**：子类覆盖实现具体效果逻辑。例：DealDamageEffect 覆盖此方法创建 DamageRequest 并交给 CombatResolver。

## 使用示例

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
