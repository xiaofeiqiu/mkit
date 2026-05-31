class_name RoomNode
extends RefCounted

var node_id: String = ""
var room_definition_id: String = ""
var room_type: String = "combat"
var next_nodes: Array[RoomNode] = []
var previous_nodes: Array[RoomNode] = []
