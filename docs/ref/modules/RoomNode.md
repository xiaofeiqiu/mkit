# RoomNode

**层：** Module  
**文件：** `addons/mkit/modules/world/dungeon/room_node.gd`  
**继承：** `extends RefCounted`

## 职责

`RoomGraph` 的节点。记录一个房间定义 ID，以及前后连接关系。

## 字段

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `node_id` | `String` | `""` | 图内节点 ID |
| `room_definition_id` | `String` | `""` | 对应 `RoomDefinition.room_id` |
| `room_type` | `String` | `"combat"` | 类型标记 |
| `next_nodes` | `Array[RoomNode]` | `[]` | 后继节点 |
| `previous_nodes` | `Array[RoomNode]` | `[]` | 前驱节点 |

## 使用模式

### 最小示例（Level 1）

```gdscript
var node := RoomNode.new()
node.node_id = "room_node_0"
node.room_definition_id = "room.combat_a"
```

### 典型场景（Level 2）

```gdscript
func print_graph(graph: RoomGraph) -> void:
    for node in graph.nodes:
        print("%s -> %d next" % [node.room_definition_id, node.next_nodes.size()])
```

## 相关

- → [RoomGraph](RoomGraph.md) · [DungeonGenerator](DungeonGenerator.md) · [RunDirector](RunDirector.md)

