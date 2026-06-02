extends Node2D

# Phase 4 run slice — validation target:
#   Start a run. Enter a generated room.
#   Detect room clear. Choose reward. Advance to the next room.
#
# Controls: WASD/Arrows = move, Space/J = melee, Q = fireball
#           1/2/3 = pick reward when prompted

@onready var _run_director: RunDirector = $RunDirector
@onready var player: Node = $Player
@onready var _room_label: Label = $HUD/StatsPanel/RoomInfo
@onready var _status_label: Label = $HUD/StatsPanel/RunStatus
@onready var _reward_label: Label = $HUD/StatsPanel/RewardStatus
@onready var _log_label: Label = $HUD/StatsPanel/EventLog
@onready var _hp_label: Label = $HUD/StatsPanel/PlayerHP
@onready var _instructions_label: Label = $HUD/Instructions

var _pending_rewards: Array[RewardOption] = []
var _log_lines: Array[String] = []


func _ready() -> void:
	_register_content()
	_connect_signals()
	_instructions_label.text = "Move: WASD / Arrows     Melee: Space / J     Fireball: Q\nKill all enemies to clear room. Press 1/2/3 to pick reward."
	_run_director.start_run(12345)


func _process(_delta: float) -> void:
	_update_hud()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1:
				_pick_reward(0)
			KEY_2:
				_pick_reward(1)
			KEY_3:
				_pick_reward(2)


# ── content registration ───────────────────────────────────────────────────────


func _register_content() -> void:
	var registry := ServiceRegistry.get_service("content") as ContentRegistry
	if registry == null:
		push_error("Phase4: ContentRegistry not available")
		return

	# Enemy definition pointing to the existing enemy scene
	var goblin := EntityDefinition.new()
	goblin.entity_definition_id = "enemy.goblin_basic"
	goblin.display_name = "Goblin"
	goblin.scene_path = "res://game/demo/entities/enemy/enemy.tscn"
	goblin.default_faction = "enemy"
	goblin.tags = ["enemy", "living", "melee"]
	goblin.base_stats = {"max_hp": 60.0, "attack_power": 8.0, "move_speed": 0.0, "defense": 0.0}
	registry.register_resource(goblin)

	# Room definitions
	var room01 := RoomDefinition.new()
	room01.room_id = "room.combat_01"
	room01.scene_path = "res://game/demo/rooms/combat_room_01.tscn"
	room01.room_type = "combat"
	room01.difficulty_rating = 1
	room01.enemy_spawn_ids = ["enemy.goblin_basic", "enemy.goblin_basic"]
	room01.reward_pool_ids = [
		"reward.attack_plus_20",
		"reward.max_hp_plus_20",
		"reward.move_speed_plus_15pct",
		"reward.defense_plus_5"
	]
	registry.register_resource(room01)

	var room02 := RoomDefinition.new()
	room02.room_id = "room.combat_02"
	room02.scene_path = "res://game/demo/rooms/combat_room_02.tscn"
	room02.room_type = "combat"
	room02.difficulty_rating = 1
	room02.enemy_spawn_ids = ["enemy.goblin_basic", "enemy.goblin_basic", "enemy.goblin_basic"]
	room02.reward_pool_ids = [
		"reward.attack_plus_20",
		"reward.max_hp_plus_20",
		"reward.move_speed_plus_15pct",
		"reward.defense_plus_5"
	]
	registry.register_resource(room02)

	# Reward definitions
	_register_reward(
		registry,
		"reward.attack_plus_20",
		"Power Up",
		"+20% attack power",
		"attack_power",
		StatModifierDefinition.Operation.PERCENT_ADD,
		0.20,
		"common",
		10.0
	)
	_register_reward(
		registry,
		"reward.max_hp_plus_20",
		"Vitality",
		"+20 max HP",
		"max_hp",
		StatModifierDefinition.Operation.FLAT_ADD,
		20.0,
		"common",
		10.0
	)
	_register_reward(
		registry,
		"reward.move_speed_plus_15pct",
		"Swift Feet",
		"+15% move speed",
		"move_speed",
		StatModifierDefinition.Operation.PERCENT_ADD,
		0.15,
		"rare",
		6.0
	)
	_register_reward(
		registry,
		"reward.defense_plus_5",
		"Iron Skin",
		"+5 defense",
		"defense",
		StatModifierDefinition.Operation.FLAT_ADD,
		5.0,
		"common",
		8.0
	)


