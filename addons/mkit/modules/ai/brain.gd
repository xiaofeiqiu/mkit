class_name Brain
extends Node
@export var enabled: bool = true
@export var think_interval: float = 0.2
var _timer: float = 0.0
var command_router: CommandRouter = null
var target: Node = null
var blackboard: Blackboard = Blackboard.new()


func _ready() -> void:
	command_router = ServiceRegistry.get_service("commands") as CommandRouter


func _process(delta: float) -> void:
	if not enabled:
		return
	_timer -= delta
	if _timer <= 0:
		_timer = think_interval
		think()


func think() -> void:
	pass


func issue_command(command_type: String, payload: Dictionary = {}) -> bool:
	if command_router == null:
		return false
	var source_id := _get_owner_id()
	var cmd := GameCommand.create(command_type, source_id, source_id, payload)
	return command_router.dispatch(cmd)


func _get_owner_id() -> String:
	var identity := owner.get_node_or_null("EntityIdentity") as EntityIdentity
	return identity.entity_id if identity != null else owner.name
