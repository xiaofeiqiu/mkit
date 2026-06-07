# EffectService

**层：** Kernel  
**文件：** `addons/mkit/kernel/effects/effect_service.gd`  
**继承：** `extends RefCounted`  
**服务 ID：** `"effects"`

## 职责

Effect 执行链调度器。接受单个或多个 `GameEffect`，依次调 `effect.apply(context)`，记录结果供调试。通常不需要直接调用——`GameAction._fire_effects` 已内部使用它；直接调用适用于无 Action 的一次性效果。

## 字段（public var）

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `trace_enabled` | `bool` | `true` | 开启时每次执行都记录到 `recent_results` |
| `recent_results` | `Array[EffectResult]` | `[]` | 最近 100 条执行结果（调试用）|
| `max_recent_results` | `int` | `100` | `recent_results` 的容量上限 |

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `execute(effect: GameEffect, context: GameplayContext) -> EffectResult` | `EffectResult` | 执行单个 Effect |
| `execute_many(effects: Array[GameEffect], context: GameplayContext, stop_on_failure: bool = false) -> Array[EffectResult]` | `Array[EffectResult]` | 顺序执行多个 Effect；`stop_on_failure=true` 时第一个失败即停止 |
| `clear_recent_results() -> void` | `void` | 清空调试记录 |

## 使用模式

### 最小示例（Level 1）

```gdscript
var effects_svc := ServiceRegistry.get_port(ServiceRegistry.SERVICE_EFFECTS) as EffectService
var ctx := GameplayContext.new()
ctx.source = self
ctx.target = enemy
var result := effects_svc.execute(deal_damage_effect, ctx)
```

### 典型场景（Level 2）

```gdscript
# 直接触发一次性伤害（不走 Action）
func _apply_instant_damage(source: Node, target: Node, amount: float) -> bool:
    var effects_svc := ServiceRegistry.get_port(ServiceRegistry.SERVICE_EFFECTS) as EffectService
    if effects_svc == null:
        push_error("EffectService not available")
        return false

    var dmg := DealDamageEffect.new()
    dmg.effect_id   = "instant_damage"
    dmg.base_amount = amount
    dmg.damage_type = "true"   # 无视防御

    var ctx := GameplayContext.new()
    ctx.source = source
    ctx.target = target

    var result := effects_svc.execute(dmg, ctx)
    if not result.success:
        push_warning("Instant damage failed: %s" % result.failure_reason)
        return false
    return true


# 链式效果（治疗 + buff，任意一个失败都继续）
func _apply_heal_and_buff(target: Node) -> void:
    var effects_svc := ServiceRegistry.get_port(ServiceRegistry.SERVICE_EFFECTS) as EffectService
    if effects_svc == null:
        return

    var heal := HealEffect.new()
    heal.effect_id  = "potion_heal"
    heal.base_amount = 30.0

    var buff := ApplyBuffEffect.new()
    buff.effect_id  = "potion_buff"
    buff.stat_id    = "defense"
    buff.flat_bonus = 5.0
    buff.duration   = 10.0

    var ctx := GameplayContext.new()
    ctx.source = target
    ctx.target = target

    var results := effects_svc.execute_many([heal, buff], ctx, false)
    for r in results:
        if not r.success:
            push_warning("Effect '%s' failed: %s" % [r.effect_id, r.failure_reason])


# 调试：查看最近执行结果
func _debug_recent_effects() -> void:
    var effects_svc := ServiceRegistry.get_port(ServiceRegistry.SERVICE_EFFECTS) as EffectService
    if effects_svc == null:
        return
    for result in effects_svc.recent_results:
        print("[%s] success=%s %s" % [
            result.effect_id,
            result.success,
            "" if result.success else ("reason=" + result.failure_reason)
        ])
```

## 相关

- → [GameEffect](GameEffect.md) — Effect 基类
- → [EffectResult](EffectResult.md) — 执行结果对象
- → [GameAction](GameAction.md) — `_fire_effects` 内部使用 EffectService
- → [pipeline.md — Effect Execution](../../pipeline.md#6-effect-execution)
- → [debugging.md](../../debugging.md#effectservice-trace) — 用 recent_results 定位效果不生效
