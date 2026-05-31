class_name DungeonGenerator
extends RefCounted

## Purpose: Public method `generate_linear` for external gameplay integration.
## Example: `self.generate_linear(<room_pool_ids>, <seed>, <length>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func generate_linear(room_pool_ids: Array[String], seed: int, length: int) -> RoomGraph:
	var graph := RoomGraph.new()
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
