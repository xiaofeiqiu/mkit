class_name RoomNode
extends RefCounted
## 说明：`RoomNode` 是 房间与一局流程系统 的节点数据，负责保存图或流程中的单个节点信息。
## 上游：通常由同领域服务、controller、组件或内容资源创建或调用。
## 下游：会连接 mkit 的服务、组件、资源或事件管线，不直接依赖具体游戏内容。
## 使用：当项目需要在房间与一局流程系统中复用这段契约或状态时使用它。
## 示例：`var instance := RoomNode.new()`

## 运行时状态：`node_id` 表示稳定 id，由 `RoomNode` 的公开 API 读取或维护。
var node_id: String = ""
## 运行时状态：`room_definition_id` 表示稳定 id，由 `RoomNode` 的公开 API 读取或维护。
var room_definition_id: String = ""
## 运行时状态：`room_type` 表示 `RoomNode` 的字段值，由 `RoomNode` 的公开 API 读取或维护。
var room_type: String = "combat"
## 运行时状态：`next_nodes` 表示 `RoomNode` 的字段值，由 `RoomNode` 的公开 API 读取或维护。
var next_nodes: Array[RoomNode] = []
## 运行时状态：`previous_nodes` 表示 `RoomNode` 的字段值，由 `RoomNode` 的公开 API 读取或维护。
var previous_nodes: Array[RoomNode] = []
