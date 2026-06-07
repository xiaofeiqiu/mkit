# Condition

**层：** Kernel  
**文件：** `addons/mkit/kernel/conditions/condition.gd`  
**继承：** `extends Resource`

## 职责

可配置布尔判定的基类。`GameEffect`、`AbilityDefinition`、`DialogueChoice`、`LootEntry`、`ShopEntry` 等都用 `Array[Condition]` 做门槛。子类只需 override `_evaluate_impl`。

## 字段

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `condition_id` | `String`（@export）| `""` | 标识 |
| `invert` | `bool`（@export）| `false` | 为真时对结果取反 |

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `evaluate(context: GameplayContext) -> bool` | `bool` | 调 `_evaluate_impl`，再按 `invert` 取反 |
| `_evaluate_impl(context) -> bool` | `bool` | **子类实现**，默认 `true` |
| `get_failure_reason(context) -> String` | `String` | 失败原因（子类可 override 给更具体的文案）|

## 使用模式

### 最小示例（Level 1）

```gdscript
class_name HasTagCondition
extends Condition

@export var required_tag: String = ""

func _evaluate_impl(context: GameplayContext) -> bool:
    return context.has_tag(required_tag)

func get_failure_reason(_context: GameplayContext) -> String:
    return "missing_tag:%s" % required_tag
```

## 相关

- → [ConditionEvaluator](ConditionEvaluator.md)（批量求值）· [TargetInRangeCondition](TargetInRangeCondition.md)（内置示例）
- → [GameEffect](GameEffect.md)（`conditions` 字段）
