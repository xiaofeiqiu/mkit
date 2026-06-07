# StatusEffectInstance

**层：** Module  
**文件：** `addons/mkit/modules/combat/status_effects/status_effect_instance.gd`  
**继承：** `extends RefCounted`

## 职责

某个状态在某个实体上的**运行时实例**：剩余时长、tick 计时、当前层数、来源。由 `StatusEffectController` 创建并每帧推进。

## 字段

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `instance_id` | `String` | `""` | 实例 id |
| `definition_id` | `String` | `""` | 对应 `status_id` |
| `source_id` | `String` | `""` | 施加者 id |
| `source` / `target` | `Node` | `null` | 施加者 / 承受者 |
| `remaining_duration` | `float` | `0.0` | 剩余时长 |
| `tick_timer` | `float` | `0.0` | 距下次 tick |
| `stacks` | `int` | `1` | 当前层数 |

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `setup(definition, source, target, initial_stacks, duration_override := -1.0)` | — | 初始化 |

## 相关

- → [StatusEffectDefinition](StatusEffectDefinition.md) · [StatusEffectController](StatusEffectController.md)
