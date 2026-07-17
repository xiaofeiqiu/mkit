extends Node

# Translates raw keyboard input into GameCommands for this entity's
# CommandReceiver. The state machine decides what (if anything) each command does;
# input never touches gameplay state directly.
#
# Reads keys directly (instead of named input actions) so the demo needs no
# project-level InputMap entries.
#   Move:   WASD
#   Attack: Space / J
#   Dash:   Shift

@export var target_id: String = "player_001"
@export var cast_ability_id: String = ""

var _receiver: CommandReceiver = null
var _was_moving: bool = false


func _ready() -> void:
	_receiver = EntityContract.get_command_receiver(self)


func _physics_process(_delta: float) -> void:
	var dir := _read_direction()

	if dir != Vector2.ZERO:
		_send_command(BuiltinCommands.MOVE, {"direction": dir})
		_was_moving = true
	elif _was_moving:
		_send_command(BuiltinCommands.STOP_MOVE)
		_was_moving = false


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE or event.keycode == KEY_J:
			_send_command(BuiltinCommands.ATTACK)
		elif event.keycode == KEY_Q:
			var ability_id := cast_ability_id.strip_edges()
			if ability_id == "":
				return
			_send_command(BuiltinCommands.CAST_ABILITY, {"ability_id": ability_id})
		elif event.keycode == KEY_SHIFT:
			_send_command(BuiltinCommands.DASH, {"direction": _read_direction()})


func _send_command(command_type: String, payload: Dictionary = {}) -> bool:
	if _receiver == null:
		_receiver = EntityContract.get_command_receiver(self)
	if _receiver == null:
		return false
	var command := GameCommand.create(command_type, target_id, target_id, payload)
	return _receiver.receive_command(command)


func _read_direction() -> Vector2:
	var dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_A):
		dir.x -= 1.0
	if Input.is_key_pressed(KEY_D):
		dir.x += 1.0
	if Input.is_key_pressed(KEY_W):
		dir.y -= 1.0
	if Input.is_key_pressed(KEY_S):
		dir.y += 1.0
	return dir
