class_name GameplayContext
extends RefCounted

## Purpose: Public runtime field `source`.
## Example: `self.source = null`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var source: Node = null
## Purpose: Public runtime field `target`.
## Example: `self.target = null`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var target: Node = null
## Purpose: Public runtime field `instigator`.
## Example: `self.instigator = null`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var instigator: Node = null
## Purpose: Public runtime field `ability_id`.
## Example: `self.ability_id = "value"`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var ability_id: String = ""
## Purpose: Public runtime field `item_id`.
## Example: `self.item_id = "value"`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var item_id: String = ""
## Purpose: Public runtime field `status_id`.
## Example: `self.status_id = "value"`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var status_id: String = ""
## Purpose: Public runtime field `room_id`.
## Example: `self.room_id = "value"`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var room_id: String = ""
## Purpose: Public runtime field `run_id`.
## Example: `self.run_id = "value"`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var run_id: String = ""
## Purpose: Public runtime field `position`.
## Example: `self.position = Vector2.ZERO`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var position: Vector2 = Vector2.ZERO
## Purpose: Public runtime field `direction`.
## Example: `self.direction = Vector2.ZERO`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var direction: Vector2 = Vector2.ZERO
## Purpose: Public runtime field `amount`.
## Example: `self.amount = 1.0`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var amount: float = 0.0
## Purpose: Public runtime field `tags`.
## Example: `self.tags = []`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var tags: Array[String] = []
## Purpose: Public runtime field `payload`.
## Example: `self.payload = {}`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var payload: Dictionary = {}


## Purpose: Public method `from_command` for external gameplay integration.
## Example: `GameplayContext.from_command(<command>, <source_node>, <target_node>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
static func from_command(command: GameCommand, source_node: Node = null, target_node: Node = null) -> GameplayContext:
	var ctx := GameplayContext.new()
	ctx.source = source_node
	ctx.target = target_node
	ctx.payload = command.payload.duplicate(true)
	ctx.direction = command.get_vector2("direction", Vector2.ZERO)
	ctx.position = command.get_vector2("position", Vector2.ZERO)
	ctx.ability_id = command.get_string("ability_id", "")
	ctx.item_id = command.get_string("item_id", "")
	return ctx


## Purpose: Public method `with_source` for external gameplay integration.
## Example: `self.with_source(<node>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func with_source(node: Node) -> GameplayContext:
	source = node
	return self


## Purpose: Public method `with_target` for external gameplay integration.
## Example: `self.with_target(<node>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func with_target(node: Node) -> GameplayContext:
	target = node
	return self


## Purpose: Public method `with_payload_value` for external gameplay integration.
## Example: `self.with_payload_value(<key>, <value>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func with_payload_value(key: String, value) -> GameplayContext:
	payload[key] = value
	return self


## Purpose: Public method `get_payload_value` for external gameplay integration.
## Example: `self.get_payload_value(<key>, <default_value>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func get_payload_value(key: String, default_value = null):
	if payload.has(key):
		return payload[key]
	return default_value


## Purpose: Public method `has_tag` for external gameplay integration.
## Example: `self.has_tag(<tag>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func has_tag(tag: String) -> bool:
	return tags.has(tag)
