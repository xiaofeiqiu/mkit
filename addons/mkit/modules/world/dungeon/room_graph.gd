class_name RoomGraph
extends RefCounted
## 说明：`RoomGraph` 是 房间与一局流程系统 的图结构，负责保存节点连接和路径选择信息。
## 上游：通常由同领域服务、controller、组件或内容资源创建或调用。
## 下游：会连接 mkit 的服务、组件、资源或事件管线，不直接依赖具体游戏内容。
## 使用：当项目需要在房间与一局流程系统中复用这段契约或状态时使用它。
## 示例：`var instance := RoomGraph.new()`

## 房间图中的节点列表；每个 RoomNode 代表一个可进入房间。
var nodes: Array[RoomNode] = []
## 本局房间图的起点节点。
var start_node: RoomNode = null
## 本局房间图的终点或 Boss 节点；没有 Boss 时可为 null。
var boss_node: RoomNode = null


## 读取当前对象中的 `room_at`；未找到时返回 null、空集合或该 API 的默认值。
func get_room_at(index: int) -> RoomNode:
	if index < 0 or index >= nodes.size():
		return null
	return nodes[index]


## 清空本对象持有的运行时表和缓存；通常在测试或重新 bootstrap 前调用。
func clear() -> void:
	for node in nodes:
		node.next_nodes.clear()
		node.previous_nodes.clear()
	nodes.clear()
	start_node = null
	boss_node = null
