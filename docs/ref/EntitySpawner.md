# EntitySpawner

## 概念说明

EntitySpawner 是通过 EntityDefinition 创建实体节点的统一入口。它负责加载实体场景、挂到指定父节点、初始化 EntityIdentity、基础属性和初始技能。房间刷怪、召唤物、陷阱和读档恢复都需要生成实体；统一入口可以保证 ID、阵营、属性和事件链一致。

## 设计目的

把"从定义 ID 生成实体"的全部逻辑集中到一个节点，避免 Room、AI、Effect 等各处手写场景路径加载和 EntityIdentity 初始化代码，同时通过信号让外部系统（如 RoomController）知道哪些实体被生成或失败。

## 文件

`res://addons/mkit/modules/entity/entity_spawner.gd`

## 字段说明

- **content**：代码字段。实际存在于当前实现中，供运行时或 Inspector 配置使用。

## 接口

```gdscript
class_name EntitySpawner
extends Node
signal entity_spawned(entity: Node, definition_id: String)
signal entity_spawn_failed(definition_id: String, reason: String)
var content: ContentRegistry = null
func spawn_entity( definition_id: String, parent: Node, position: Vector2 = Vector2.ZERO, runtime_id: String = "" ) -> Node
```

## 函数使用场景

- **`spawn_entity(definition_id, parent, position, runtime_id)`**：主要公开接口，通过 ContentRegistry 查找 EntityDefinition，实例化场景，挂到 parent 节点，并依次初始化 identity、stats 和 abilities。成功后发出 `entity_spawned` 信号，失败时发出 `entity_spawn_failed`。例如 RoomController 进入房间时对每个 enemy_spawn_id 调用此方法。
- **`_get_definition(definition_id)`**：内部辅助，从 ContentRegistry 读取 EntityDefinition；若 ContentRegistry 未缓存则重新获取。
- **`_initialize_identity(entity, definition, runtime_id)`**：把 definition 的 definition_id、display_name、faction、tags 写入实体的 EntityIdentity；若传入 runtime_id 则覆盖自动生成的 entity_id。
- **`_initialize_stats(entity, definition)`**：把 definition.base_stats 中每个 stat_id/value 写入实体的 StatsComponent.set_base_stat。
- **`_initialize_abilities(entity, definition)`**：对 definition.starting_ability_ids 逐个调用实体 AbilityController.register_ability。

## 使用示例

```gdscript
var spawner := $EntitySpawner as EntitySpawner
var enemy := spawner.spawn_entity(
    "enemy.goblin_basic",
    $Enemies,
    Vector2(320, 160)
)

# 监听生成事件
spawner.entity_spawned.connect(func(entity, def_id):
    print("Spawned: ", def_id, " at ", entity.global_position)
)
spawner.entity_spawn_failed.connect(func(def_id, reason):
    push_error("Spawn failed for %s: %s" % [def_id, reason])
)
```
