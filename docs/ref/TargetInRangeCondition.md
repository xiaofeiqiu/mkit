# TargetInRangeCondition

## 概念说明

TargetInRangeCondition 是检查目标距离的条件。比较 context.source 和 context.target 的 global_position 距离与配置范围。攻击、互动、AI 决策和技能都需要距离检查，统一实现能保证行为一致。

## 设计目的

将距离检查封装为可配置的 Condition Resource，通过 range 字段设置有效范围，确保不同系统（技能、互动、AI）使用相同的距离判定逻辑。

## 文件

`res://addons/mkit/kernel/conditions/builtin/target_in_range_condition.gd`

## 字段说明

- **range**：作用范围。例：近战技能 range=48，火球 range=600。

## 接口

```gdscript
class_name TargetInRangeCondition
extends Condition
@export var range: float = 64.0
func get_failure_reason(context: GameplayContext) -> String
```

## 函数使用场景

- **_evaluate_impl()**：计算 source 与 target 的距离，与 range 比较。若 source 或 target 为空则返回 false。

## 使用示例

### 检查敌人是否在近战范围内

```gdscript
var condition := TargetInRangeCondition.new()
condition.range = 96.0

var ctx := GameplayContext.new()
ctx.source = player
ctx.target = enemy

if condition.evaluate(ctx):
    print("Enemy is in range")
```
