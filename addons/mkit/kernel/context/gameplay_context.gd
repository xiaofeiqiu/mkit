class_name GameplayContext
extends RefCounted
var source: Node = null
var target: Node = null
var instigator: Node = null
var ability_id: String = ""
var item_id: String = ""
var status_id: String = ""
var room_id: String = ""
var run_id: String = ""
var position: Vector2 = Vector2.ZERO
var direction: Vector2 = Vector2.ZERO
var amount: float = 0.0
var tags: Array[String] = []
var payload: Dictionary = {}


static func from_nodes(source_node: Node = null, target_node: Node = null) -> GameplayContext:
	var ctx := GameplayContext.new()
	ctx.source = source_node
	ctx.target = target_node
	return ctx


static func from_context(context: GameplayContext = null) -> GameplayContext:
	return context if context != null else GameplayContext.new()


static func from_command(
	command: GameCommand, source_node: Node = null, target_node: Node = null
) -> GameplayContext:
	var ctx := from_nodes(source_node, target_node)
	ctx.payload = command.payload.duplicate(true)
	ctx.direction = command.get_vector2("direction", Vector2.ZERO)
	ctx.position = command.get_vector2("position", Vector2.ZERO)
	ctx.ability_id = command.get_string("ability_id", "")
	ctx.item_id = command.get_string("item_id", "")
	return ctx


func with_source(node: Node) -> GameplayContext:
	source = node
	return self


func with_target(node: Node) -> GameplayContext:
	target = node
	return self


func with_payload_value(key: String, value) -> GameplayContext:
	payload[key] = value
	return self


func get_payload_value(key: String, default_value = null):
	if payload.has(key):
		return payload[key]
	return default_value


func has_tag(tag: String) -> bool:
	return tags.has(tag)
