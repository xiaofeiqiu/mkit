## What: RoomNode is one node in a generated RoomGraph.
## Responsibilities: store graph node id, RoomDefinition id, room type, next nodes, and previous nodes.
## Upstream: DungeonGenerator creates RoomNode instances while building a run path.
## Downstream: RunDirector reads nodes to decide which room definition to load next.
## When to use: Use it as graph data for linear or branching room progression.
## Example: `node.room_definition_id = "combat_02"; node.next_nodes.append(boss_node)`.
class_name RoomNode
extends RefCounted

## Purpose: Public runtime field `node_id`.
## Example: `self.node_id = "value"`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var node_id: String = ""
## Purpose: Public runtime field `room_definition_id`.
## Example: `self.room_definition_id = "value"`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var room_definition_id: String = ""
## Purpose: Public runtime field `room_type`.
## Example: `self.room_type = "value"`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var room_type: String = "combat"
## Purpose: Public runtime field `next_nodes`.
## Example: `self.next_nodes = []`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var next_nodes: Array[RoomNode] = []
## Purpose: Public runtime field `previous_nodes`.
## Example: `self.previous_nodes = []`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var previous_nodes: Array[RoomNode] = []
