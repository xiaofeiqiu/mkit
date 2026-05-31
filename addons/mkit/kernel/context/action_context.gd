class_name ActionContext
extends GameplayContext

## Purpose: Public runtime field `action_id`.
## Example: `self.action_id = "value"`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var action_id: String = ""
## Purpose: Public runtime field `duration`.
## Example: `self.duration = 1.0`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var duration: float = 0.0
## Purpose: Public runtime field `elapsed`.
## Example: `self.elapsed = 1.0`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var elapsed: float = 0.0
## Purpose: Public runtime field `phase`.
## Example: `self.phase = "value"`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var phase: String = ""


## Purpose: Public method `from_command` for external gameplay integration.
## Example: `ActionContext.from_command(<command>, <source_node>, <target_node>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
static func from_command(command: GameCommand, source_node: Node = null, target_node: Node = null) -> ActionContext:
	var ctx := ActionContext.new()
	ctx.source = source_node
	ctx.target = target_node
	ctx.payload = command.payload.duplicate(true)
	ctx.direction = command.get_vector2("direction", Vector2.ZERO)
	ctx.position = command.get_vector2("position", Vector2.ZERO)
	ctx.ability_id = command.get_string("ability_id", "")
	ctx.item_id = command.get_string("item_id", "")
	return ctx
