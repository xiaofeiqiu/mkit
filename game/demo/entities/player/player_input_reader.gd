extends Node

# Translates raw keyboard input into GameCommands and dispatches them through the
# CommandRouter to this entity's CommandReceiver. The state machine decides what
# (if anything) each command does — input never touches gameplay state directly.
#
# Reads keys directly (instead of named input actions) so the demo needs no
# project-level InputMap entries.
#   Move:   WASD / Arrow keys
#   Attack: Space / J

@export var target_id: String = "player_001"
@export var cast_ability_id: String = ""

var _router: CommandRouter = null
var _was_moving: bool = false


func _ready() -> void:
	_router = ServiceRegistry.get_service("commands") as CommandRouter


func _physics_process(_delta: float) -> void:
	if _router == null:
		_router = ServiceRegistry.get_service("commands") as CommandRouter
		if _router == null:
			return

	var dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		dir.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		dir.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		dir.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		dir.y += 1.0

	if dir != Vector2.ZERO:
		_router.dispatch(
			GameCommand.create(BuiltinCommands.MOVE, target_id, target_id, {"direction": dir})
		)
		_was_moving = true
	elif _was_moving:
		_router.dispatch(GameCommand.create(BuiltinCommands.STOP_MOVE, target_id, target_id, {}))
		_was_moving = false


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE or event.keycode == KEY_J:
			if _router == null:
				return
			_router.dispatch(GameCommand.create(BuiltinCommands.ATTACK, target_id, target_id, {}))
		elif event.keycode == KEY_Q:
			var ability_id := cast_ability_id.strip_edges()
			if _router == null or ability_id == "":
				return
			_router.dispatch(
				GameCommand.create(
					BuiltinCommands.CAST_ABILITY,
					target_id,
					target_id,
					{"ability_id": ability_id}
				)
			)
