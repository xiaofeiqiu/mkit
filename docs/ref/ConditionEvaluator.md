# ConditionEvaluator

## 概念说明

ConditionEvaluator 是条件列表的统一评估器。负责执行 all/any 规则，收集失败原因，并支持调试输出。当技能不能释放或奖励没出现时，开发者需要知道具体是哪条规则失败。

## 设计目的

提供静态方法，避免每个系统自己实现条件循环。统一的收集失败原因方法让 UI 可以显示有意义的错误提示，而不是只有一个"失败"状态。

## 文件

`res://addons/mkit/kernel/conditions/condition_evaluator.gd`

## 接口

```gdscript
class_name ConditionEvaluator
extends RefCounted
static func evaluate_all(conditions: Array[Condition], context: GameplayContext) -> bool
static func collect_failures( conditions: Array[Condition], context: GameplayContext ) -> Array[String]
```

## 函数使用场景

- **evaluate_all()**：对条件列表执行 AND 逻辑。例：AbilityController 释放火球前一次性检查所有条件（冷却、mana、距离），只要有一个不满足就返回 false。
- **collect_failures()**：收集所有不满足条件的失败原因。例：返回 ["冷却未完成: ability.fireball_basic", "目标超出范围"] 供 UI 显示最重要的一条。

## 使用示例

### 检查是否可以释放技能

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
