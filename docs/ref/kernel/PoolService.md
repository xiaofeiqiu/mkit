# PoolService

**层：** Kernel  
**文件：** `addons/mkit/kernel/services/pool_service.gd`  
**继承：** `extends Node`  
**服务 ID：** `"pool"`

## 职责

对象池，复用高频生成/销毁的节点（投射物、伤害数字、VFX），减少实例化开销。`SpawnSceneEffect`、`VFXSpawner`、`DamageNumberSystem` 在 `use_pool=true` 时走它。

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `warmup(scene_path, count, parent=null) -> void` | — | 预热：预先实例化 `count` 个备用 |
| `acquire(scene_path, parent=null) -> Node` | `Node` | 取一个（池空则新建），激活并挂到 parent |
| `release(scene_path, node) -> void` | — | 归还：停用并放回池 |
| `clear_pool(scene_path) -> void` | — | 清空某场景的池并 `queue_free` |

> 节点可实现 `on_pool_acquired()` / `on_pool_released()` 在取用/归还时重置自身状态。

## 使用模式

### 最小示例（Level 1）

```gdscript
var pool := ServiceRegistry.get_service("pool") as PoolService
pool.warmup("res://game/vfx/spark.tscn", 16)     # 开局预热
var fx := pool.acquire("res://game/vfx/spark.tscn", self)
# 用完归还
pool.release("res://game/vfx/spark.tscn", fx)
```

## 相关

- → [SpawnSceneEffect](SpawnSceneEffect.md) · [ref/modules/VFXSpawner.md](../modules/VFXSpawner.md) · [ref/modules/DamageNumberSystem.md](../modules/DamageNumberSystem.md)
