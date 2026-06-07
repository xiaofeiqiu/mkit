# TimedAttackAction

**层：** Module  
**文件：** `addons/mkit/modules/combat/actions/timed_attack_action.gd`  
**继承：** `extends GameAction`

## 职责

带 startup / active / recovery 三段时序的近战攻击。`_on_start` 播 `"attack"` 动画；`_on_update` 在 active 窗口内开启 `HitboxComponent`，窗口外关闭；总时长结束 `complete()`，触发 `on_complete_effects`。

## 字段

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `startup_duration` | `float` | `0.12` | 前摇 |
| `active_duration` | `float` | `0.10` | 判定生效 |
| `recovery_duration` | `float` | `0.25` | 后摇 |
| `hitbox_path` | `NodePath` | `NodePath("")` | 优先按此路径在 source 上查找 `HitboxComponent`；为空则按组件名回退 |
| `hitbox_component_name` | `StringName` | `"HitboxComponent"` | `hitbox_path` 为空时使用的兼容字段 |

继承 `GameAction` 的 `on_complete_effects` / `cancel_tags`（默认 `["dash","stun","death"]`）。

## 时序

```
0 ───startup───┃───active───┃───recovery───┃ → complete()
               ↑ Hitbox on  ↑ Hitbox off
```

## 使用模式

### 最小示例（Level 1）

```gdscript
var attack := TimedAttackAction.new()
attack.startup_duration = 0.15
attack.active_duration = 0.12
attack.recovery_duration = 0.35
# 建议显式用 path；不配则回退 hitbox_component_name
attack.hitbox_path = NodePath("Components/HitboxComponent")
var dmg := DealDamageEffect.new()
dmg.base_amount = 12.0
attack.on_complete_effects = [dmg]
```

> 兼容说明：`hitbox_path` 在旧场景兼容逻辑下可留空，默认会尝试从 `hitbox_component_name`（默认 `"HitboxComponent"`）查找组件。

## 相关

- → [GameAction](../kernel/GameAction.md) · [HitboxComponent](HitboxComponent.md)
- → [cookbook/04_attack_action.md](../../cookbook/04_attack_action.md) · [pipeline.md — Animation（通道 A）](../../pipeline.md#10-animation--action-驱动通道)
