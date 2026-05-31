## What: RoomGraph is the runtime graph of RoomNode objects for a generated run floor.
## Responsibilities: store ordered room nodes, start node, boss node, and room lookup by index.
## Upstream: DungeonGenerator creates it from room pools and a seed.
## Downstream: RunDirector advances through it and loads RoomDefinition ids.
## When to use: Use it when run flow needs a generated sequence or graph of rooms instead of a single scene.
## Example: `var graph := DungeonGenerator.new().generate_linear(["combat_01", "combat_02"], 42, 3)`.
class_name RoomGraph
extends RefCounted

## Purpose: Public runtime field `nodes`.
## Example: `self.nodes = []`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var nodes: Array[RoomNode] = []
## Purpose: Public runtime field `start_node`.
## Example: `self.start_node = null`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var start_node: RoomNode = null
## Purpose: Public runtime field `boss_node`.
## Example: `self.boss_node = null`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var boss_node: RoomNode = null

## Purpose: Public method `get_room_at` for external gameplay integration.
## Example: `self.get_room_at(<index>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func get_room_at(index: int) -> RoomNode:
	if index < 0 or index >= nodes.size():
		return null
	return nodes[index]
