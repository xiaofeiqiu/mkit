# VFXSpawner

## 概念说明

VFXSpawner 是视觉特效生成器。它按 vfx_id 生成 PackedScene，设置位置、方向和自动清理。伤害、死亡、拾取、房间清理等事件都需要 VFX，但玩法系统不应该知道具体特效场景。

## 设计目的

把特效场景的实例化、位置设置和自动生命周期管理集中到一个服务节点，使 FeedbackSystem 只需传入 vfx_id 和位置，不需要了解特效场景路径或 Tween 动画清理逻辑。

## 文件

`res://addons/mkit/modules/ui/vfx_spawner.gd`

## 字段说明

- **vfx_scene_map**：特效场景表。例：hit、death、pickup 分别映射到不同 PackedScene。
- **auto_free_seconds**：自动清理时间。例：普通 hit VFX 2 秒后释放。
- **use_pool**：是否通过 `"pool"` 服务复用 VFX 实例。默认 false，保持直接实例化和 queue_free 行为。

## 接口

```gdscript
class_name VFXSpawner
extends Node
@export var vfx_scene_map: Dictionary = {}
@export var auto_free_seconds: float = 2.0
@export var use_pool: bool = false
func spawn(vfx_id: String, position: Vector2, direction: Vector2 = Vector2.ZERO) -> Node
```

## 函数使用场景

- **`spawn(vfx_id, position, direction)`**：从 `vfx_scene_map` 查找场景路径，加载并实例化 PackedScene，设置 global_position 和 rotation（基于 direction），若节点有 `play()` 方法则调用，再通过 Timer 在 `auto_free_seconds` 后清理。`use_pool=true` 且 `"pool"` 服务存在时清理动作为 ObjectPool release，否则 queue_free。vfx_id 不存在时返回 null，不影响 gameplay。FeedbackSystem 在 damage_applied 和 entity_died 时调用此方法。

## 使用示例

```gdscript
# 在目标位置生成命中特效
$VFXSpawner.spawn("hit", enemy.global_position, Vector2.LEFT)

# 生成死亡爆炸
$VFXSpawner.spawn("death", enemy.global_position)

# 生成拾取反馈
$VFXSpawner.spawn("pickup", item_position)
```
