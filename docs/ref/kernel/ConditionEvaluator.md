# ConditionEvaluator

**层：** Kernel  
**文件：** `addons/mkit/kernel/conditions/condition_evaluator.gd`  
**继承：** `extends RefCounted`（纯静态工具）

## 职责

对一组 `Condition` 做"全部通过"判定，并能收集所有失败原因。框架内几乎所有"条件门槛"都走它。

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `static evaluate_all(conditions: Array[Condition], context) -> bool` | `bool` | 全部通过才返回 `true`（空数组视为通过）|
| `static collect_failures(conditions, context) -> Array[String]` | `Array[String]` | 返回每个未通过条件的 `get_failure_reason` |

## 使用模式

### 最小示例（Level 1）

```gdscript
if not ConditionEvaluator.evaluate_all(definition.conditions, ctx):
    var reasons := ConditionEvaluator.collect_failures(definition.conditions, ctx)
    push_warning("条件不满足: %s" % ", ".join(reasons))
```

## 相关

- → [Condition](Condition.md)（单条判定）
- → [GameEffect](GameEffect.md)（`apply` 内部调用它）· [ref/modules/AbilityController.md](../modules/AbilityController.md)
