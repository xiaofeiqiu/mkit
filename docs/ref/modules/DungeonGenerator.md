# DungeonGenerator

**层：** Module  
**文件：** `addons/mkit/modules/world/dungeon/dungeon_generator.gd`  
**继承：** `extends RefCounted`

## 职责

Run 房间图生成器。当前实现提供线性序列：从房间池按 seed 随机抽取 `length` 个 `RoomNode`。

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `generate_linear(room_pool_ids: Array[String], seed: int, length: int) -> RoomGraph` | `RoomGraph` | 生成线性房间图；空池或非正长度返回空图 |

## 使用模式

### 最小示例（Level 1）

```gdscript
var graph: RoomGraph = DungeonGenerator.new().generate_linear(["room.a", "room.b"], 99, 3)
```

### 典型场景（Level 2）

```gdscript
func build_run_graph(pool: Array[String], length: int) -> RoomGraph:
    if pool.is_empty():
        return RoomGraph.new()
    var seed := 12345
    return DungeonGenerator.new().generate_linear(pool, seed, length)
```

## 相关

- → [RoomGraph](RoomGraph.md) · [RoomNode](RoomNode.md) · [RunDirector](RunDirector.md)

