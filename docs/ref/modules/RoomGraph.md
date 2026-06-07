# RoomGraph

**层：** Module  
**文件：** `addons/mkit/modules/world/dungeon/room_graph.gd`  
**继承：** `extends RefCounted`

## 职责

一局 run 的房间图。当前 `DungeonGenerator.generate_linear()` 生成线性图，`RunDirector` 用 index 顺序取房间。

## 字段

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `nodes` | `Array[RoomNode]` | `[]` | 全部房间节点 |
| `start_node` | `RoomNode` | `null` | 起点 |
| `boss_node` | `RoomNode` | `null` | 当前线性图的末节点 |

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `get_room_at(index: int) -> RoomNode` | `RoomNode` | 越界返回 `null` |
| `clear() -> void` | — | 清空节点和连接引用 |

## 使用模式

### 最小示例（Level 1）

```gdscript
var graph: RoomGraph = DungeonGenerator.new().generate_linear(["room.a"], 42, 3)
var first: RoomNode = graph.get_room_at(0)
```

### 典型场景（Level 2）

```gdscript
func next_room_id(graph: RoomGraph, index: int) -> String:
    var node: RoomNode = graph.get_room_at(index)
    if node == null:
        return ""
    return node.room_definition_id
```

## 相关

- → [RoomNode](RoomNode.md) · [DungeonGenerator](DungeonGenerator.md) · [RunState](RunState.md)

