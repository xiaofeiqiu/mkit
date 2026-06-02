# RoomNode

## 概念说明

RoomNode 是程序生成地牢后地图结构中的单个房间节点。它保存 node_id、room_definition_id、room_type 和与相邻节点的连接关系（next_nodes、previous_nodes）。生成器不能只返回一串场景路径；RunDirector 需要可检查、可保存、可调试的地图结构。

## 设计目的

把地牢图中每个房间节点的数据（定义 ID、类型、连接关系）封装为独立对象，使 RunDirector 可以按图遍历房间，而不需要直接加载场景，分离"地图结构"与"场景实例化"两个关注点。

## 文件

`res://addons/mkit/modules/room/room_node.gd`

## 字段说明

- **node_id**：稳定 ID 字段。例：RoomNode 通过 node_id 引用某个定义或运行时对象，避免直接保存节点路径。
- **room_definition_id**：稳定 ID 字段。例：RoomNode 通过 room_definition_id 引用某个定义或运行时对象，避免直接保存节点路径。
- **room_type**：代码字段。实际存在于当前实现中，供运行时或 Inspector 配置使用。
- **next_nodes**：集合字段。例：保存多个配置或运行时对象，让系统可以逐个处理。
- **previous_nodes**：集合字段。例：保存多个配置或运行时对象，让系统可以逐个处理。

## 接口

```gdscript
class_name RoomNode
extends RefCounted
var node_id: String = ""
var room_definition_id: String = ""
var room_type: String = "combat"
var next_nodes: Array[RoomNode] = []
var previous_nodes: Array[RoomNode] = []
```

## 函数使用场景

RoomNode 是纯数据对象，无公开方法。字段由 DungeonGenerator 填充，RunDirector 通过 RoomGraph.get_room_at() 读取。

- **`room_definition_id`**：RunDirector._load_room() 通过此 ID 从 ContentRegistry 查找 RoomDefinition 并加载对应场景。
- **`room_type`**：RunDirector 和 UI 据此决定进入房间的行为（combat 房间刷怪，treasure 房间开宝箱，boss 房间播放特殊音乐）。
- **`next_nodes` / `previous_nodes`**：分支地图实现时，RunDirector 据此让玩家选择前往哪个分支节点。线性地图时 next_nodes 只有一个元素。

## 使用示例

```gdscript
var node := RoomNode.new()
node.node_id = "room_node_001"
node.room_definition_id = "room.dungeon_small_01"
node.room_type = "combat"

# 连接到下一个节点
var next_node := RoomNode.new()
next_node.node_id = "room_node_002"
next_node.room_definition_id = "room.dungeon_elite_01"
node.next_nodes.append(next_node)
next_node.previous_nodes.append(node)
```
