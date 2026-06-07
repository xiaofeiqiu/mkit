# EffectResult

**层：** Kernel  
**文件：** `addons/mkit/kernel/effects/effect_result.gd`  
**继承：** `extends RefCounted`

## 职责

`GameEffect.apply()` 的返回值，表示一次效果执行的成功/失败与附加产出。`EffectService.recent_results` 缓存它们供调试。

## 字段

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `success` | `bool` | `true` | 是否成功 |
| `effect_id` | `String` | `""` | 来源 effect 的 id |
| `failure_reason` | `String` | `""` | 失败原因（`success=false` 时）|
| `payload` | `Dictionary` | `{}` | 成功时的产出（如 `{"final_amount": 30}`）|
| `child_results` | `Array[EffectResult]` | `[]` | 子结果（组合 effect 用）|

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `static ok(id="", data={})` | `EffectResult` | 构造成功结果 |
| `static fail(id, reason)` | `EffectResult` | 构造失败结果 |

## 使用模式

### 最小示例（Level 1）

```gdscript
# 在自定义 GameEffect._apply_impl 里
func _apply_impl(context: GameplayContext) -> EffectResult:
    if context.target == null:
        return EffectResult.fail(effect_id, "no_target")
    return EffectResult.ok(effect_id, {"applied": true})
```

```gdscript
# 调用方检查结果
var r := effects.execute(my_effect, ctx)
if not r.success:
    push_warning("effect 失败: %s" % r.failure_reason)
```

## 相关

- → [GameEffect](GameEffect.md)（返回它）· [EffectService](EffectService.md)（缓存它）
- → [pipeline.md — Effect Execution](../../pipeline.md#6-effect-execution)
