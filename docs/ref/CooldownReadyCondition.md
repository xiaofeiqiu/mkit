# CooldownReadyCondition

## 概念说明

CooldownReadyCondition 是检查技能冷却是否就绪的条件。读取目标实体 AbilityController 中指定技能的冷却状态。冷却是最常见的技能门槛，统一条件能避免每个技能自己写一遍检查逻辑。

## 设计目的

将冷却检查封装为可配置的 Condition Resource，与 AbilityDefinition.conditions 配合使用，确保所有技能使用统一的冷却检查路径。

## 文件

`res://addons/mkit/kernel/conditions/builtin/cooldown_ready_condition.gd`

## 接口

```gdscript
class_name CooldownReadyCondition
extends Condition

@export var ability_id: String = ""

func _evaluate_impl(context: GameplayContext) -> bool

func get_failure_reason(context: GameplayContext) -> String
```

## 函数使用场景

- **_evaluate_impl()**：内部实现，从 context.source 获取 AbilityController 并检查冷却。若 ability_id 为空则从 context.ability_id 读取。
- **get_failure_reason()**：返回冷却未就绪的具体技能 ID，用于 UI 显示。

## 使用示例

### 单独使用

```gdscript
var condition := CooldownReadyCondition.new()
condition.ability_id = "ability.fireball_basic"

var ctx := GameplayContext.new()
ctx.source = player

if condition.evaluate(ctx):
    print("Fireball is ready")
```

### 配置到 AbilityDefinition

```gdscript
var cooldown_cond := CooldownReadyCondition.new()
# ability_id 留空则自动从 context.ability_id 读取
fireball_definition.conditions.append(cooldown_cond)
```
