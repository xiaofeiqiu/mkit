class_name RoomNode
extends RefCounted
## 说明：`RoomNode` 是 房间与一局流程系统 的节点数据，负责保存图或流程中的单个节点信息。
## 上游：通常由同领域服务、controller、组件或内容资源创建或调用。
## 下游：会连接 mkit 的服务、组件、资源或事件管线，不直接依赖具体游戏内容。
## 使用：当项目需要在房间与一局流程系统中复用这段契约或状态时使用它。
## 示例：`var instance := RoomNode.new()`

## RoomGraph 内部使用的节点 id；同一房间图中应保持唯一。
var node_id: String = ""
## 引用的 RoomDefinition id；房间控制器或节点按它加载静态配置。
var room_definition_id: String = ""
## 房间类型字符串；例如 combat、shop、event，由游戏内容约定。
var room_type: String = "combat"
## 当前房间图节点可前往的后继节点列表。
var next_nodes: Array[RoomNode] = []
## 当前房间图节点的前置节点列表。
var previous_nodes: Array[RoomNode] = []
