# AbilityController

**层：** Module  
**文件：** `addons/mkit/modules/combat/abilities/ability_controller.gd`  
**继承：** `extends SaveableComponent`

## 职责

实体的技能管理控制器，挂在 `Controllers/AbilityController`。负责注册技能、检查施放条件/消耗、走冷却，并把施放桥接到 `ActionService`（有 `cast_time`）或瞬发 `GameAction`。是 State 与 Action/Effect 之间的桥。

## 字段

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `starting_ability_ids` | `Array[String]`（@export）| `[]` | `_ready` 时自动注册的技能 |
| `abilities` | `Dictionary` | `{}` | `ability_id → AbilityInstance` |

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `register_ability(ability_id) -> bool` | `bool` | 拉 definition 建 instance；失败返回 false |
| `can_cast(ability_id, context) -> bool` | `bool` | 是否可施放 |
| `get_cast_failure_reason(ability_id, context) -> String` | `String` | 失败原因（空串=可施放）|
| `cast(ability_id, context) -> bool` | `bool` | 施放；失败发 `ability_failed` |
| `is_cooldown_ready(ability_id) -> bool` | `bool` | 冷却是否就绪 |
| `get_cooldown_remaining(ability_id) -> float` | `float` | 剩余冷却 |

## 信号

| 信号名 | 参数 | 触发时机 |
|--------|------|----------|
| `ability_registered` | `ability_id` | 注册成功 |
| `ability_cast_started` | `ability_id` | 开始施放（扣费后）|
| `ability_cast_finished` | `ability_id` | 施放完成（瞬发/CastAction 完成）|
| `ability_failed` | `ability_id, reason` | 施放失败 |
| `cooldown_started` | `ability_id, duration` | 进入冷却 |

## 使用模式

### 最小示例（Level 1）

```gdscript
var ctrl := player.get_node("Controllers/AbilityController") as AbilityController
var ctx := GameplayContext.new()
ctx.source = player
ctx.target = enemy
ctx.ability_id = "fireball"
ctrl.cast("fireball", ctx)
```

### 典型场景（Level 2）

```gdscript
# 在 State 里施放，覆盖成功与失败两条路径
func _try_cast(ability_id: String, target: Node) -> bool:
    var ctrl := owner_entity.get_node_or_null("Controllers/AbilityController") as AbilityController
    if ctrl == null:
        return false
    var ctx := GameplayContext.new()
    ctx.source = owner_entity
    ctx.target = target
    ctx.ability_id = ability_id
    # 先问原因，给玩家明确反馈
    var reason := ctrl.get_cast_failure_reason(ability_id, ctx)
    if reason != "":
        # on_cooldown / insufficient_mana / not_registered / 条件失败文案
        print("无法施放: %s" % reason)
        return false
    return ctrl.cast(ability_id, ctx)


func _ready() -> void:
    var ctrl := owner_entity.get_node_or_null("Controllers/AbilityController") as AbilityController
    if ctrl != null:
        ctrl.ability_failed.connect(func(id: String, reason: String):
            push_warning("%s 施放失败: %s" % [id, reason])
        )
```

> 存档：`AbilityController` 是 `SaveableComponent`，`to_save_data` 存已学技能与冷却，但需由 `Saveable` 代理收集（见 [SaveableComponent](../kernel/SaveableComponent.md)）。

## 相关

- → [AbilityDefinition](AbilityDefinition.md) · [AbilityInstance](AbilityInstance.md) · [CastAction](CastAction.md)
- → [cookbook/05_ability.md](../../cookbook/05_ability.md) · [pipeline.md — Ability Cast](../../pipeline.md#5-ability-cast)
