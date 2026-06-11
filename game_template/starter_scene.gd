extends Node2D

const PLAYER_ID := "starter.player"
const ENEMY_ID := "starter.enemy"
const QUEST_ID := "starter.quest.first_hunt"
const ATTACK_COMMAND := "starter.attack"
const ENEMY_DEFEATED_EVENT := "starter.enemy_defeated"
const PLAYER_SPEED := 180.0
const ATTACK_RANGE := 56.0
const ATTACK_DAMAGE := 1
const ENEMY_MAX_HP := 3


class EnemyReceiver:
	extends CommandReceiver
	var scene: Node = null

	func handle_unhandled_command(command: GameCommand) -> bool:
		if command.command_type != "starter.attack" or scene == null:
			return false
		return bool(scene.call("_handle_attack_command", command))


var _commands: CommandService = null
var _content: ContentService = null
var _events: EventService = null
var _quest: QuestService = null
var _player: Node2D = null
var _enemy: Node2D = null
var _enemy_hp: int = ENEMY_MAX_HP
var _status_label: Label = null
var _log_label: Label = null


func _ready() -> void:
	_commands = Mkit.commands()
	_content = Mkit.content()
	_events = Mkit.events()
	_quest = Mkit.quest()
	_build_world()
	_register_enemy_receiver()
	_setup_quest()
	_set_log("Move close to the enemy, then press Space or J.")
	_update_status()


func _exit_tree() -> void:
	if _commands != null:
		_commands.unregister_receiver(ENEMY_ID)


func _process(delta: float) -> void:
	var input := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		input.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		input.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		input.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		input.y += 1.0
	if input != Vector2.ZERO:
		_player.position += input.normalized() * PLAYER_SPEED * delta


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if key.keycode == KEY_SPACE or key.keycode == KEY_J:
		_dispatch_attack()


func _build_world() -> void:
	_player = _make_actor(Color(0.2, 0.7, 1.0), 16.0)
	_player.name = "Player"
	_player.position = Vector2(300.0, 240.0)
	add_child(_player)

	_enemy = _make_actor(Color(1.0, 0.35, 0.25), 18.0)
	_enemy.name = "Enemy"
	_enemy.position = Vector2(520.0, 240.0)
	var enemy_state_machine := StateMachine.new()
	enemy_state_machine.name = "StateMachine"
	_enemy.add_child(enemy_state_machine)
	add_child(_enemy)

	var canvas := CanvasLayer.new()
	add_child(canvas)
	_status_label = Label.new()
	_status_label.position = Vector2(16.0, 16.0)
	_status_label.add_theme_font_size_override("font_size", 18)
	canvas.add_child(_status_label)
	_log_label = Label.new()
	_log_label.position = Vector2(16.0, 58.0)
	_log_label.add_theme_font_size_override("font_size", 16)
	canvas.add_child(_log_label)


func _make_actor(color: Color, radius: float) -> EntityRoot:
	var node := EntityRoot.new()
	var body := Polygon2D.new()
	body.color = color
	body.polygon = PackedVector2Array(
		[
			Vector2(-radius, -radius),
			Vector2(radius, -radius),
			Vector2(radius, radius),
			Vector2(-radius, radius)
		]
	)
	node.add_child(body)
	return node


func _register_enemy_receiver() -> void:
	var receiver := EnemyReceiver.new()
	receiver.name = "CommandReceiver"
	receiver.receiver_id = ENEMY_ID
	receiver.auto_register = false
	receiver.scene = self
	_enemy.add_child(receiver)
	_commands.register_receiver(ENEMY_ID, receiver)


func _setup_quest() -> void:
	if not _content.has(QUEST_ID):
		var objective := QuestObjectiveDefinition.new()
		objective.objective_id = "defeat_enemy"
		objective.description = "Defeat the starter enemy"
		objective.event_type = ENEMY_DEFEATED_EVENT
		objective.match_key = "enemy_id"
		objective.match_value = ENEMY_ID
		objective.required_count = 1
		var definition := QuestDefinition.new()
		definition.quest_id = QUEST_ID
		definition.display_name = "First Hunt"
		definition.description = "Defeat the starter enemy."
		var objectives: Array[QuestObjectiveDefinition] = [objective]
		definition.objectives = objectives
		definition.auto_complete = true
		_content.register_resource(definition)
	if _quest.get_state(QUEST_ID) == null:
		_quest.accept_quest(QUEST_ID, GameplayContext.from_nodes(_player))


func _dispatch_attack() -> void:
	var command := GameCommand.create(
		ATTACK_COMMAND, PLAYER_ID, ENEMY_ID, {"damage": ATTACK_DAMAGE}
	)
	if not _commands.dispatch(command):
		_set_log("Move closer before attacking.")


func _handle_attack_command(command: GameCommand) -> bool:
	if _enemy_hp <= 0:
		return false
	if _player.position.distance_to(_enemy.position) > ATTACK_RANGE:
		return false
	_enemy_hp = max(0, _enemy_hp - int(command.payload.get("damage", ATTACK_DAMAGE)))
	if _enemy_hp <= 0:
		_enemy.visible = false
		_events.emit_domain_event(
			DomainEvent.create(
				ENEMY_DEFEATED_EVENT, PLAYER_ID, ENEMY_ID, {"enemy_id": ENEMY_ID, "amount": 1}
			)
		)
		_set_log("Enemy defeated. Quest complete.")
	else:
		_set_log("Hit confirmed.")
	_update_status()
	return true


func _update_status() -> void:
	var quest_state := _quest.get_state(QUEST_ID)
	var quest_text := "Quest: First Hunt"
	if quest_state != null:
		if quest_state.status == QuestState.STATUS_TURNED_IN:
			quest_text = "Quest: First Hunt complete"
		else:
			quest_text = "Quest: First Hunt 0/1"
	_status_label.text = "%s\nEnemy HP: %d/%d" % [quest_text, _enemy_hp, ENEMY_MAX_HP]


func _set_log(message: String) -> void:
	_log_label.text = message
