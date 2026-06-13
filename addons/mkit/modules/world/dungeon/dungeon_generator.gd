class_name DungeonGenerator
extends RefCounted
## 说明：`DungeonGenerator` 是 房间与一局流程系统 的公开 API 类型，负责承载该领域的可复用运行时数据或行为。
## 上游：通常由同领域服务、controller、组件或内容资源创建或调用。
## 下游：会连接 mkit 的服务、组件、资源或事件管线，不直接依赖具体游戏内容。
## 使用：当项目需要在房间与一局流程系统中复用这段契约或状态时使用它。
## 示例：`var instance := DungeonGenerator.new()`



## 读取配置资源生成运行时对象或结果；输入为空或无效时返回空结果。
func generate_linear(room_pool_ids: Array[String], seed: int, length: int) -> RoomGraph:
	var graph := RoomGraph.new()
	if length <= 0:
		return graph
	if room_pool_ids.is_empty():
		push_warning("DungeonGenerator: room_pool_ids is empty, cannot generate run graph.")
		return graph
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var previous: RoomNode = null
	for i in range(length):
		var node := RoomNode.new()
		node.node_id = "room_node_%d" % i
		node.room_definition_id = room_pool_ids[rng.randi_range(0, room_pool_ids.size() - 1)]
		node.room_type = "combat"
		if previous != null:
			previous.next_nodes.append(node)
			node.previous_nodes.append(previous)
		else:
			graph.start_node = node
		graph.nodes.append(node)
		previous = node
	if previous != null:
		graph.boss_node = previous
	return graph
