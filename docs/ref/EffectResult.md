# EffectResult

## 概念说明

EffectResult 是效果执行后的结构化结果。负责记录成功与否、失败原因、影响目标、数值、标签和调试信息。DebugOverlay、测试和战斗日志需要知道效果到底做了什么，而不是只看到 HP 变了。

## 设计目的

为每次 Effect 执行提供可检查的结果对象，确保调试和测试时能准确追踪效果是否按预期执行，失败时有明确的失败原因字符串。

## 文件

`res://addons/mkit/kernel/effects/effect_result.gd`

## 接口

```gdscript
class_name EffectResult
extends RefCounted

var success: bool = true
var effect_id: String = ""
var failure_reason: String = ""
var payload: Dictionary = {}
var child_results: Array[EffectResult] = []

static func ok(id: String = "", data: Dictionary = {}) -> EffectResult

static func fail(id: String, reason: String) -> EffectResult
```

## 函数使用场景

- **ok()**：创建成功结果，可附带 payload 数据。例：GrantItemEffect 成功后返回 `EffectResult.ok(effect_id, {"item_id": item_id, "quantity": quantity})`。
- **fail()**：创建失败结果，必须提供失败原因。例：目标没有 HealthComponent 时返回 `EffectResult.fail(effect_id, "Target has no HealthComponent")`。

## 使用示例

### 成功结果

```gdscript
var result := EffectResult.ok("grant_gold", {"gold": 20})
print(result.success)
print(result.payload["gold"])
```

### 失败结果

```gdscript
var failed := EffectResult.fail("deal_damage", "Target has no HealthComponent")
push_warning(failed.failure_reason)
```
