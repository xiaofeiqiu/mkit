# ObjectPool

## 概念说明

ObjectPool 是可复用场景实例池。负责预热、取出、归还投射物、伤害数字、VFX 等短生命周期节点。动作 RPG 中投射物和特效频繁生成销毁；对象池能降低卡顿，同时保持生成逻辑不散落在各模块里。

## 设计目的

通过复用节点实例减少高频 instantiate/queue_free 带来的性能开销。与 Godot 的 process_mode 配合实现节点激活和停用，并通过可选的 `on_pool_acquired` / `on_pool_released` 回调支持节点自定义重置逻辑。

## 文件

`res://addons/mkit/kernel/services/object_pool.gd`

## 接口

```gdscript
class_name ObjectPool
extends Node
func warmup(scene_path: String, count: int, parent: Node = null) -> void
func acquire(scene_path: String, parent: Node = null) -> Node
func release(scene_path: String, node: Node) -> void
func clear_pool(scene_path: String) -> void
```

## 函数使用场景

- **warmup()**：预热对象池。例：进入战斗房前调用 `warmup("res://game/vfx/hit.tscn", 20)` 预创建 VFX 节点，避免战斗中第一次生成时的卡顿。
- **acquire()**：取出实例。例：SpawnSceneEffect 从池中获取一个 fireball 场景实例，优先复用已有节点。
- **release()**：归还实例。例：投射物命中目标或超出边界后调用 `release` 回到池中，不 queue_free。
- **clear_pool()**：清理特定场景的整个池。例：退出 run 时释放该 run 的临时 VFX 和 projectile 节点。

## 使用示例

### 预热并使用对象池

```gdscript
var pool := ServiceRegistry.get_service("pool") as ObjectPool
# 预热
pool.warmup("res://game/projectiles/fireball.tscn", 10, $Projectiles)

# 取出
var projectile := pool.acquire("res://game/projectiles/fireball.tscn", $Projectiles)
projectile.global_position = player.global_position
projectile.direction = Vector2.RIGHT

# 命中后归还
pool.release("res://game/projectiles/fireball.tscn", projectile)
```
