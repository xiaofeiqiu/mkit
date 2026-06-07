# ActionService

**层：** Kernel  
**文件：** `addons/mkit/kernel/actions/action_service.gd`  
**继承：** `extends Node`  
**服务 ID：** `"actions"`

## 职责

管理所有活跃 `GameAction` 的生命周期：注册、每帧 update、完成/取消后清理。是 kernel 内部的 Action 调度器，上层代码通过它启动 Action，无需手动管理 `active_actions`。

## 字段（public var）

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `active_actions` | `Array[GameAction]` | `[]` | 当前所有活跃 Action（只读，勿直接修改）|

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `start_action(action: GameAction, context: ActionContext) -> GameAction` | `GameAction` | 注册 Action，调 `action.start(context)`，发 `action_started` 信号；返回 null 表示参数无效 |
| `cancel_actions_for_source(source: Node, reason: String = "") -> void` | `void` | 取消指定 source 的所有活跃 Action（如实体死亡时）|

## 信号

| 信号名 | 参数 | 触发时机 |
|--------|------|----------|
| `action_started` | `action: GameAction` | `start_action` 成功后 |
| `action_completed` | `action: GameAction` | Action 自然完成后（非 cancel）|
| `action_cancelled` | `action: GameAction, reason: String` | Action 被取消后 |

## 使用模式

### 最小示例（Level 1）

```gdscript
var action_svc := ServiceRegistry.get_service("actions") as ActionService
var ctx := ActionContext.new()
ctx.source = self
action_svc.start_action(TimedAttackAction.new(), ctx)
```

### 典型场景（Level 2）

```gdscript
func _start_attack_action(source: Node, target: Node) -> void:
    var action_svc := ServiceRegistry.get_service("actions") as ActionService
    if action_svc == null:
        push_error("ActionService not available")
        return

    var attack := TimedAttackAction.new()
    attack.startup_duration  = 0.12
    attack.active_duration   = 0.10
    attack.recovery_duration = 0.25

    var dmg := DealDamageEffect.new()
    dmg.effect_id   = "melee_hit"
    dmg.base_amount = 20.0
    attack.on_complete_effects = [dmg]

    var ctx := ActionContext.new()
    ctx.source = source
    ctx.target = target
    ctx.ability_id = "melee_attack"

    var action := action_svc.start_action(attack, ctx)
    if action == null:
        push_error("Failed to start attack action — context or action was null")
        return

    action.completed.connect(func(_a: GameAction) -> void:
        print("Attack complete")
    )
    action.cancelled.connect(func(_a: GameAction, reason: String) -> void:
        print("Attack cancelled: %s" % reason)
    )


func _on_entity_died(entity: Node) -> void:
    # 实体死亡时取消所有在途 Action
    var action_svc := ServiceRegistry.get_service("actions") as ActionService
    if action_svc != null:
        action_svc.cancel_actions_for_source(entity, "death")
```

## 相关

- → [GameAction](GameAction.md) — Action 基类和生命周期钩子
- → [ActionContext](ActionContext.md) — 传入 start_action 的上下文对象
- → [pipeline.md — Main Gameplay Loop](../../pipeline.md#2-main-gameplay-loop)
- → [cookbook/04_attack_action.md](../../cookbook/04_attack_action.md)
