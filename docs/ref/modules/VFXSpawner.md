# VFXSpawner

**层：** Module  
**文件：** `addons/mkit/modules/ui/vfx_spawner.gd`  
**继承：** `extends Node`

## 职责

VFX 生成器。按 `vfx_id` 查场景路径，实例化到自身下，设置位置 / 朝向，可自动释放或归还对象池。

## 字段

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `vfx_scene_map` | `Dictionary`（@export）| `{}` | vfx_id → PackedScene 路径 |
| `auto_free_seconds` | `float`（@export）| `2.0` | 自动释放时间；<=0 不自动释放 |
| `use_pool` | `bool`（@export）| `false` | 是否用 `PoolService` |

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `spawn(vfx_id: String, position: Vector2, direction: Vector2 = Vector2.ZERO) -> Node` | `Node` | 成功返回 VFX 节点；未注册或加载失败返回 `null` |

## 使用模式

### 最小示例（Level 1）

```gdscript
$VFXSpawner.spawn("hit", player.global_position)
```

### 典型场景（Level 2）

```gdscript
func spawn_directional_hit(target: Node2D, direction: Vector2) -> void:
    var spawner := $VFXSpawner as VFXSpawner
    var node: Node = spawner.spawn("hit", target.global_position, direction)
    if node == null:
        push_warning("Missing hit VFX")
```

## 相关

- → [FeedbackSystem](FeedbackSystem.md) · [PoolService](../kernel/PoolService.md)
- → [cookbook/13_animation.md](../../cookbook/13_animation.md)

