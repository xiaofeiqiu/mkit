# TargetInRangeCondition

**层：** Kernel  
**文件：** `addons/mkit/kernel/conditions/builtin/target_in_range_condition.gd`  
**继承：** `extends Condition`

## 职责

内置条件：判断 `context.source` 与 `context.target` 的 2D 距离是否在 `range` 内。常用于技能/攻击的射程门槛。

## 字段

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `range` | `float`（@export）| `64.0` | 最大距离（像素）|

继承自 `Condition` 的 `condition_id` / `invert` 同样可用。

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `_evaluate_impl(context) -> bool` | `bool` | source/target 均为 `Node2D` 且距离 ≤ `range` 才为真 |
| `get_failure_reason(context) -> String` | `String` | 返回 `"target_out_of_range"` |

## 使用模式

### 最小示例（Level 1）

```gdscript
# 在 .tres 里配到 AbilityDefinition.conditions，或代码构造：
var cond := TargetInRangeCondition.new()
cond.range = 96.0
ability_def.conditions = [cond]
```

## 相关

- → [Condition](Condition.md) · [ConditionEvaluator](ConditionEvaluator.md)
- → [ref/modules/AbilityDefinition.md](../modules/AbilityDefinition.md)
