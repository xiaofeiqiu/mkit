class_name ActionContext
extends GameplayContext
var action_id: String = ""
var duration: float = 0.0
var elapsed: float = 0.0
var phase: String = ""


static func from_nodes(source_node: Node = null, target_node: Node = null) -> ActionContext:
	var ctx := ActionContext.new()
	ctx.source = source_node
	ctx.target = target_node
	return ctx


static func from_context(context: GameplayContext = null) -> ActionContext:
	var ctx := ActionContext.new()
	if context == null:
		return ctx
	ctx.source = context.source
	ctx.target = context.target
	ctx.instigator = context.instigator
	ctx.ability_id = context.ability_id
	ctx.item_id = context.item_id
	ctx.status_id = context.status_id
	ctx.room_id = context.room_id
	ctx.run_id = context.run_id
	ctx.position = context.position
	ctx.direction = context.direction
	ctx.amount = context.amount
	ctx.tags = context.tags.duplicate()
	ctx.payload = context.payload.duplicate(true) if context.payload != null else {}
	return ctx


static func from_command(
	command: GameCommand, source_node: Node = null, target_node: Node = null
) -> ActionContext:
	var ctx := from_nodes(source_node, target_node)
	ctx.payload = command.payload.duplicate(true)
	ctx.direction = command.get_vector2("direction", Vector2.ZERO)
	ctx.position = command.get_vector2("position", Vector2.ZERO)
	ctx.ability_id = command.get_string("ability_id", "")
	ctx.item_id = command.get_string("item_id", "")
	return ctx
