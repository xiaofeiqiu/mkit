class_name RoomGraph
extends RefCounted
var nodes: Array[RoomNode] = []
var start_node: RoomNode = null
var boss_node: RoomNode = null


func get_room_at(index: int) -> RoomNode:
	if index < 0 or index >= nodes.size():
		return null
	return nodes[index]
