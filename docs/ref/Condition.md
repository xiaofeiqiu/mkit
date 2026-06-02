# Condition

## 概念说明

Condition 是可复用的真假规则。负责判断技能能不能放、状态能不能切、奖励能不能出现、掉落项能不能进入候选池等。把规则做成 Resource 后，技能、装备、奖励、AI 都能共享同一套检查逻辑。

## 设计目的

作为所有可配置条件的基类 Resource，通过 `invert` 字段支持取反，通过 `get_failure_reason` 方法提供可读的失败原因。子类只需覆盖 `_evaluate_impl` 实现具体规则。

## 文件

`res://addons/mkit/kernel/conditions/condition.gd`

## 接口

```gdscript
class_name Condition
extends Resource

@export var condition_id: String = ""
@export var invert: bool = false

func evaluate(context: GameplayContext) -> bool

func _evaluate_impl(context: GameplayContext) -> bool

func get_failure_reason(context: GameplayContext) -> String
```

## 函数使用场景

- **evaluate()**：对外暴露的评估入口，会处理 invert 逻辑。例：AbilityController 释放火球前对每个条件调用 evaluate，只有全部返回 true 才允许施法。
- **get_failure_reason()**：返回可读的失败原因字符串。例：UI 显示"冷却未完成"或"目标超出范围"，帮助玩家理解为什么技能无法释放。

## 使用示例

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

### 挂载到 AbilityDefinition

```gdscript
var condition := HasTagCondition.new()
condition.required_tag = "enemy"
fireball_definition.conditions.append(condition)
```
