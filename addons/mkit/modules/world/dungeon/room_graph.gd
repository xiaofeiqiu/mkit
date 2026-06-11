class_name RoomGraph
extends RefCounted
## 说明：`RoomGraph` 是 房间与一局流程系统 的图结构，负责保存节点连接和路径选择信息。
## 上游：通常由同领域服务、controller、组件或内容资源创建或调用。
## 下游：会连接 mkit 的服务、组件、资源或事件管线，不直接依赖具体游戏内容。
## 使用：当项目需要在房间与一局流程系统中复用这段契约或状态时使用它。
## 示例：`var instance := RoomGraph.new()`

## 运行时状态：`nodes` 表示 `RoomGraph` 的字段值，由 `RoomGraph` 的公开 API 读取或维护。
var nodes: Array[RoomNode] = []
## 运行时状态：`start_node` 表示 `RoomGraph` 的字段值，由 `RoomGraph` 的公开 API 读取或维护。
var start_node: RoomNode = null
## 运行时状态：`boss_node` 表示 `RoomGraph` 的字段值，由 `RoomGraph` 的公开 API 读取或维护。
var boss_node: RoomNode = null


## 返回 `room_at` 对应的数据或对象，并保持 `RoomGraph` 的领域契约一致。
func get_room_at(index: int) -> RoomNode:
	if index < 0 or index >= nodes.size():
		return null
	return nodes[index]


## 清理当前保存的运行时状态或缓存，并保持 `RoomGraph` 的领域契约一致。
func clear() -> void:
	for node in nodes:
		node.next_nodes.clear()
		node.previous_nodes.clear()
	nodes.clear()
	start_node = null
	boss_node = null
