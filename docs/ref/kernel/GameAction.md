# GameAction

**层：** Kernel  
**文件：** `addons/mkit/kernel/actions/game_action.gd`  
**继承：** `extends RefCounted`

## 职责

带时序的行为单元。管理 start → update → complete/cancel 生命周期，钩子执行完毕后由 kernel 自动触发 effect 数组（data-driven），无需手动调 EffectService。

## 字段（public var）

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `action_id` | `String` | `""` | 动作标识，在 `_on_start` 中赋值 |
| `context` | `ActionContext` | `null` | 由 `ActionService.start_action` 传入，整条生命周期共享 |
| `elapsed` | `float` | `0.0` | 已运行时间（秒），每帧 `update` 累加 |
| `finished` | `bool` | `false` | `complete()` 后为 true |
| `cancelled_flag` | `bool` | `false` | `cancel()` 后为 true |
| `cancel_tags` | `Array[String]` | `[]` | 声明哪些 tag 可触发 cancel（如 `["stun","death"]`）|
| `on_start_effects` | `Array[GameEffect]` | `[]` | `_on_start` 完成后自动执行 |
| `on_complete_effects` | `Array[GameEffect]` | `[]` | `_on_complete` 完成后自动执行（+ `_resolve_effects` 结果）|
| `on_cancel_effects` | `Array[GameEffect]` | `[]` | `_on_cancel` 完成后自动执行（不含 `_resolve_effects`）|

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `start(ctx: ActionContext) -> void` | `void` | 由 ActionService 调用；执行 `_on_start` 并 `_fire_effects(on_start_effects + _resolve_effects)` |
| `update(delta: float) -> void` | `void` | 每帧由 ActionService 调用；内部调 `_on_update` |
| `complete() -> void` | `void` | 主动完成；执行 `_on_complete` + effects + 发 `completed` 信号 |
| `cancel(reason: String = "") -> void` | `void` | 主动取消；执行 `_on_cancel` + `on_cancel_effects` + 发 `cancelled` 信号 |
| `is_finished() -> bool` | `bool` | `finished or cancelled_flag` |
| `can_cancel_with(tag: String) -> bool` | `bool` | 检查 `cancel_tags` 是否包含该 tag |
| `_on_start() -> void` | `void` | **override**：动作开始时（播动画、设状态）|
| `_on_update(delta: float) -> void` | `void` | **override**：每帧逻辑（时序检测、触发 complete）|
| `_on_cancel(reason: String) -> void` | `void` | **override**：被取消时的清理 |
| `_on_complete() -> void` | `void` | **override**：完成时的清理 |
| `_resolve_effects(ctx: ActionContext) -> Array[GameEffect]` | `Array[GameEffect]` | **override**：运行时动态补充 effects（比静态数组更灵活）|

## 信号

| 信号名 | 参数 | 触发时机 |
|--------|------|----------|
| `completed` | `action: GameAction` | `complete()` 执行完 effects 后 |
| `cancelled` | `action: GameAction, reason: String` | `cancel()` 执行完 effects 后 |

## 使用模式

### 最小示例（Level 1）

```gdscript
# 最简单的延时动作（0.5 秒后触发效果）
var action := GameAction.new()
action.on_complete_effects = [my_deal_damage_effect]

var action_svc := Mkit.actions()
var ctx := ActionContext.new()
ctx.source = self
ctx.target = enemy
action_svc.start_action(action, ctx)
# ActionService 每帧 update，action 默认无 _on_update 实现，需手动 complete
action.complete()
```

### 典型场景（Level 2）

```gdscript
# 自定义带时序的动作：cast_time 内播动画，结束后执行效果
class_name SpellCastAction
extends GameAction

var duration: float = 0.8  # 咏唱时间


func _on_start() -> void:
    action_id = "spell_cast"
    cancel_tags = ["stun", "knockback", "death"]
    # 播放咏唱动画
    var anim := EntityContract.get_contract_node(context.source, "Presentation", "AnimationPlayer") as AnimationPlayer
    if anim != null and anim.has_animation("cast"):
        anim.play("cast")


func _on_update(delta: float) -> void:
    if elapsed >= duration:
        complete()          # 触发 on_complete_effects


func _on_cancel(reason: String) -> void:
    # 打断咏唱，停止动画
    var anim := EntityContract.get_contract_node(context.source, "Presentation", "AnimationPlayer") as AnimationPlayer
    if anim != null:
        anim.stop()


func _resolve_effects(_ctx: ActionContext) -> Array[GameEffect]:
    # 运行时根据目标距离动态选择效果
    var effects: Array[GameEffect] = []
    if _ctx.target != null:
        effects.append(deal_damage_effect)
    return effects
```

```gdscript
# 启动上面的动作
func _cast_spell(source: Node, target: Node) -> void:
    var action_svc := Mkit.actions()
    if action_svc == null:
        return

    var action := SpellCastAction.new()
    action.duration = 0.8

    var dmg := DealDamageEffect.new()
    dmg.effect_id = "spell_hit"
    dmg.base_amount = 40.0
    # on_complete_effects 也可以用 _resolve_effects 动态加，这里两者并用
    action.on_complete_effects = [dmg]

    var ctx := ActionContext.new()
    ctx.source = source
    ctx.target = target
    ctx.ability_id = "fireball"

    var started := action_svc.start_action(action, ctx)
    if started == null:
        push_error("Failed to start spell cast action")
        return

    started.completed.connect(func(_a: GameAction) -> void:
        print("Spell cast complete")
    )
    started.cancelled.connect(func(_a: GameAction, reason: String) -> void:
        print("Spell cast cancelled: %s" % reason)
    )
```

## 相关

- → [ActionService](ActionService.md) — 管理 Action 生命周期，每帧 update
- → [ActionContext](ActionContext.md) — 继承 GameplayContext，添加 action_id / duration / phase
- → [GameEffect](GameEffect.md) — on_complete_effects 中的效果类型
- → [pipeline.md — Ability Cast](../../pipeline.md#5-ability-cast)
- → [cookbook/04_attack_action.md](../../cookbook/04_attack_action.md)
