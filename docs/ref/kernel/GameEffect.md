# GameEffect

**层：** Kernel  
**文件：** `addons/mkit/kernel/effects/game_effect.gd`  
**继承：** `extends Resource`

## 职责

Effect 系统的抽象基类。`apply()` 先评估 conditions，通过后调 `_apply_impl()`。具体效果逻辑全部在 module 子类的 `_apply_impl` 中实现，kernel 只负责调度和结果包装。

## 字段（@export 和 public var）

| 字段名 | 类型 | 默认值 | 说明（由谁写/读）|
|--------|------|--------|------|
| `effect_id` | `String` | `""` | 效果唯一标识，出现在 `EffectResult` 中（你设；EffectService 读）|
| `conditions` | `Array[Condition]` | `[]` | 执行前检查的条件列表；任一失败则返回 fail result |
| `tags` | `Array[String]` | `[]` | 效果分类标签，供过滤/日志使用 |

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `apply(context: GameplayContext) -> EffectResult` | `EffectResult` | 由 EffectService 调用；先 condition 检查，后 `_apply_impl` |
| `_apply_impl(context: GameplayContext) -> EffectResult` | `EffectResult` | **override**：实际效果逻辑；默认返回 `EffectResult.ok(effect_id)` |

## 使用模式

### 最小示例（Level 1）

```gdscript
# 最简单的自定义效果：打印日志
class_name PrintMessageEffect
extends GameEffect

@export var message: String = "effect triggered"

func _apply_impl(context: GameplayContext) -> EffectResult:
    print("[%s] %s" % [effect_id, message])
    return EffectResult.ok(effect_id)
```

### 典型场景（Level 2）

```gdscript
# 带条件检查的自定义效果：只对有 StatsComponent 的目标加 buff
class_name ApplyBuffEffect
extends GameEffect

@export var stat_id: String = "attack_power"
@export var flat_bonus: float = 10.0
@export var duration: float = 5.0


func _apply_impl(context: GameplayContext) -> EffectResult:
    var target := context.target
    if target == null:
        return EffectResult.fail(effect_id, "no_target")

    var stats := target.get_node_or_null("Components/StatsComponent") as StatsComponent
    if stats == null:
        return EffectResult.fail(effect_id, "no_stats_component")

    var modifier := StatModifier.new()
    modifier.modifier_id  = "%s_buff_%d" % [effect_id, Time.get_ticks_usec()]
    modifier.stat_id      = stat_id
    modifier.operation    = StatModifierDefinition.Operation.FLAT_ADD
    modifier.value        = flat_bonus
    modifier.remaining_duration = duration  # ≤ 0 表示永久
    stats.add_modifier(modifier)

    return EffectResult.ok(effect_id, {
        "stat_id":   stat_id,
        "bonus":     flat_bonus,
        "duration":  duration
    })
```

```gdscript
# 在 GameAction 中使用自定义 Effect
func _setup_action() -> void:
    var buff := ApplyBuffEffect.new()
    buff.effect_id  = "attack_buff"
    buff.stat_id    = "attack_power"
    buff.flat_bonus = 10.0
    buff.duration   = 5.0

    var action := GameAction.new()
    action.on_complete_effects = [buff]

    var action_svc := ServiceRegistry.get_service("actions") as ActionService
    var ctx := ActionContext.new()
    ctx.source = self
    ctx.target = self       # 给自己加 buff
    action_svc.start_action(action, ctx)
    action.complete()
```

## 相关

- → [EffectService](EffectService.md) — execute / execute_many
- → [EffectResult](EffectResult.md) — ok / fail / 数据字段
- → [GameplayContext](GameplayContext.md) — source / target / amount / tags
- → [Condition](Condition.md) — conditions 字段的类型
- → [pipeline.md — Effect Execution](../../pipeline.md#6-effect-execution)
- → [concepts.md — 模型 5：扩展点地图](../../concepts.md#模型-5扩展点地图你写什么--mkit-管什么)