func _register_reward(
	registry: ContentRegistry,
	reward_id: String,
	display_name: String,
	description: String,
	stat_id: String,
	op: StatModifierDefinition.Operation,
	value: float,
	rarity: String,
	weight: float
) -> void:
	var stat_effect := ApplyStatModifierEffect.new()
	stat_effect.effect_id = reward_id
	stat_effect.stat_id = stat_id
	stat_effect.operation = op
	stat_effect.value = value
	stat_effect.duration = -1.0

	var reward := RewardDefinition.new()
	reward.reward_id = reward_id
	reward.display_name = display_name
	reward.description = description
	reward.rarity = rarity
	reward.weight = weight
	reward.effects = [stat_effect]
	registry.register_resource(reward)


# ── signals ────────────────────────────────────────────────────────────────────


func _connect_signals() -> void:
	_run_director.run_started.connect(_on_run_started)
	_run_director.room_enter_requested.connect(_on_room_enter_requested)
	_run_director.choosing_reward.connect(_on_choosing_reward)
	_run_director.run_finished.connect(_on_run_finished)

	var events := ServiceRegistry.get_service("events") as EventRouter
	if events != null:
		events.entity_died.connect(_on_entity_died)
		events.room_cleared.connect(_on_room_cleared)


func _on_run_started(state: RunState) -> void:
	_log("[RUN] started  seed=%d  rooms=%d" % [state.seed, _run_director.run_length])


func _on_room_enter_requested(room_def_id: String) -> void:
	var idx := _run_director.run_state.current_room_index if _run_director.run_state != null else 0
	_log("[ROOM] entering room %d: %s" % [idx + 1, room_def_id])
	_pending_rewards.clear()


func _on_choosing_reward(options: Array[RewardOption]) -> void:
	_pending_rewards = options
	_log("[REWARD] room cleared! Pick reward:")
	for i in range(options.size()):
		_log(
			(
				"  %d) [%s] %s — %s"
				% [i + 1, options[i].rarity, options[i].display_name, options[i].description]
			)
		)
	_reward_label.text = "Room cleared! Press 1 / 2 / 3 to pick reward"


func _on_run_finished(result: String) -> void:
	_log("[RUN] finished: %s" % result)
	_reward_label.text = "Run %s!" % result


func _on_entity_died(entity_id: String, _ref: Node) -> void:
	_log("[DIED] %s" % entity_id)


func _on_room_cleared(room_id: String) -> void:
	_log("[EVENT] room_cleared: %s" % room_id)


func _pick_reward(index: int) -> void:
	if _pending_rewards.is_empty():
		return
	if index >= _pending_rewards.size():
		_log("[REWARD] invalid choice %d" % (index + 1))
		return
	var option := _pending_rewards[index]
	_run_director.select_reward(option)
	_log("[REWARD] picked: %s" % option.display_name)
	_pending_rewards.clear()
	_reward_label.text = "Reward: %s applied" % option.display_name


# ── HUD ────────────────────────────────────────────────────────────────────────


func _update_hud() -> void:
	var state := _run_director.run_state
	if state != null:
		_room_label.text = (
			"Run floor %d  room %d/%d  [%s]"
			% [
				state.current_floor,
				state.current_room_index + 1,
				_run_director.run_length,
				state.status
			]
		)
		_status_label.text = "Seed: %d  Rooms visited: %d" % [state.seed, state.room_history.size()]

	var health := player.get_node_or_null("Components/HealthComponent") as HealthComponent
	if health != null:
		_hp_label.text = "Player HP: %.0f / %.0f" % [health.current_hp, health.get_max_hp()]


func _log(line: String) -> void:
	print(line)
	_log_lines.append(line)
	if _log_lines.size() > 8:
		_log_lines.pop_front()
	if _log_label != null:
		_log_label.text = "\n".join(_log_lines)
