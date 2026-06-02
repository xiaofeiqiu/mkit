# RoomGraph

## 概念说明

RoomGraph 是程序生成地牢后的完整房间连接图。它包含所有 RoomNode、起始节点和 Boss 节点，为 RunDirector 提供按索引访问当前房间的入口。生成器只输出 RoomGraph，不直接实例化场景。

## 设计目的

把地牢图的数据结构与场景实例化分离，使 DungeonGenerator 专注于生成合法的图结构，RunDirector 专注于按顺序或分支遍历节点，两者之间通过 RoomGraph 解耦。

## 文件

`res://addons/mkit/modules/run/room_graph.gd`

## 接口

```gdscript
class_name RoomGraph
extends RefCounted

var nodes: Array[RoomNode] = []
var start_node: RoomNode = null
var boss_node: RoomNode = null

func get_room_at(index: int) -> RoomNode:
    if index < 0 or index >= nodes.size():
        return null
    return nodes[index]
```

## 函数使用场景

- **`get_room_at(index)`**：RunDirector.enter_next_room() 用 `run_state.current_room_index` 调用此方法取当前 RoomNode；返回 null 表示已遍历完所有节点，触发 complete_run()。

## 使用示例

```gdscript
var generator := DungeonGenerator.new()
var graph := generator.generate_linear([
    "room.dungeon_small_01",
    "room.dungeon_small_02",
    "room.treasure_01"
], 98765, 8)

print("Start room: ", graph.start_node.room_definition_id)
print("Boss room: ", graph.boss_node.room_definition_id)

var room_2 := graph.get_room_at(2)
if room_2 != null:
    print("Room 2: ", room_2.room_definition_id)
```
