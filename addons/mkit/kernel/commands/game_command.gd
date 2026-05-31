## What: GameCommand is a structured request for gameplay intent, such as move, attack, cast, or equip.
## Responsibilities: carry type/source/target/payload metadata, expose typed payload readers, and track consumption.
## Upstream: input readers, AI planners, UI, network adapters, and scripted demos create commands.
## Downstream: CommandRouter and CommandReceiver deliver commands to state machines or gameplay systems.
## When to use: Use it when gameplay intent should be routed instead of directly calling entity methods.
## Example: `var cmd := GameCommand.create(BuiltinCommands.MOVE, "input", "player_001", {"direction": Vector2.RIGHT})`.
class_name GameCommand
extends RefCounted

## Purpose: Public runtime field `command_id`.
## Example: `self.command_id = "value"`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var command_id: String = ""
## Purpose: Public runtime field `command_type`.
## Example: `self.command_type = "value"`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var command_type: String = ""
## Purpose: Public runtime field `source_id`.
## Example: `self.source_id = "value"`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var source_id: String = ""
## Purpose: Public runtime field `target_id`.
## Example: `self.target_id = "value"`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var target_id: String = ""
## Purpose: Public runtime field `timestamp`.
## Example: `self.timestamp = 1.0`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var timestamp: float = 0.0
## Purpose: Public runtime field `priority`.
## Example: `self.priority = 1`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var priority: int = 0
## Purpose: Public runtime field `payload`.
## Example: `self.payload = {}`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var payload: Dictionary = {}
## Purpose: Public runtime field `consumed`.
## Example: `self.consumed = true`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var consumed: bool = false


## Purpose: Public method `create` for external gameplay integration.
## Example: `GameCommand.create(<type>, <source>, <target>, <data>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
static func create(type: String, source: String = "", target: String = "", data: Dictionary = {}) -> GameCommand:
	var cmd := GameCommand.new()
	cmd.command_type = type
	cmd.command_id = "%s_%d" % [type, Time.get_ticks_usec()]
	cmd.source_id = source
	cmd.target_id = target
	cmd.timestamp = Time.get_ticks_msec() / 1000.0
	cmd.payload = data
	return cmd


## Purpose: Public method `mark_consumed` for external gameplay integration.
## Example: `self.mark_consumed()`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func mark_consumed() -> void:
	consumed = true


## Purpose: Public method `get_vector2` for external gameplay integration.
## Example: `self.get_vector2(<key>, <default_value>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func get_vector2(key: String, default_value: Vector2 = Vector2.ZERO) -> Vector2:
	if payload.has(key):
		return payload[key]
	return default_value


## Purpose: Public method `get_string` for external gameplay integration.
## Example: `self.get_string(<key>, <default_value>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func get_string(key: String, default_value: String = "") -> String:
	if payload.has(key):
		return str(payload[key])
	return default_value


## Purpose: Public method `get_float` for external gameplay integration.
## Example: `self.get_float(<key>, <default_value>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func get_float(key: String, default_value: float = 0.0) -> float:
	if payload.has(key):
		return float(payload[key])
	return default_value
