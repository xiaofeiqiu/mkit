class_name ActionContext
extends GameplayContext
var action_id: String = ""
var duration: float = 0.0
var elapsed: float = 0.0
var phase: String = ""


static func from_command(
	command: GameCommand, source_node: Node = null, target_node: Node = null
) -> ActionContext:
	var ctx := ActionContext.new()
	ctx.source = source_node
	ctx.target = target_node
	ctx.payload = command.payload.duplicate(true)
	ctx.direction = command.get_vector2("direction", Vector2.ZERO)
	ctx.position = command.get_vector2("position", Vector2.ZERO)
	ctx.ability_id = command.get_string("ability_id", "")
	ctx.item_id = command.get_string("item_id", "")
	return ctx
