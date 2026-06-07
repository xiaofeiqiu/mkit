# SpawnSceneEffect

**层：** Kernel  
**文件：** `addons/mkit/kernel/effects/builtin/spawn_scene_effect.gd`  
**继承：** `extends GameEffect`

## 职责

内置效果：在当前场景实例化一个 `PackedScene`（投射物、爆炸、掉落…），可选用 `PoolService` 取用，并按 source/target 定位与朝向。

## 字段

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `scene_path` | `String`（@export）| `""` | 要生成的场景路径 |
| `spawn_at_target` | `bool`（@export）| `false` | 真→在 target 处生成，否则在 source 处 |
| `use_pool` | `bool`（@export）| `false` | 真→从 `PoolService.acquire` 取用 |

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `_apply_impl(context) -> EffectResult` | `EffectResult` | 生成实例；若实例有 `set_direction` 且 `context.direction != 0` 则调用之 |

## 使用模式

### 最小示例（Level 1）

```gdscript
# 在技能 effects 数组里配：
var fx := SpawnSceneEffect.new()
fx.scene_path = "res://game/vfx/fireball_projectile.tscn"
fx.spawn_at_target = false   # 从施法者处生成，朝 context.direction 飞
```

## 相关

- → [GameEffect](GameEffect.md)（基类）· [ref/kernel/PoolService.md](PoolService.md)
- → [ref/modules/VFXSpawner.md](../modules/VFXSpawner.md)（表现层 VFX 的另一条路）
