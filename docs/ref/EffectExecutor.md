# EffectExecutor

## 概念说明

EffectExecutor 是 Effect 的统一执行器。负责按顺序执行效果，记录 trace，返回结果，并限制任意系统随意修改玩法状态。集中执行能让调试、回放、测试和数据驱动配置更可靠。

## 设计目的

作为 Effect 执行的统一入口，上层系统（AbilityController、RewardSystem、StatusEffectController）不直接循环调用各组件，而是将 Effect 列表交给 executor，由它负责记录追踪信息和处理失败逻辑。

## 文件

`res://addons/mkit/kernel/effects/effect_executor.gd`

## 字段说明

- **trace_enabled**：状态标记。例：用它判断当前对象是否已经处理过，避免重复触发。
- **recent_results**：代码字段。实际存在于当前实现中，供运行时或 Inspector 配置使用。
- **max_recent_results**：代码字段。实际存在于当前实现中，供运行时或 Inspector 配置使用。

## 接口

```gdscript
class_name EffectExecutor
extends RefCounted
var trace_enabled: bool = true
var recent_results: Array[EffectResult] = []
var max_recent_results: int = 100
func execute(effect: GameEffect, context: GameplayContext) -> EffectResult
func execute_many( effects: Array[GameEffect], context: GameplayContext, stop_on_failure: bool = false ) -> Array[EffectResult]
func clear_recent_results() -> void
```

> EffectExecutor 是 **RefCounted 轻量服务**（非生命周期服务），注册到 ServiceRegistry 但不挂入节点树。它没有 `_process`/信号，可被随意 `new()` 作为兜底或测试夹具（如 AbilityController / RewardSystem 在缺少 `effects` 服务时回退到 `EffectExecutor.new()`），因此不应改为 `Node`。`recent_results` 是有界的 trace 缓冲（`max_recent_results`，超出即 `pop_front`），需要回收时调用 `clear_recent_results()`。

## 函数使用场景

- **execute()**：执行单个 Effect。例：需要精确控制每个 Effect 执行时序时逐一调用。
- **execute_many()**：批量执行 Effect 列表。例：AbilityController 执行技能效果列表，RewardSystem 应用奖励效果列表。`stop_on_failure=true` 时遇到失败立即停止后续效果。
- **clear_recent_results()**：清空 `recent_results` trace 缓冲。例：场景/run 切换时回收旧的追踪记录，或测试用例之间重置。

## 使用示例

### 批量执行技能效果

```gdscript
var executor := ServiceRegistry.get_service("effects") as EffectExecutor
var ctx := GameplayContext.new()
ctx.source = player
ctx.target = enemy

var results := executor.execute_many(ability_def.effects, ctx, true)
for result in results:
    if not result.success:
        print("Effect failed: ", result.failure_reason)
```
