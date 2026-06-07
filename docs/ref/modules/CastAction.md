# CastAction

**层：** Module  
**文件：** `addons/mkit/modules/combat/abilities/cast_action.gd`  
**继承：** `extends GameAction`

## 职责

读条施法动作。当 `AbilityDefinition.cast_time > 0` 时，`AbilityController` 用它来表示"吟唱中"：播 `"cast"` 动画，计时到 `duration` 后 `complete()`，由 kernel 自动触发 `on_complete_effects`（即技能 effects）。期间可被 `cancel_tags`（stun/death/silence）打断。

## 字段

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `duration` | `float` | `0.0` | 读条时长（= `cast_time`）|
| `animation_name` | `String` | `"cast"` | 播放的动画名 |

继承自 `GameAction` 的 `on_complete_effects` / `cancel_tags` / `elapsed` 等同样可用。

## 方法

继承 `GameAction` 的生命周期钩子（`_on_start` 播动画、`_on_update` 计时到点 `complete`、`_on_cancel`/`_on_complete` 停止反馈）。

## 使用模式

### 最小示例（Level 1）

```gdscript
# 通常由 AbilityController 自动创建；手动用法：
var cast := CastAction.new()
cast.duration = 1.5
cast.on_complete_effects = ability_def.effects
(ServiceRegistry.get_service("actions") as ActionService).start_action(cast, action_ctx)
```

## 相关

- → [GameAction](../kernel/GameAction.md)（基类）· [AbilityController](AbilityController.md)（创建它）
- → [pipeline.md — Ability Cast](../../pipeline.md#5-ability-cast)
