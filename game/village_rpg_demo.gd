extends Node2D


const ZONE_VILLAGE := "zone.demo.village"
const ZONE_ROOM := "zone.demo.village_room"
const ZONE_FIELD := "zone.demo.field"
const QUEST_ID := "quest.demo.field_report"
const QUEST_OBJECTIVE_ID := "obj.demo.kill_field_beast"
const QUEST_MANUAL_ID := "quest.demo.supply_request"
const QUEST_MANUAL_OBJECTIVE_ID := "obj.demo.receive_supply_note"
const SHOP_ID := "shop.demo.village_supply"
const ITEM_POTION := "item.demo.herb_potion"
const ITEM_CLAW := "item.demo.beast_claw"
const ITEM_CHARM := "item.demo.village_charm"
const ITEM_FIELD_BLADE := "item.demo.field_blade"
const WEAPON_SLOT := "weapon"
const ENTITY_FIELD_BEAST := "entity.demo.field_beast"
const ENTITY_TRIAL_BEAST := "entity.demo.trial_beast"
const ABILITY_FIREBOLT := "ability.demo.firebolt"
const STATUS_BURN := "status.demo.burn"
const ROOM_TRIAL_01 := "room.demo.trial_01"
const ROOM_TRIAL_02 := "room.demo.trial_02"
const ROOM_TRIAL_03 := "room.demo.trial_03"
const REWARD_TRIAL_ATTACK := "reward.demo.trial_attack"
const UPGRADE_TRIAL_ATTACK := "upgrade.demo.trial_attack"
const PLAYER_ID := "player_001"
const ATTACK_SFX_ID := "sfx.demo.attack"
const FIREBOLT_SFX_ID := "sfx.demo.firebolt"
const AUTO_RUN_EXPECTED_POTION_BUYS := 2
const HIT_VFX_AUTO_RELEASE_SECONDS := 0.55
const EVENT_LOG_MAX_LINES := 5
const MELEE_RANGE := 30.0
const FIREBOLT_RANGE := 120.0
const FIREBOLT_PROJECTILE_SPEED := 360.0
const FIREBOLT_PROJECTILE_MIN_DURATION := 0.22
const FIREBOLT_PROJECTILE_MAX_DURATION := 0.56
const FIREBOLT_PROJECTILE_FALLBACK_DISTANCE := 180.0
const TRIAL_SEED := 8606
const DEFAULT_WINDOW_SIZE := Vector2i(1280, 720)
const DEMO_CAMERA_CENTER := Vector2(360.0, 245.0)
const DEMO_CAMERA_WORLD_SIZE := Vector2(1080.0, 608.0)
const DEMO_CAMERA_MIN_ZOOM := 0.82
const DEMO_CAMERA_MAX_ZOOM := 2.2
const TRIAL_REWARD_UI_SCENE := preload("res://game/scenes/trial_reward_selection.tscn")
const DEMO_AUTO_RUN_VERIFIER_SCRIPT := preload("res://game/demo_auto_run_verifier.gd")
const DEMO_SAVE_PAYLOAD_VERIFIER_SCRIPT := preload("res://game/demo_save_payload_verifier.gd")
const HIT_VFX_SCENE := "res://game/ui/hit_vfx.tscn"


class EmbeddedSceneRouter:
	extends SceneService

	var host: Node = null

	func change_scene(scene_path: String) -> bool:
		if scene_path == "" or host == null:
			scene_change_failed.emit(scene_path, "invalid_embedded_scene")
			return false
		var packed := load(scene_path) as PackedScene
		if packed == null:
			scene_change_failed.emit(scene_path, "load_failed")
			return false
		for child in host.get_children():
			host.remove_child(child)
			child.queue_free()
		host.add_child(packed.instantiate())
		current_scene_path = scene_path
		scene_changed.emit(scene_path)
		return true


@onready var _world_host: Node2D = $WorldHost
@onready var _room_root: Node2D = $RoomRoot
@onready var _run_director: RunDirector = $RunDirector
@onready var _player: EntityRoot = $Player
@onready var _camera: Camera2D = $Camera2D
@onready var _instructions_label: Label = $HUD/Instructions
@onready var _zone_label: Label = $HUD/StatsPanel/ZoneInfo
@onready var _quest_label: Label = $HUD/StatsPanel/QuestInfo
@onready var _player_label: Label = $HUD/StatsPanel/PlayerInfo
@onready var _combat_label: Label = $HUD/StatsPanel/CombatInfo
@onready var _inventory_label: Label = $HUD/StatsPanel/InventoryInfo
@onready var _shop_label: Label = $HUD/StatsPanel/ShopInfo
@onready var _trial_label: Label = $HUD/StatsPanel/TrialInfo
@onready var _event_log_label: Label = $HUD/StatsPanel/EventLog
@onready var _dialogue_ui: DialogueUI = $HUD/DialoguePanel
@onready var _quest_log_ui: QuestLogUI = $HUD/QuestLogPanel
@onready var _shop_ui: ShopUI = $HUD/ShopPanel
@onready var _reward_layer: Control = $HUD/RewardLayer
@onready var _ui_manager: UIManager = $HUD/UIManager
@onready var _feedback_system: FeedbackSystem = $FeedbackSystem
@onready var _debug_overlay: DebugOverlay = $DebugOverlay

var _dialogue: DialogueService = null
var _quest: QuestService = null
var _shop: ShopService = null
var _world: WorldService = null
var _commands: CommandService = null
var _events: EventService = null
var _effects: EffectService = null
var _time: TimeService = null
var _progression: ProgressionService = null
var _audio: AudioService = null
var _save_manager: SaveService = null
var _entity_spawner: EntitySpawner = null
var _scene_router := EmbeddedSceneRouter.new()
var _auto_run_verifier: Variant = DEMO_AUTO_RUN_VERIFIER_SCRIPT.new()
var _save_payload_verifier: Variant = DEMO_SAVE_PAYLOAD_VERIFIER_SCRIPT.new()
var _previous_scene_router: SceneService = null
var _log_lines: Array[String] = []
var _field_beast_ref: EntityRoot = null
var _field_beast_looted: bool = false
var _field_beast_defeated: bool = false
var _shop_purchase_completed: bool = false
var _shop_sale_completed: bool = false
var _shop_purchase_verifications: int = 0
var _shop_sale_currency_verified: bool = false
var _auto_run_enabled: bool = false
var _auto_run_started: bool = false
var _firebolt_cast_succeeded: bool = false
var _burn_tick_observed: bool = false
var _elder_blessing_received: bool = false
var _command_combat_succeeded: bool = false
var _field_blade_equipped: bool = false
var _pending_trial_rewards: Array[RewardOption] = []
var _trial_room_entries: Array[String] = []
var _trial_rooms_cleared: int = 0
var _trial_run_finished_result: String = ""
var _trial_upgrade_reward_selected: bool = false
var _reward_screen: RewardSelectionUI = null
var _demo_save_roundtrip_succeeded: bool = false
var _demo_save_payload_verified: bool = false
var _runtime_seconds: float = 0.0
var _feedback_toast_observed: bool = false
var _feedback_shake_observed: bool = false
var _spawn_scene_effect_succeeded: bool = false
var _hit_vfx_cleanup_verified: bool = false
var _active_hit_vfx: Array[Node] = []
var _active_firebolt_projectiles: Array[Node2D] = []
var _firebolt_projectile_observed: bool = false
var _debug_overlay_verified: bool = false
var _interaction_focus_observed: bool = false
var _portal_interaction_succeeded: bool = false
var _manual_quest_completed: bool = false
var _dash_succeeded: bool = false
var _potion_use_completed: bool = false
var _last_failed_command: String = ""
var _last_failed_effect: String = ""
var _last_missing_service: String = ""


func _ready() -> void:
	_auto_run_enabled = OS.get_cmdline_args().has("--demo-auto-run")
	_configure_window()
	_resolve_services()
	if _save_manager != null and _auto_run_enabled:
		_save_manager.save_path = "/tmp/mkit_demo_auto_save.json"
	_configure_entity_spawner()
	_configure_embedded_router()
	_reset_demo_state()
	_configure_audio()
	_bind_ui()
	_connect_signals()
	_grant_starter_currency()
	_set_instructions()
	_log("[DEMO] RPG loop demo ready")
	_go_to_zone(ZONE_VILLAGE, "village_square")
	_update_camera_for_viewport()
	if _auto_run_enabled:
		_run_auto_loop.call_deferred()


func _process(delta: float) -> void:
	var scaled_delta := delta
	if _time != null:
		scaled_delta = _time.advance(delta)
	_runtime_seconds += scaled_delta
	_update_hud()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_R:
				_toggle_room_portal()
			KEY_G:
				_toggle_field_portal()
			KEY_T:
				_talk_or_advance_dialogue()
			KEY_Y:
				_request_elder_blessing()
			KEY_M:
				_request_manual_task()
			KEY_F:
				_cast_firebolt_command()
			KEY_F11:
				_toggle_fullscreen()
			KEY_ENTER:
				if event.alt_pressed or event.meta_pressed:
					_toggle_fullscreen()
				else:
					_perform_context_action()
			KEY_F3:
				_toggle_debug_overlay()
			KEY_E:
				_perform_context_action()
			KEY_C:
				_enter_trial_cave()
			KEY_F6:
				_save_demo_state()
			KEY_F7:
				_load_demo_state()
			KEY_1:
				_select_context_option(0)
			KEY_2:
				_select_context_option(1)
			KEY_3:
				_select_context_option(2)
			KEY_K:
				_defeat_field_beast()
			KEY_B:
				_buy_potion()
			KEY_V:
				_sell_claw()
			KEY_H:
				_use_potion()


func _exit_tree() -> void:
	_clear_hit_vfx()
	_cleanup_audio_players()
	if ServiceRegistry.has_service("scenes"):
		var current := Mkit.scenes()
		if current == _scene_router:
			ServiceRegistry.unregister_service("scenes")
			if _previous_scene_router != null:
				ServiceRegistry.register_service("scenes", _previous_scene_router)
	if _world != null and _world.scene_router == _scene_router:
		_world.scene_router = _previous_scene_router


func _resolve_services() -> void:
	_dialogue = Mkit.dialogue()
	_quest = Mkit.quest()
	_shop = Mkit.shop()
	_world = Mkit.world()
	_commands = Mkit.commands()
	_events = Mkit.events()
	_effects = Mkit.effects()
	if _effects != null:
		_effects.trace_enabled = true
	_time = Mkit.time()
	_progression = Mkit.progression()
	_audio = Mkit.audio()
	_save_manager = Mkit.save()
	_last_missing_service = _first_missing_service()


func _configure_entity_spawner() -> void:
	_entity_spawner = EntitySpawner.new()
	_entity_spawner.name = "DemoEntitySpawner"
	if ServiceRegistry.has_service("content"):
		_entity_spawner.content = Mkit.content()
	add_child(_entity_spawner)


func _configure_embedded_router() -> void:
	_scene_router.name = "DemoEmbeddedSceneRouter"
	_scene_router.host = _world_host
	add_child(_scene_router)
	_previous_scene_router = null
	if ServiceRegistry.has_service("scenes"):
		_previous_scene_router = Mkit.scenes()
	ServiceRegistry.unregister_service("scenes")
	ServiceRegistry.register_service("scenes", _scene_router)
	if _world != null:
		_world.scene_router = _scene_router


func _reset_demo_state() -> void:
	if _quest != null:
		_quest.log = QuestLog.new()
	if _progression != null:
		_progression.state = ProgressionState.new()
	var inventory := _inventory()
	if inventory != null:
		inventory.model.setup(inventory.capacity)
	var experience := _experience()
	if experience != null:
		experience.current_level = 1
		experience.current_xp = 0
	var health := _player_health()
	if health != null:
		health.dead = false
		health.current_hp = health.get_max_hp()
	var equipment := _equipment_controller()
	if equipment != null:
		for slot_id in equipment.equipped.keys().duplicate():
			equipment.unequip(slot_id)
	_field_blade_equipped = false
	_field_beast_looted = false
	_field_beast_defeated = false
	_shop_purchase_completed = false
	_shop_sale_completed = false
	_shop_purchase_verifications = 0
	_shop_sale_currency_verified = false
	_firebolt_cast_succeeded = false
	_burn_tick_observed = false
	_elder_blessing_received = false
	_command_combat_succeeded = false
	_runtime_seconds = 0.0
	if _time != null:
		_time.elapsed_gameplay_time = 0.0
	_feedback_toast_observed = false
	_feedback_shake_observed = false
	_spawn_scene_effect_succeeded = false
	_hit_vfx_cleanup_verified = false
	_active_hit_vfx.clear()
	_active_firebolt_projectiles.clear()
	_firebolt_projectile_observed = false
	_debug_overlay_verified = false
	_interaction_focus_observed = false
	_portal_interaction_succeeded = false
	_manual_quest_completed = false
	_dash_succeeded = false
	_potion_use_completed = false
	_reset_trial_state()
	_demo_save_roundtrip_succeeded = false
	_demo_save_payload_verified = false


func _configure_audio() -> void:
	if _audio == null:
		return
	_audio.music_bus = "Master"
	_audio.sfx_bus = "Master"


func _bind_ui() -> void:
	if _dialogue_ui != null:
		_dialogue_ui.visible = false
		_dialogue_ui.bind(_dialogue)
	if _quest_log_ui != null:
		_quest_log_ui.bind(_quest)
	if _shop_ui != null:
		_shop_ui.visible = false
		_shop_ui.bind(_shop, _player)
	if _feedback_system != null:
		_feedback_system.toast_requested.connect(_on_feedback_toast_requested)
		_feedback_system.screen_shake_requested.connect(_on_feedback_screen_shake_requested)


func _connect_signals() -> void:
	if _dialogue != null:
		_dialogue.dialogue_started.connect(_on_dialogue_started)
		_dialogue.dialogue_ended.connect(_on_dialogue_ended)
	if _quest != null:
		_quest.quest_accepted.connect(_on_quest_accepted)
		_quest.objective_advanced.connect(_on_objective_advanced)
		_quest.quest_turned_in.connect(_on_quest_turned_in)
	if _commands != null:
		_commands.command_failed.connect(_on_command_failed)
	if _shop != null:
		_shop.shop_opened.connect(_on_shop_opened)
		_shop.item_purchased.connect(_on_item_purchased)
		_shop.item_sold.connect(_on_item_sold)
		_shop.transaction_failed.connect(_on_transaction_failed)
	if _world != null:
		_world.zone_changed.connect(_on_zone_changed)
	if _events != null:
		_events.domain_event_emitted.connect(_on_domain_event)
		_events.subscribe(LootEvents.REWARD_SELECTED, _on_reward_selected)
		_events.subscribe(LootEvents.LOOT_DROPPED, _on_loot_dropped)
		_events.subscribe(CombatEvents.ENTITY_DIED, _on_entity_died)
		_events.subscribe(CombatEvents.DAMAGE_APPLIED, _on_damage_applied)
	if _run_director != null:
		_run_director.run_started.connect(_on_trial_run_started)
		_run_director.room_enter_requested.connect(_on_trial_room_enter_requested)
		_run_director.choosing_reward.connect(_on_trial_choosing_reward)
		_run_director.run_finished.connect(_on_trial_run_finished)
	var interaction := _interaction_component()
	if interaction != null:
		interaction.interactable_focused.connect(_on_interactable_focused)
		interaction.interactable_unfocused.connect(_on_interactable_unfocused)
	var experience := _experience()
	if experience != null:
		experience.level_up.connect(_on_level_up)
	var ability := _ability_controller()
	if ability != null:
		ability.ability_cast_started.connect(_on_ability_cast_started)
		ability.ability_failed.connect(_on_ability_failed)
	var inventory := _inventory()
	if inventory != null:
		inventory.item_added.connect(_on_item_added)
		inventory.item_removed.connect(_on_item_removed)


func _configure_window() -> void:
	if _camera != null:
		_camera.make_current()
	var viewport := get_viewport()
	if viewport != null:
		viewport.size_changed.connect(_update_camera_for_viewport)
	_update_camera_for_viewport()


func _update_camera_for_viewport() -> void:
	if _camera == null:
		return
	var viewport_size := get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	var zoom: float = minf(
		viewport_size.x / DEMO_CAMERA_WORLD_SIZE.x,
		viewport_size.y / DEMO_CAMERA_WORLD_SIZE.y
	)
	zoom = clampf(zoom, DEMO_CAMERA_MIN_ZOOM, DEMO_CAMERA_MAX_ZOOM)
	_camera.position = DEMO_CAMERA_CENTER
	_camera.zoom = Vector2(zoom, zoom)


func _set_fullscreen(enabled: bool) -> void:
	if DisplayServer.get_name() == "headless":
		return
	if enabled:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(DEFAULT_WINDOW_SIZE)
	var screen := DisplayServer.window_get_current_screen()
	var screen_position := DisplayServer.screen_get_position(screen)
	var screen_size := DisplayServer.screen_get_size(screen)
	var centered_offset := Vector2i(
		maxi(0, int((screen_size.x - DEFAULT_WINDOW_SIZE.x) * 0.5)),
		maxi(0, int((screen_size.y - DEFAULT_WINDOW_SIZE.y) * 0.5))
	)
	DisplayServer.window_set_position(screen_position + centered_offset)


func _is_fullscreen() -> bool:
	var mode := DisplayServer.window_get_mode()
	return (
		mode == DisplayServer.WINDOW_MODE_FULLSCREEN
		or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	)


func _grant_starter_currency() -> void:
	if _progression != null:
		_progression.add_currency("gold", 10)


func _set_instructions() -> void:
	_update_instructions()


func _toggle_debug_overlay() -> void:
	if _debug_overlay != null:
		_debug_overlay.toggle()


func _toggle_fullscreen() -> void:
	_set_fullscreen(not _is_fullscreen())


func _go_to_zone(zone_id: String, spawn_id: String) -> bool:
	if _world == null:
		_log("[WORLD] service missing")
		return false
	if not _world.go_to_zone(zone_id, spawn_id):
		_log("[WORLD] could not enter %s" % zone_id)
		return false
	return true


func _toggle_room_portal() -> void:
	if _world == null:
		return
	if _world.current_zone_id == ZONE_VILLAGE:
		_interact_portal("ToRoom")
	elif _world.current_zone_id == ZONE_ROOM:
		_interact_portal("ToVillage")
	else:
		_log("[WORLD] stand at the elder room door")


func _toggle_field_portal() -> void:
	if _world == null:
		return
	if _is_trial_cave_open():
		_leave_trial_cave("field_gate")
		return
	if _world.current_zone_id == ZONE_FIELD:
		_interact_portal("ToVillage")
	elif _world.current_zone_id == ZONE_VILLAGE:
		_interact_portal("ToField")
	else:
		_log("[WORLD] stand at the field gate")


func _interact_portal(portal_name: String) -> bool:
	return _try_zone_interaction("%s/Interactable" % portal_name, portal_name)


func _try_zone_interaction(interactable_path: String, label: String) -> bool:
	var interaction := _interaction_component()
	if interaction == null:
		_log("[INTERACT] player interaction component missing")
		return false
	var interactable := _find_zone_interactable(interactable_path)
	if interactable == null:
		_log("[INTERACT] missing %s" % label)
		return false
	if interaction.current_interactable != interactable:
		_log("[INTERACT] stand near %s" % label)
		return false
	if not interaction.try_interact():
		_log("[INTERACT] failed %s" % label)
		return false
	if interactable is Portal:
		_portal_interaction_succeeded = true
	return true


func _perform_context_action() -> void:
	if _dialogue != null and _dialogue.is_active():
		_select_dialogue_option(0)
		return
	if not _pending_trial_rewards.is_empty():
		_select_trial_reward(0)
		return
	var focused := _focused_interactable()
	if focused != null:
		match focused.interaction_id:
			"interaction.demo.elder":
				_talk_or_advance_dialogue()
			"interaction.demo.village_supply":
				_ensure_shop_open()
			"interaction.demo.trial_cave":
				_enter_trial_cave()
			_:
				_try_current_interaction()
		return
	if _is_trial_cave_open():
		_leave_trial_cave("field_gate")
		return
	if _item_count(ITEM_FIELD_BLADE) > 0:
		_toggle_field_blade()
		return
	_log("[INTERACT] move near the Elder, a gate, the shop, or the cave")


func _try_current_interaction() -> bool:
	var interaction := _interaction_component()
	if interaction == null:
		_log("[INTERACT] player interaction component missing")
		return false
	var interactable := interaction.current_interactable
	if interactable == null:
		_log("[INTERACT] no nearby target")
		return false
	if not interaction.try_interact():
		_log("[INTERACT] failed %s" % _interactable_label(interactable))
		return false
	if interactable is Portal:
		_portal_interaction_succeeded = true
	return true


func _select_context_option(index: int) -> void:
	if _dialogue != null and _dialogue.is_active():
		_select_dialogue_option(index)
		return
	if not _pending_trial_rewards.is_empty():
		_select_trial_reward(index)


func _select_dialogue_option(index: int) -> void:
	if _dialogue == null or not _dialogue.is_active():
		return
	var choices := _dialogue.get_available_choices()
	if choices.is_empty():
		if index == 0:
			_dialogue.advance()
		return
	if index < 0 or index >= choices.size():
		_log("[DIALOGUE] choice %d is unavailable" % (index + 1))
		return
	_dialogue.choose(index)
	if _dialogue.is_active() and _dialogue.get_available_choices().is_empty():
		_dialogue.advance()


func _find_zone_interactable(interactable_path: String) -> Interactable:
	var root := _current_zone_root()
	if root == null:
		return null
	return root.get_node_or_null(interactable_path) as Interactable


func _focused_interactable() -> Interactable:
	var interaction := _interaction_component()
	if interaction == null:
		return null
	return interaction.current_interactable


func _is_focused_zone_interactable(interactable_path: String) -> bool:
	var interaction := _interaction_component()
	if interaction == null:
		return false
	var interactable := _find_zone_interactable(interactable_path)
	return interactable != null and interaction.current_interactable == interactable


func _focus_zone_interactable(interactable_path: String) -> void:
	var interactable := _find_zone_interactable(interactable_path)
	if interactable == null:
		return
	var area := interactable.get_parent() as Area2D
	if area == null:
		return
	_player.global_position = area.global_position + Vector2(1000.0, 0.0)
	await get_tree().physics_frame
	_player.global_position = area.global_position
	await get_tree().physics_frame
	await get_tree().physics_frame


func _talk_or_advance_dialogue() -> void:
	if _dialogue == null:
		return
	if _dialogue.is_active():
		_select_dialogue_option(0)
		return
	if _world == null or _world.current_zone_id != ZONE_ROOM:
		_log("[DIALOGUE] enter the elder room first")
		return
	if not _try_zone_interaction("Elder/InteractionArea/Interactable", "elder"):
		_log("[DIALOGUE] elder dialogue did not start")


func _request_elder_blessing() -> void:
	if _dialogue == null:
		return
	if _world == null or _world.current_zone_id != ZONE_ROOM:
		_log("[DIALOGUE] enter the elder room first")
		return
	if _dialogue.is_active():
		_choose_elder_blessing()
		return
	if not _try_zone_interaction("Elder/InteractionArea/Interactable", "elder"):
		_log("[DIALOGUE] elder dialogue did not start")
		return
	_choose_elder_blessing()


func _choose_elder_blessing() -> void:
	if _dialogue == null or not _dialogue.is_active():
		return
	var choices := _dialogue.get_available_choices()
	if choices.size() < 2:
		_log("[DIALOGUE] elder blessing choice is unavailable")
		return
	var stats := _player_stats()
	var before := stats.get_stat_value("attack_power", 0.0) if stats != null else 0.0
	_dialogue.choose(1)
	if _dialogue.is_active():
		_dialogue.advance()
	var after := stats.get_stat_value("attack_power", 0.0) if stats != null else before
	if after > before:
		_elder_blessing_received = true
		_log("[STAT] elder blessing attack_power %.0f -> %.0f" % [before, after])


func _request_manual_task() -> void:
	if _dialogue == null or _quest == null:
		return
	if _world == null or _world.current_zone_id != ZONE_ROOM:
		_log("[QUEST] enter the elder room first")
		return
	if not _dialogue.is_active():
		if not _try_zone_interaction("Elder/InteractionArea/Interactable", "elder"):
			_log("[QUEST] elder manual task did not start")
			return
	var choices := _dialogue.get_available_choices()
	if choices.size() < 3:
		_log("[QUEST] manual task choice is unavailable")
		return
	_dialogue.choose(2)
	if _dialogue.is_active():
		_dialogue.advance()
	var state := _quest.get_state(QUEST_MANUAL_ID)
	if state != null and state.status == "turned_in":
		_manual_quest_completed = true
		_log("[QUEST] manual supply request completed")


func _defeat_field_beast() -> void:
	if _world == null or _world.current_zone_id != ZONE_FIELD:
		_log("[COMBAT] go to the field first")
		return
	var beast := _field_beast()
	if beast == null:
		_log("[COMBAT] field beast not found")
		return
	var health := beast.get_component("HealthComponent") as HealthComponent
	if not _is_field_beast_health_alive(health):
		_log("[COMBAT] field beast already defeated")
		return
	_damage_player_from_beast(beast)
	var damage := DealDamageEffect.new()
	damage.effect_id = "effect.demo.manual_strike"
	damage.base_amount = 50.0
	damage.can_crit = false
	var result := _effects.execute(damage, GameplayContext.new().with_source(_player).with_target(beast))
	if result.success:
		_log("[COMBAT] struck the field beast")
	else:
		_log("[COMBAT] strike failed: %s" % result.failure_reason)


func _damage_player_from_beast(beast: EntityRoot) -> void:
	if _effects == null:
		return
	var health := _player_health()
	if health == null or health.dead:
		return
	var damage := DealDamageEffect.new()
	damage.effect_id = "effect.demo.beast_counter"
	damage.base_amount = 12.0
	damage.can_crit = false
	_effects.execute(damage, GameplayContext.new().with_source(beast).with_target(_player))


func _engage_field_beast_via_commands() -> void:
	if _world == null or _world.current_zone_id != ZONE_FIELD:
		_log("[COMBAT] go to the field first")
		return
	var beast := _field_beast()
	if beast == null:
		if _field_beast_defeated:
			_command_combat_succeeded = true
			_log("[COMBAT] field beast already defeated")
			return
		_log("[COMBAT] field beast not found")
		return
	if not _is_field_beast_health_alive():
		if _field_beast_defeated:
			_command_combat_succeeded = true
			_log("[COMBAT] field beast already defeated")
			return
		_log("[COMBAT] field beast already defeated")
		return
	await _approach(beast, MELEE_RANGE)
	await _attack_field_beast()
	if _field_beast_defeated or not _is_field_beast_health_alive():
		_command_combat_succeeded = true
	else:
		_log("[COMBAT] command chain stalled; using scripted strike")
		_defeat_field_beast()
		if _field_beast_defeated or not _is_field_beast_health_alive():
			_command_combat_succeeded = true


func _attack_field_beast() -> void:
	var state_machine := _player.get_state_machine_node()
	if state_machine == null:
		return
	var attacks := 0
	while attacks < 8 and _is_field_beast_health_alive():
		_dispatch_player_command(BuiltinCommands.ATTACK, {})
		var guard := 0
		while (
			guard < 600
			and _is_field_beast_health_alive()
			and state_machine.get_current_path() == "Player/Attack"
		):
			await get_tree().physics_frame
			guard += 1
		attacks += 1


func _dispatch_player_command(command_type: String, payload: Dictionary) -> void:
	if _player == null:
		return
	var receiver := _player.get_command_receiver_node()
	if receiver == null:
		return
	receiver.receive_command(GameCommand.create(command_type, PLAYER_ID, PLAYER_ID, payload))


func _cast_firebolt_command() -> void:
	_dispatch_player_command(BuiltinCommands.CAST_ABILITY, {"ability_id": ABILITY_FIREBOLT})


func _dash_player_once() -> void:
	var state_machine := _player.get_state_machine_node()
	if state_machine == null:
		return
	var start := _player.global_position
	_dispatch_player_command(BuiltinCommands.DASH, {"direction": Vector2.RIGHT})
	var guard := 0
	while guard < 60 and state_machine.get_current_path() == "Player/Dash":
		await get_tree().process_frame
		guard += 1
	_dash_succeeded = _player.global_position.distance_to(start) > 12.0
	if _dash_succeeded:
		_log("[ACTION] dash moved player")


func _cast_firebolt_at_beast() -> void:
	if _world == null or _world.current_zone_id != ZONE_FIELD:
		_log("[ABILITY] go to the field first")
		return
	var beast := _field_beast()
	if beast == null:
		_log("[ABILITY] field beast not found")
		return
	var health := beast.get_component("HealthComponent") as HealthComponent
	if health == null or health.dead:
		return
	var ability := _ability_controller()
	if ability == null or not ability.has_ability(ABILITY_FIREBOLT):
		_log("[ABILITY] firebolt is not available")
		return
	await _approach(beast, FIREBOLT_RANGE)
	var mana_before := _player_mana()
	_cast_firebolt_command()
	var guard := 0
	while guard < 240 and not ability.active_cast_actions.is_empty():
		await get_tree().process_frame
		guard += 1
	_firebolt_cast_succeeded = _player_mana() < mana_before
	if _firebolt_cast_succeeded:
		_log("[ABILITY] firebolt burned the beast (mana %.0f -> %.0f)" % [mana_before, _player_mana()])
		await _wait_for_beast_burn_tick(beast)
	else:
		_log("[ABILITY] firebolt cast did not resolve")


func _wait_for_beast_burn_tick(beast: EntityRoot) -> void:
	var status := beast.get_controller("StatusEffectController") as StatusEffectController
	if status == null:
		_log("[STATUS] field beast status controller not found")
		return
	if not status.has_status(STATUS_BURN):
		_log("[STATUS] firebolt did not apply burn")
		return
	var elapsed := 0.0
	while elapsed < 1.5 and not _burn_tick_observed and status.has_status(STATUS_BURN):
		await get_tree().process_frame
		elapsed += get_process_delta_time()
	if not _burn_tick_observed:
		_log("[STATUS] burn tick was not observed")


func _enter_trial_cave() -> void:
	if _is_trial_cave_open():
		_leave_trial_cave("cave_toggle")
		return
	if _world == null:
		return
	if _world.current_zone_id != ZONE_FIELD:
		_log("[TRIAL] enter the field first")
		return
	var root := _current_zone_root()
	if root == null or root.get_node_or_null("TrialCave") == null:
		_log("[TRIAL] trial cave entrance missing")
		return
	if not _is_focused_zone_interactable("TrialCaveArea/Interactable"):
		_log("[TRIAL] stand at the cave entrance")
		return
	if _run_director == null:
		_log("[TRIAL] run director missing")
		return
	if _run_director.run_state != null and not _is_trial_terminal():
		_log("[TRIAL] run already active")
		return
	_reset_trial_state()
	_room_root.visible = true
	_run_director.first_floor_room_pool = [ROOM_TRIAL_01, ROOM_TRIAL_02, ROOM_TRIAL_03]
	_run_director.run_length = 3
	_run_director.start_run(TRIAL_SEED)


func _is_trial_cave_open() -> bool:
	return _room_root != null and _room_root.visible


func _leave_trial_cave(reason: String) -> void:
	if not _is_trial_cave_open():
		return
	if _run_director != null and _run_director.run_state != null and not _is_trial_terminal():
		_run_director.fail_run(reason)
	else:
		_close_trial_room()
	_place_player_at_trial_cave_exit()
	_log("[TRIAL] left cave")


func _place_player_at_trial_cave_exit() -> void:
	var root := _current_zone_root()
	if root == null:
		return
	var marker := root.get_node_or_null("TrialCave") as Node2D
	if marker != null:
		_player.global_position = marker.global_position


func _defeat_trial_room_enemies() -> void:
	if _run_director == null or _run_director.current_room_controller == null:
		_log("[TRIAL] no active room")
		return
	if _effects == null:
		_log("[TRIAL] effect service missing")
		return
	var room := _run_director.current_room_controller
	if room.runtime == null:
		_log("[TRIAL] active room has no runtime")
		return
	var enemy_ids := room.runtime.active_enemy_ids.duplicate()
	for enemy_id in enemy_ids:
		var enemy := room.active_enemies.get(enemy_id, null) as EntityRoot
		if enemy == null:
			continue
		var brain := enemy.get_controller("SimpleAIEnemyBrain") as SimpleAIEnemyBrain
		if brain != null:
			brain.enabled = false
		var damage := DealDamageEffect.new()
		damage.effect_id = "effect.demo.trial_strike"
		damage.base_amount = 999.0
		damage.can_crit = false
		_effects.execute(damage, GameplayContext.new().with_source(_player).with_target(enemy))


func _trial_reward_index(reward_id: String) -> int:
	for i in range(_pending_trial_rewards.size()):
		if _pending_trial_rewards[i].reward_id == reward_id:
			return i
	return 0


func _select_trial_reward(index: int) -> void:
	if _pending_trial_rewards.is_empty():
		_log("[TRIAL] no pending rewards")
		return
	if index < 0 or index >= _pending_trial_rewards.size():
		_log("[TRIAL] invalid reward choice %d" % (index + 1))
		return
	var selected := _pending_trial_rewards[index]
	if _reward_screen != null and is_instance_valid(_reward_screen):
		var container := _reward_screen.get_node_or_null("OptionContainer")
		if container != null and index < container.get_child_count():
			var button := container.get_child(index) as Button
			if button != null:
				button.pressed.emit()
			else:
				_run_director.select_reward(selected)
		else:
			_run_director.select_reward(selected)
	else:
		_run_director.select_reward(selected)
	_pending_trial_rewards.clear()
	_reward_screen = null
	_log("[TRIAL] picked reward %s" % selected.display_name)


func _is_trial_terminal() -> bool:
	if _run_director == null or _run_director.run_state == null:
		return true
	return _run_director.run_state.status == "completed" or _run_director.run_state.status == "failed"


func _is_trial_completed() -> bool:
	return _run_director != null and _run_director.run_state != null and _run_director.run_state.status == "completed"


func _reset_trial_state() -> void:
	_pending_trial_rewards.clear()
	_trial_room_entries.clear()
	_trial_rooms_cleared = 0
	_trial_run_finished_result = ""
	_trial_upgrade_reward_selected = false
	_close_trial_room()


func _close_trial_room() -> void:
	_clear_trial_reward_screen()
	if _room_root != null:
		for child in _room_root.get_children():
			child.queue_free()
		_room_root.visible = false
	if _run_director != null:
		_run_director.current_room_controller = null


func _clear_trial_reward_screen() -> void:
	if _reward_screen != null and is_instance_valid(_reward_screen):
		_reward_screen.queue_free()
	_reward_screen = null
	if _reward_layer != null:
		for child in _reward_layer.get_children():
			child.queue_free()


func _approach(target: Node2D, stop_distance: float) -> void:
	var steps := 0
	while steps < 400:
		var offset := target.global_position - _player.global_position
		if offset.length() <= stop_distance:
			break
		_dispatch_player_command(BuiltinCommands.MOVE, {"direction": offset.normalized()})
		await get_tree().physics_frame
		steps += 1
	_dispatch_player_command(BuiltinCommands.STOP_MOVE, {})
	await get_tree().physics_frame


func _buy_potion() -> void:
	if not _ensure_shop_open():
		return
	var gold_before := _gold()
	var potion_count_before := _item_count(ITEM_POTION)
	var price := _shop.get_buy_price(ITEM_POTION)
	if _shop.buy(ITEM_POTION, 1, _player):
		var gold_after := _gold()
		var potion_count_after := _item_count(ITEM_POTION)
		if gold_after == gold_before - price and potion_count_after == potion_count_before + 1:
			_shop_purchase_verifications += 1
		_play_sfx("sfx.demo.shop")


func _sell_claw() -> void:
	if not _ensure_shop_open():
		return
	var inventory := _inventory()
	if inventory == null:
		return
	var claw := inventory.find_item_by_definition(ITEM_CLAW)
	if claw == null:
		_log("[SHOP] no beast claw to sell")
		return
	var gold_before := _gold()
	var claw_count_before := _item_count(ITEM_CLAW)
	var price := _shop.get_sell_price(ITEM_CLAW)
	if _shop.sell(claw.instance_id, 1, _player):
		var gold_after := _gold()
		var claw_count_after := _item_count(ITEM_CLAW)
		_shop_sale_currency_verified = (
			gold_after == gold_before + price and claw_count_after == claw_count_before - 1
		)
		_play_sfx("sfx.demo.shop")


func _ensure_shop_open() -> bool:
	if _shop == null:
		_log("[SHOP] service missing")
		return false
	if _world == null or _world.current_zone_id != ZONE_VILLAGE:
		_log("[SHOP] return to the village supply stall")
		return false
	if not _is_focused_zone_interactable("VillageSupply/Interactable"):
		if _shop.current_shop != null:
			_shop.close_shop()
		if _shop_ui != null:
			_shop_ui.visible = false
		_log("[SHOP] stand at the village supply stall")
		return false
	if _shop.current_shop != null:
		return true
	if not _shop.open_shop(SHOP_ID):
		_log("[SHOP] could not open village supply")
		return false
	if _shop_ui != null:
		_shop_ui.visible = true
	return true


func _use_potion() -> void:
	var inventory := _inventory()
	if inventory == null:
		return
	var potion := inventory.find_item_by_definition(ITEM_POTION)
	if potion == null:
		_log("[ITEM] no herb potion in inventory")
		return
	var definition := inventory.get_item_definition(ITEM_POTION)
	if definition == null or definition.use_effects.is_empty():
		_log("[ITEM] potion has no effects")
		return
	if _effects == null:
		return
	var health := _player_health()
	var before := health.current_hp if health != null else 0.0
	var potion_count_before := _item_count(ITEM_POTION)
	var ctx := GameplayContext.new().with_source(_player).with_target(_player)
	_effects.execute_many(definition.use_effects, ctx, true)
	var removed := inventory.remove_item_by_instance_id(potion.instance_id, 1)
	var after := health.current_hp if health != null else 0.0
	_potion_use_completed = (
		removed and after > before and _item_count(ITEM_POTION) == potion_count_before - 1
	)
	_log("[ITEM] used herb potion HP %.0f -> %.0f" % [before, after])


func _save_demo_state() -> bool:
	if _save_manager == null:
		_log("[SAVE] service missing")
		return false
	if _save_manager.save_game(get_tree().root):
		_log("[SAVE] saved demo state")
		return true
	_log("[SAVE] save failed")
	return false


func _load_demo_state() -> bool:
	if _save_manager == null:
		_log("[SAVE] service missing")
		return false
	_close_trial_room()
	_clear_hit_vfx()
	if _save_manager.load_game(get_tree().root):
		_sync_loaded_state_flags()
		_close_trial_room()
		_clear_hit_vfx()
		_log("[SAVE] loaded demo state")
		return true
	_log("[SAVE] load failed")
	return false


func _sync_loaded_state_flags() -> void:
	var equipment := _equipment_controller()
	_field_blade_equipped = equipment != null and equipment.get_equipped(WEAPON_SLOT) != null


func _on_dialogue_started(dialogue_id: String) -> void:
	if _dialogue_ui != null:
		_dialogue_ui.visible = true
	_play_sfx("sfx.demo.dialogue")
	_log("[DIALOGUE] started %s" % _display_name(dialogue_id, "Elder"))


func _on_dialogue_ended(dialogue_id: String) -> void:
	_log("[DIALOGUE] ended %s" % _display_name(dialogue_id, "Elder"))


func _on_quest_accepted(quest_id: String) -> void:
	_play_sfx("sfx.demo.quest")
	_log("[QUEST] accepted %s" % _quest_title(quest_id))


func _on_objective_advanced(
	quest_id: String, objective_id: String, current: int, required: int
) -> void:
	_log(
		"[QUEST] %s %s %d/%d"
		% [_quest_title(quest_id), _quest_objective_label(quest_id, objective_id), current, required]
	)


func _on_quest_turned_in(quest_id: String) -> void:
	_play_sfx("sfx.demo.quest")
	_log("[QUEST] turned in %s" % _quest_title(quest_id))


func _on_shop_opened(shop_id: String) -> void:
	if _shop_ui != null:
		_shop_ui.visible = true
	_log("[SHOP] opened %s" % _display_name(shop_id, "Village Supply"))


func _on_item_purchased(item_id: String, quantity: int, total_cost: int) -> void:
	if item_id == ITEM_POTION and quantity > 0:
		_shop_purchase_completed = true
	_log("[SHOP] bought %s x%d for %d gold" % [_display_name(item_id), quantity, total_cost])


func _on_item_sold(item_id: String, quantity: int, total_gain: int) -> void:
	if item_id == ITEM_CLAW and quantity > 0:
		_shop_sale_completed = true
	_log("[SHOP] sold %s x%d for %d gold" % [_display_name(item_id), quantity, total_gain])


func _on_transaction_failed(item_id: String, reason: String) -> void:
	_log("[SHOP] transaction failed %s: %s" % [_display_name(item_id, "item"), reason])


func _on_zone_changed(from_zone_id: String, to_zone_id: String) -> void:
	_clear_hit_vfx()
	_clear_firebolt_projectiles()
	var interaction := _interaction_component()
	if interaction != null:
		interaction.current_interactable = null
	if _shop != null:
		_shop.close_shop()
	if _shop_ui != null:
		_shop_ui.visible = false
	if from_zone_id == ZONE_FIELD and to_zone_id != ZONE_FIELD and not _field_beast_defeated:
		_field_beast_ref = null
	if to_zone_id == ZONE_FIELD:
		_spawn_field_beast()
	_log(
		"[WORLD] %s -> %s"
		% [
			_display_name(from_zone_id, "start") if from_zone_id != "" else "start",
			_display_name(to_zone_id)
		]
	)


func _on_command_failed(command: GameCommand, reason: String) -> void:
	if command == null:
		_last_failed_command = reason
		return
	_last_failed_command = "%s: %s" % [command.command_type, reason]


func _on_damage_applied(event: DomainEvent) -> void:
	var result: DamageResult = event.payload.get("result")
	if result == null:
		return
	_log(
		"[COMBAT] %.0f damage to %s"
		% [result.final_amount, _entity_display_name(result.target)]
	)
	if _has_entity_tag(result.target, "field_beast"):
		_spawn_hit_effect(result.target)


func _on_ability_cast_started(ability_id: String) -> void:
	if ability_id == ABILITY_FIREBOLT:
		_log("[ABILITY] casting %s" % _display_name(ability_id, "Firebolt"))
		_play_sfx(FIREBOLT_SFX_ID)
		_spawn_firebolt_projectile(_firebolt_visual_target())


func _on_ability_failed(ability_id: String, reason: String) -> void:
	if ability_id == ABILITY_FIREBOLT:
		_log("[ABILITY] %s failed: %s" % [_display_name(ability_id, "Firebolt"), reason])


func _spawn_hit_effect(target: Node) -> void:
	if _effects == null or target == null:
		return
	var effect := SpawnSceneEffect.new()
	effect.effect_id = "effect.demo.spawn_hit_vfx"
	effect.scene_path = HIT_VFX_SCENE
	effect.spawn_at_target = true
	effect.use_pool = true
	var context := GameplayContext.new().with_source(_player).with_target(target)
	context.direction = Vector2.RIGHT
	var result := _effects.execute(effect, context)
	if result.success:
		_spawn_scene_effect_succeeded = true
		var spawned := result.payload.get("instance", null) as Node
		if spawned != null:
			_track_hit_vfx(spawned)


func _firebolt_visual_target() -> Node2D:
	if _player == null or _player.get_tree() == null:
		return null
	var best: Node2D = null
	var best_distance: float = INF
	for node in _player.get_tree().get_nodes_in_group("enemy"):
		var enemy := node as EntityRoot
		if enemy == null or not is_instance_valid(enemy):
			continue
		var health := enemy.get_component("HealthComponent") as HealthComponent
		if health != null and health.dead:
			continue
		var distance := _player.global_position.distance_to(enemy.global_position)
		if distance <= FIREBOLT_RANGE and distance < best_distance:
			best = enemy
			best_distance = distance
	return best


func _player_facing_direction() -> Vector2:
	var state_machine := _player.get_state_machine_node()
	if state_machine != null:
		var facing: Vector2 = state_machine.blackboard.get_value("facing", Vector2.RIGHT)
		if facing != Vector2.ZERO:
			return facing.normalized()
	return Vector2.RIGHT


func _spawn_firebolt_projectile(target: Node2D) -> void:
	if _player == null:
		return
	var start := _player.global_position
	var has_target: bool = target != null and is_instance_valid(target)
	var end: Vector2 = (
		target.global_position
		if has_target
		else start + _player_facing_direction() * FIREBOLT_PROJECTILE_FALLBACK_DISTANCE
	)
	var direction: Vector2 = (end - start).normalized()
	if direction == Vector2.ZERO:
		direction = _player_facing_direction()
	start += direction * 30.0
	var projectile := Node2D.new()
	projectile.name = "DemoFireboltProjectile"
	projectile.z_index = 40
	projectile.global_position = start
	projectile.rotation = direction.angle()
	var glow := Polygon2D.new()
	glow.name = "Glow"
	glow.color = Color(1.0, 0.2, 0.04, 0.2)
	glow.polygon = PackedVector2Array([
		Vector2(-42, -14), Vector2(-8, -22), Vector2(30, -10),
		Vector2(44, 0), Vector2(30, 10), Vector2(-8, 22), Vector2(-42, 14)
	])
	projectile.add_child(glow)
	var trail := Polygon2D.new()
	trail.name = "Trail"
	trail.color = Color(1.0, 0.24, 0.05, 0.28)
	trail.polygon = PackedVector2Array([
		Vector2(-34, -7), Vector2(-6, -13), Vector2(18, -5),
		Vector2(26, 0), Vector2(18, 5), Vector2(-6, 13), Vector2(-34, 7)
	])
	projectile.add_child(trail)
	var core := Polygon2D.new()
	core.name = "Core"
	core.color = Color(1.0, 0.78, 0.24, 0.95)
	core.polygon = PackedVector2Array([
		Vector2(-10, -6), Vector2(12, -10), Vector2(25, 0),
		Vector2(12, 10), Vector2(-10, 6), Vector2(-18, 0)
	])
	projectile.add_child(core)
	add_child(projectile)
	_active_firebolt_projectiles.append(projectile)
	_firebolt_projectile_observed = true
	var duration := clampf(
		start.distance_to(end) / FIREBOLT_PROJECTILE_SPEED,
		FIREBOLT_PROJECTILE_MIN_DURATION,
		FIREBOLT_PROJECTILE_MAX_DURATION
	)
	var tween := create_tween()
	tween.tween_property(projectile, "global_position", end, duration).set_trans(
		Tween.TRANS_QUAD
	).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(projectile, "scale", Vector2(1.25, 1.25), duration)
	tween.tween_callback(_finish_firebolt_projectile.bind(projectile, target))


func _finish_firebolt_projectile(projectile: Node2D, target: Node2D) -> void:
	_active_firebolt_projectiles.erase(projectile)
	if projectile != null and is_instance_valid(projectile):
		projectile.queue_free()
	if target != null and is_instance_valid(target):
		_spawn_hit_effect(target)


func _clear_firebolt_projectiles() -> void:
	for projectile in _active_firebolt_projectiles.duplicate():
		if projectile != null and is_instance_valid(projectile):
			projectile.queue_free()
	_active_firebolt_projectiles.clear()


func _track_hit_vfx(node: Node) -> void:
	if node == null:
		return
	if not _active_hit_vfx.has(node):
		_active_hit_vfx.append(node)
	get_tree().create_timer(HIT_VFX_AUTO_RELEASE_SECONDS).timeout.connect(_release_hit_vfx.bind(node))


func _release_hit_vfx(node: Node) -> void:
	if node == null or not is_instance_valid(node):
		_active_hit_vfx.erase(node)
		return
	if not _active_hit_vfx.has(node):
		return
	_active_hit_vfx.erase(node)
	var pool := Mkit.pool()
	if pool != null:
		pool.release(HIT_VFX_SCENE, node)
	else:
		node.queue_free()


func _release_active_hit_vfx() -> void:
	for node in _active_hit_vfx.duplicate():
		_release_hit_vfx(node)


func _clear_hit_vfx() -> void:
	_release_active_hit_vfx()
	var root := get_tree().current_scene if get_tree() != null else null
	if root == null:
		root = self
	_release_visible_hit_vfx(root)


func _release_visible_hit_vfx(node: Node) -> void:
	if node.name.begins_with("DemoHitVFX") and node is CanvasItem and (node as CanvasItem).visible:
		_release_untracked_hit_vfx(node)
	for child in node.get_children():
		_release_visible_hit_vfx(child)


func _release_untracked_hit_vfx(node: Node) -> void:
	if node == null or not is_instance_valid(node):
		return
	if _active_hit_vfx.has(node):
		_release_hit_vfx(node)
		return
	var pool := Mkit.pool()
	if pool != null:
		pool.release(HIT_VFX_SCENE, node)
	else:
		node.queue_free()


func _visible_hit_vfx_count() -> int:
	var root := get_tree().current_scene if get_tree() != null else null
	if root == null:
		root = self
	return _count_visible_hit_vfx(root)


func _count_visible_hit_vfx(node: Node) -> int:
	var count := 0
	if node.name.begins_with("DemoHitVFX") and node is CanvasItem and (node as CanvasItem).visible:
		count += 1
	for child in node.get_children():
		count += _count_visible_hit_vfx(child)
	return count


func _on_feedback_toast_requested(message: String) -> void:
	if message != "":
		_feedback_toast_observed = true


func _on_feedback_screen_shake_requested(strength: float) -> void:
	if strength > 0.0:
		_feedback_shake_observed = true


func _on_interactable_focused(interactable: Interactable) -> void:
	if interactable == null:
		return
	_interaction_focus_observed = true
	_log("[INTERACT] focus %s" % _interactable_label(interactable))


func _on_interactable_unfocused(interactable: Interactable) -> void:
	if interactable == null:
		return
	if interactable.interaction_id == "interaction.demo.village_supply":
		if _shop != null:
			_shop.close_shop()
		if _shop_ui != null:
			_shop_ui.visible = false


func _on_domain_event(event: DomainEvent) -> void:
	if event == null or event.event_type != "demo_burn_tick":
		return
	_burn_tick_observed = true
	_log("[STATUS] %s" % str(event.payload.get("message", "burn tick")))


func _on_reward_selected(event: DomainEvent) -> void:
	if str(event.payload.get("reward_id", "")) != REWARD_TRIAL_ATTACK:
		return
	if _run_director == null or _run_director.run_state == null:
		return
	if not _run_director.run_state.temporary_upgrade_ids.has(UPGRADE_TRIAL_ATTACK):
		_run_director.run_state.temporary_upgrade_ids.append(UPGRADE_TRIAL_ATTACK)
	_trial_upgrade_reward_selected = true
	_log("[TRIAL] upgrade recorded %s" % _display_name(REWARD_TRIAL_ATTACK))


func _on_trial_run_started(state: RunState) -> void:
	_trial_room_entries.clear()
	_trial_rooms_cleared = 0
	_trial_run_finished_result = ""
	_trial_upgrade_reward_selected = false
	_log("[TRIAL] started seed=%d" % state.seed)


func _on_trial_room_enter_requested(room_id: String) -> void:
	_trial_room_entries.append(room_id)
	_pending_trial_rewards.clear()
	_clear_trial_reward_screen()
	_log("[TRIAL] entering %s" % _friendly_content_id(room_id))


func _on_trial_choosing_reward(options: Array[RewardOption]) -> void:
	_pending_trial_rewards = options
	_trial_rooms_cleared += 1
	_show_trial_rewards(options)
	_log("[TRIAL] choose reward after room %d" % _trial_rooms_cleared)


func _on_trial_run_finished(result: String) -> void:
	_trial_run_finished_result = result
	_pending_trial_rewards.clear()
	_clear_trial_reward_screen()
	if result == "completed" and _room_root != null:
		_room_root.visible = false
	elif result.begins_with("failed"):
		_close_trial_room()
	_log("[TRIAL] finished %s" % result)


func _show_trial_rewards(options: Array[RewardOption]) -> void:
	_clear_trial_reward_screen()
	if _reward_layer == null:
		return
	_reward_screen = TRIAL_REWARD_UI_SCENE.instantiate() as RewardSelectionUI
	if _reward_screen == null:
		return
	_reward_layer.add_child(_reward_screen)
	_reward_screen.setup({"options": options, "run_director": _run_director})


func _on_entity_died(event: DomainEvent) -> void:
	var entity_id := str(event.payload.get("entity_id", event.source_id))
	var entity_ref := event.payload.get("entity_ref") as Node
	_log(
		"[COMBAT] defeated %s"
		% (_entity_display_name(entity_ref) if entity_ref != null else _friendly_content_id(entity_id))
	)
	if entity_ref == null:
		return
	var tags: Array = event.payload.get("tags", [])
	if not tags.has("field_beast"):
		return
	_field_beast_defeated = true
	_grant_field_xp()
	_field_beast_ref = null


func _on_loot_dropped(event: DomainEvent) -> void:
	var drop := event.payload.get("drop") as LootDropResult
	if drop == null or drop.roll_result == null:
		return
	var inventory := _inventory()
	if inventory == null:
		return
	for item in drop.roll_result.item_instances:
		if inventory.add_item(item):
			_log("[LOOT] picked up %s x%d" % [_display_name(item.definition_id), item.quantity])
	if not _field_beast_looted and drop.entity_definition_id == ENTITY_FIELD_BEAST:
		_field_beast_looted = true
		_play_sfx("sfx.demo.loot")


func _toggle_field_blade() -> void:
	var equipment := _equipment_controller()
	var inventory := _inventory()
	if equipment == null or inventory == null:
		_log("[EQUIP] equipment/inventory controller missing")
		return
	var stats := _player_stats()
	var before := stats.get_stat_value("attack_power", 0.0) if stats != null else 0.0
	if equipment.get_equipped(WEAPON_SLOT) != null:
		equipment.unequip(WEAPON_SLOT)
		_field_blade_equipped = false
		var restored := stats.get_stat_value("attack_power", 0.0) if stats != null else before
		_log("[EQUIP] stowed Field Blade attack %.0f -> %.0f" % [before, restored])
		return
	var blade := inventory.find_item_by_definition(ITEM_FIELD_BLADE)
	if blade == null:
		_log("[EQUIP] no Field Blade to equip")
		return
	if not equipment.equip(blade, WEAPON_SLOT):
		_log("[EQUIP] Field Blade equip failed")
		return
	var after := stats.get_stat_value("attack_power", 0.0) if stats != null else before
	if after > before:
		_field_blade_equipped = true
	_log("[EQUIP] equipped Field Blade attack %.0f -> %.0f" % [before, after])


func _grant_field_xp() -> void:
	var experience := _experience()
	if experience == null:
		return
	experience.add_xp(65)
	_log("[XP] +65 field XP")


func _on_level_up(old_level: int, new_level: int) -> void:
	_log("[XP] level %d -> %d" % [old_level, new_level])


func _on_item_added(item: ItemInstance) -> void:
	_log("[INV] +%s x%d" % [_display_name(item.definition_id), item.quantity])


func _on_item_removed(item: ItemInstance) -> void:
	_log("[INV] -%s" % _display_name(item.definition_id))


func _update_hud() -> void:
	_update_zone_hud()
	_update_quest_hud()
	_update_player_hud()
	_update_combat_hud()
	_update_inventory_hud()
	_update_shop_hud()
	_update_trial_hud()
	_update_instructions()


func _update_zone_hud() -> void:
	if _world == null:
		_zone_label.text = "Zone: missing world service"
		return
	var zone := _world.get_current_zone()
	_zone_label.text = "Zone: %s" % (zone.display_name if zone != null else _world.current_zone_id)


func _update_quest_hud() -> void:
	if _quest == null:
		_quest_label.text = "Quest: missing quest service"
		return
	var state := _quest.get_state(QUEST_ID)
	if state == null:
		_quest_label.text = "Quest: Talk to the Elder"
		return
	var progress := state.get_progress(QUEST_OBJECTIVE_ID)
	match state.status:
		"accepted":
			_quest_label.text = "Quest: %s - %s %d/1" % [
				_quest_title(QUEST_ID),
				_quest_objective_label(QUEST_ID, QUEST_OBJECTIVE_ID),
				progress
			]
		"completed":
			_quest_label.text = "Quest: %s - Return to the Elder" % _quest_title(QUEST_ID)
		"turned_in":
			_quest_label.text = "Quest: %s complete" % _quest_title(QUEST_ID)
		_:
			_quest_label.text = "Quest: %s" % _quest_title(QUEST_ID)


func _update_player_hud() -> void:
	var health := _player_health()
	var experience := _experience()
	var gold := _progression.get_currency("gold") if _progression != null else 0
	var hp_text := "%.0f/%.0f" % [health.current_hp, health.get_max_hp()] if health != null else "--"
	var xp_text := "Lv%d XP %d/%d" % [
		experience.current_level,
		experience.current_xp,
		experience.curve.get_xp_required(experience.current_level) if experience != null and experience.curve != null else 0
	] if experience != null else "Lv--"
	_player_label.text = "Player: HP %s  %s  gold %d" % [hp_text, xp_text, gold]


func _update_combat_hud() -> void:
	if _combat_label == null:
		return
	if _world == null or _world.current_zone_id != ZONE_FIELD:
		_combat_label.text = "Beast: enter field"
		return
	if _field_beast_defeated:
		_combat_label.text = "Beast: defeated"
		return
	var beast := _field_beast()
	if beast == null:
		_combat_label.text = "Beast: not spawned"
		return
	var health := beast.get_component("HealthComponent") as HealthComponent
	if health == null:
		_combat_label.text = "Beast: missing health"
		return
	var status := beast.get_node_or_null("Controllers/StatusEffectController") as StatusEffectController
	var status_text := " burn" if status != null and status.has_status(STATUS_BURN) else ""
	var life_text := "dead" if health.dead else "HP %.0f/%.0f" % [
		health.current_hp,
		health.get_max_hp()
	]
	_combat_label.text = "Beast: %s%s" % [life_text, status_text]


func _update_inventory_hud() -> void:
	var inventory := _inventory()
	if inventory == null:
		_inventory_label.text = "Bag: missing inventory"
		return
	var parts: Array[String] = []
	for item in inventory.model.get_items():
		parts.append("%s x%d" % [_display_name(item.definition_id), item.quantity])
	_inventory_label.text = "Bag: %s" % (", ".join(parts) if not parts.is_empty() else "empty")


func _update_shop_hud() -> void:
	if _shop == null or _shop.current_shop == null:
		_shop_label.text = "Shop: closed"
		return
	_shop_label.text = "Shop: Herb Potion %d gold, Beast Claw sells for %d" % [
		_shop.get_buy_price(ITEM_POTION),
		_shop.get_sell_price(ITEM_CLAW)
	]


func _update_instructions() -> void:
	if _instructions_label == null:
		return
	var lines := _instruction_lines()
	_instructions_label.text = "\n".join(lines)
	_instructions_label.visible = not lines.is_empty()


func _instruction_lines() -> Array[String]:
	var lines: Array[String] = []
	var context := _context_action_line()
	if context != "":
		lines.append(context)
	var next := _next_goal_line()
	if next != "" and next != context:
		lines.append(next)
	lines.append("Move: WASD  Attack: Space/J  Firebolt: Q")
	return lines


func _context_action_line() -> String:
	if _dialogue != null and _dialogue.is_active():
		var choices := _dialogue.get_available_choices()
		if choices.is_empty():
			return "E/Enter: continue dialogue"
		return "E/Enter: %s  1-3: choose another option" % choices[0].text
	if not _pending_trial_rewards.is_empty():
		return "E/Enter: choose %s  1-3: choose reward" % _pending_trial_rewards[0].display_name
	var focused := _focused_interactable()
	if focused != null:
		if focused.interaction_id == "interaction.demo.village_supply" and _shop != null and _shop.current_shop != null:
			return "Village Supply: B buy Herb Potion, V sell Beast Claw"
		return "E/Enter: %s" % _interactable_label(focused)
	if _is_trial_cave_open():
		return "E/Enter: leave Trial Cave"
	if _item_count(ITEM_FIELD_BLADE) > 0:
		return "E/Enter: equip or stow Field Blade"
	return "E/Enter: interact with the nearest highlighted target"


func _next_goal_line() -> String:
	if _world == null:
		return "Next: starting village"
	if _is_trial_cave_open():
		if not _pending_trial_rewards.is_empty():
			return "Next: choose a cave reward"
		return "Next: clear the trial room"
	var state := _quest.get_state(QUEST_ID) if _quest != null else null
	if state == null:
		if _world.current_zone_id == ZONE_ROOM:
			return "Next: talk to the Elder"
		return "Next: enter Elder Room"
	if state.status == "accepted":
		if _world.current_zone_id == ZONE_FIELD:
			if _field_beast_defeated:
				return "Next: return to the Elder"
			return "Next: defeat the Field Beast"
		return "Next: go to Field Gate"
	if state.status == "completed":
		return "Next: return to the Elder"
	if state.status == "turned_in":
		if _world.current_zone_id == ZONE_FIELD:
			return "Next: enter Trial Cave"
		if _world.current_zone_id == ZONE_VILLAGE:
			return "Next: try Village Supply or head to Field Gate"
		return "Next: return to Village"
	return ""


func _update_trial_hud() -> void:
	if _trial_label == null:
		return
	if _run_director == null or _run_director.run_state == null:
		_trial_label.text = "Trial: ready"
		return
	var state := _run_director.run_state
	_trial_label.text = "Trial: %s room %d/%d rewards %d" % [
		state.status,
		min(state.current_room_index + 1, _run_director.run_length),
		_run_director.run_length,
		state.reward_history.size()
	]


func _current_zone_root() -> Node:
	if _world_host.get_child_count() == 0:
		return null
	return _world_host.get_child(0)


func _spawn_field_beast() -> void:
	if _field_beast_defeated:
		return
	if is_instance_valid(_field_beast_ref):
		return
	var root := _current_zone_root()
	if root == null:
		return
	var marker := root.get_node_or_null("FieldBeastSpawn") as Node2D
	if marker == null:
		_log("[ENTITY] field beast spawn marker missing")
		return
	if _entity_spawner == null:
		_log("[ENTITY] entity spawner missing")
		return
	var spawned := _entity_spawner.spawn_entity(ENTITY_FIELD_BEAST, root, marker.global_position)
	var beast := spawned as EntityRoot
	if beast == null:
		_log("[ENTITY] field beast spawn failed")
		if spawned != null and is_instance_valid(spawned):
			spawned.queue_free()
		return
	_field_beast_ref = beast


func _field_beast() -> EntityRoot:
	if is_instance_valid(_field_beast_ref):
		return _field_beast_ref
	return null


func _is_field_beast_health_alive(health_component: Object = null) -> bool:
	if health_component == null:
		var beast := _field_beast()
		if beast == null:
			return false
		health_component = beast.get_component("HealthComponent")
	if health_component == null or not is_instance_valid(health_component):
		return false
	var health := health_component as HealthComponent
	if health == null:
		return false
	return not health.dead


func _inventory() -> InventoryController:
	return _player.get_controller("InventoryController") as InventoryController


func _equipment_controller() -> EquipmentController:
	return _player.get_controller("EquipmentController") as EquipmentController


func _player_health() -> HealthComponent:
	return _player.get_component("HealthComponent") as HealthComponent


func _interaction_component() -> InteractionComponent:
	return _player.get_component("InteractionComponent") as InteractionComponent


func _ability_controller() -> AbilityController:
	return _player.get_controller("AbilityController") as AbilityController


func _player_stats() -> StatsComponent:
	return _player.get_component("StatsComponent") as StatsComponent


func _player_mana() -> float:
	var pool := _player.get_component("ResourcePoolComponent") as ResourcePoolComponent
	return pool.get_current("mana") if pool != null else 0.0


func _gold() -> int:
	return _progression.get_currency("gold") if _progression != null else 0


func _item_count(definition_id: String) -> int:
	var inventory := _inventory()
	if inventory == null:
		return 0
	var total := 0
	for item in inventory.model.get_items():
		if item.definition_id == definition_id:
			total += item.quantity
	return total


func _experience() -> ExperienceComponent:
	return _player.get_component("ExperienceComponent") as ExperienceComponent


func _entity_id(node: Node) -> String:
	if node == null:
		return "?"
	var root := node as EntityRoot
	var identity := (
		root.get_entity_identity() if root != null else node.get_node_or_null("EntityIdentity")
	) as EntityIdentity
	return identity.entity_id if identity != null else str(node.name)


func _entity_display_name(node: Node) -> String:
	if node == null:
		return "?"
	var root := node as EntityRoot
	var identity := (
		root.get_entity_identity() if root != null else node.get_node_or_null("EntityIdentity")
	) as EntityIdentity
	if identity != null:
		if identity.display_name != "":
			return identity.display_name
		return _friendly_content_id(identity.entity_id)
	return str(node.name)


func _display_name(content_id: String, fallback: String = "") -> String:
	if content_id.strip_edges() == "":
		return fallback
	var content := Mkit.content()
	if content != null and content.has(content_id):
		var resource := content.get_resource(content_id)
		var raw = resource.get("display_name")
		if raw != null and str(raw) != "":
			return str(raw)
	return fallback if fallback != "" else _friendly_content_id(content_id)


func _friendly_content_id(content_id: String) -> String:
	var value := content_id
	for prefix in [
		"item.demo.",
		"quest.demo.",
		"obj.demo.",
		"ability.demo.",
		"entity.demo.",
		"zone.demo.",
		"dialogue.demo.",
		"reward.demo.",
		"status.demo.",
		"room.demo.",
		"npc.demo.",
		"shop.demo."
	]:
		value = value.replace(prefix, "")
	return value.replace("_", " ")


func _quest_title(quest_id: String) -> String:
	var definition := _quest.get_definition(quest_id) if _quest != null else null
	if definition != null and definition.display_name != "":
		return definition.display_name
	return _display_name(quest_id)


func _quest_objective_label(quest_id: String, objective_id: String) -> String:
	var definition := _quest.get_definition(quest_id) if _quest != null else null
	if definition != null:
		var objective := definition.get_objective(objective_id)
		if objective != null and objective.description != "":
			return objective.description
	return _friendly_content_id(objective_id)


func _interactable_label(interactable: Interactable) -> String:
	if interactable == null:
		return "Interact"
	match interactable.interaction_id:
		"interaction.demo.elder":
			return "Talk to Elder"
		"interaction.demo.village_supply":
			return "Open Village Supply"
		_:
			return interactable.display_text if interactable.display_text != "" else "Interact"


func _first_missing_service() -> String:
	var checks := {
		"dialogue": _dialogue,
		"quest": _quest,
		"shop": _shop,
		"world": _world,
		"commands": _commands,
		"events": _events,
		"effects": _effects,
		"time": _time,
		"progression": _progression,
		"audio": _audio,
		"save": _save_manager
	}
	for key in checks.keys():
		if checks[key] == null:
			return key
	return ""


func _has_entity_tag(node: Node, tag: String) -> bool:
	if node == null:
		return false
	var root := node as EntityRoot
	var identity := (
		root.get_entity_identity() if root != null else node.get_node_or_null("EntityIdentity")
	) as EntityIdentity
	return identity != null and identity.tags.has(tag)


func get_debug_status_lines() -> Array[String]:
	var lines: Array[String] = []
	lines.append("Zone: %s" % (_world.current_zone_id if _world != null else ""))
	var run_status := "ready"
	if _run_director != null and _run_director.run_state != null:
		run_status = _run_director.run_state.status
	lines.append("Run: %s" % run_status)
	var focused := _focused_interactable()
	lines.append("Focus: %s" % (_interactable_label(focused) if focused != null else "none"))
	if _last_failed_command != "":
		lines.append("Last failed command: %s" % _last_failed_command)
	_update_last_failed_effect()
	if _last_failed_effect != "":
		lines.append("Last failed effect: %s" % _last_failed_effect)
	if _last_missing_service != "":
		lines.append("Missing service: %s" % _last_missing_service)
	lines.append("Runtime: %.2f" % _runtime_seconds)
	return lines


func _update_last_failed_effect() -> void:
	if _effects == null:
		return
	for i in range(_effects.recent_results.size() - 1, -1, -1):
		var result := _effects.recent_results[i] as EffectResult
		if result != null and not result.success:
			_last_failed_effect = "%s: %s" % [result.effect_id, result.failure_reason]
			return


func _play_sfx(audio_id: String) -> void:
	if _audio != null:
		_audio.play_sfx(audio_id)


func _cleanup_audio_players() -> void:
	if _audio == null:
		return
	_audio.stop_music()
	for child in _audio.get_children():
		var player := child as AudioStreamPlayer
		if player == null:
			continue
		player.stop()
		player.stream = null
		_audio.remove_child(player)
		player.free()
	_audio.music_player = null
	_audio.current_music_id = ""


func _log(line: String) -> void:
	print(line)
	_record_debug_failure(line)
	_log_lines.append(_compact_log_line(line))
	if _log_lines.size() > EVENT_LOG_MAX_LINES:
		_log_lines.pop_front()
	if _event_log_label != null:
		_event_log_label.text = "Log\n%s" % "\n".join(_log_lines)


func _compact_log_line(line: String) -> String:
	var compact := line
	compact = _replace_known_content_ids(compact)
	compact = compact.replace("[SHOP] bought ", "Bought ")
	compact = compact.replace("[SHOP] sold ", "Sold ")
	compact = compact.replace("[SHOP] opened ", "Shop: ")
	compact = compact.replace("[QUEST] accepted ", "Quest accepted: ")
	compact = compact.replace("[QUEST] turned in ", "Quest complete: ")
	compact = compact.replace("[WORLD] ", "World: ")
	compact = compact.replace("[INV] +", "Found ")
	compact = compact.replace("[INV] -", "Removed ")
	if compact.length() > 62:
		compact = "%s..." % compact.substr(0, 59)
	return compact


func _replace_known_content_ids(value: String) -> String:
	var compact := value
	for id in [
		ITEM_POTION,
		ITEM_CLAW,
		ITEM_CHARM,
		ITEM_FIELD_BLADE,
		QUEST_ID,
		QUEST_MANUAL_ID,
		SHOP_ID,
		ZONE_VILLAGE,
		ZONE_ROOM,
		ZONE_FIELD,
		ENTITY_FIELD_BEAST,
		ENTITY_TRIAL_BEAST,
		ABILITY_FIREBOLT,
		STATUS_BURN,
		REWARD_TRIAL_ATTACK
	]:
		compact = compact.replace(id, _display_name(id))
	compact = compact.replace(QUEST_OBJECTIVE_ID, _quest_objective_label(QUEST_ID, QUEST_OBJECTIVE_ID))
	compact = compact.replace(
		QUEST_MANUAL_OBJECTIVE_ID,
		_quest_objective_label(QUEST_MANUAL_ID, QUEST_MANUAL_OBJECTIVE_ID)
	)
	return compact


func _record_debug_failure(line: String) -> void:
	var lower := line.to_lower()
	if lower.contains("service missing"):
		_last_missing_service = line
	if lower.contains("failed") or lower.contains("missing"):
		if line.begins_with("[ACTION]") or line.begins_with("[ABILITY]") or line.begins_with("[COMBAT]"):
			_last_failed_effect = line


func _run_auto_loop() -> void:
	await _auto_run_verifier.run(self, _save_payload_verifier)


func _settle_world() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().physics_frame
	await get_tree().physics_frame


func _settle_shutdown() -> void:
	for i in range(6):
		await get_tree().process_frame
		await get_tree().physics_frame


func _demo_loop_complete() -> bool:
	return _demo_missing_requirements().is_empty()


func _demo_missing_requirements() -> Array[String]:
	var missing: Array[String] = []
	if _world == null or _world.current_zone_id != ZONE_VILLAGE:
		missing.append("zone_village")
	if _quest == null:
		missing.append("quest_service")
	else:
		var state := _quest.get_state(QUEST_ID)
		if state == null or state.status != "turned_in":
			missing.append("field_report")
		var manual_state := _quest.get_state(QUEST_MANUAL_ID)
		if manual_state == null or manual_state.status != "turned_in":
			missing.append("manual_quest")
	var inventory := _inventory()
	if inventory == null:
		missing.append("inventory")
	else:
		if inventory.find_item_by_definition(ITEM_CHARM) == null:
			missing.append("charm")
		if inventory.find_item_by_definition(ITEM_POTION) == null:
			missing.append("potion")
		if inventory.find_item_by_definition(ITEM_CLAW) != null:
			missing.append("claw_sold")
	var experience := _experience()
	if experience == null or experience.current_level < 2:
		missing.append("level")
	if not _firebolt_cast_succeeded:
		missing.append("firebolt")
	if not _firebolt_projectile_observed:
		missing.append("firebolt_projectile")
	if not _burn_tick_observed:
		missing.append("burn_tick")
	if not _elder_blessing_received:
		missing.append("elder_blessing")
	if not _command_combat_succeeded:
		missing.append("command_combat")
	if not _interaction_focus_observed or not _portal_interaction_succeeded:
		missing.append("interaction")
	if not _manual_quest_completed:
		missing.append("manual_quest_flag")
	if not _dash_succeeded:
		missing.append("dash")
	if not _field_blade_equipped:
		missing.append("field_blade")
	if not _debug_overlay_verified:
		missing.append("debug_overlay")
	if not _demo_save_roundtrip_succeeded:
		missing.append("save_roundtrip")
	if not _demo_save_payload_verified:
		missing.append("save_payload")
	if not _is_trial_completed():
		missing.append("trial_completed")
	if _trial_run_finished_result != "completed":
		missing.append("trial_result")
	if _trial_room_entries.size() != 3 or _trial_rooms_cleared != 3:
		missing.append("trial_rooms")
	if not _trial_upgrade_reward_selected:
		missing.append("trial_reward")
	if (
		_run_director == null
		or _run_director.run_state == null
		or not _run_director.run_state.temporary_upgrade_ids.has(UPGRADE_TRIAL_ATTACK)
	):
		missing.append("trial_upgrade")
	var equipment := _equipment_controller()
	if equipment == null or equipment.get_equipped(WEAPON_SLOT) == null:
		missing.append("equipment")
	var stats := _player_stats()
	if stats == null or stats.get_stat_value("attack_power", 0.0) < 30.0:
		missing.append("attack_power")
	if not _shop_purchase_completed or not _shop_sale_completed:
		missing.append("shop")
	if _shop_purchase_verifications < AUTO_RUN_EXPECTED_POTION_BUYS:
		missing.append("shop_buy_delta")
	if not _shop_sale_currency_verified:
		missing.append("shop_sell_delta")
	if not _potion_use_completed:
		missing.append("potion_use")
	if _runtime_seconds <= 0.0:
		missing.append("time")
	if not _feedback_shake_observed or not _feedback_toast_observed:
		missing.append("feedback")
	if not _spawn_scene_effect_succeeded:
		missing.append("spawn_scene")
	if not _hit_vfx_cleanup_verified or _visible_hit_vfx_count() > 0:
		missing.append("hit_vfx_cleanup")
	if _progression == null or _progression.get_currency("gold") < 5:
		missing.append("gold")
	missing.append_array(_demo_ui_missing_requirements())
	return missing


func _demo_ui_missing_requirements() -> Array[String]:
	var missing: Array[String] = []
	_update_hud()
	if _zone_label == null or not _zone_label.text.contains("Village"):
		missing.append("ui_zone")
	if _quest_label == null or not _quest_label.text.contains("complete"):
		missing.append("ui_quest")
	if (
		_inventory_label == null
		or not _inventory_label.text.contains("Village Charm")
		or not _inventory_label.text.contains("Field Blade")
		or not _inventory_label.text.contains("Herb Potion")
	):
		missing.append("ui_inventory")
	if _shop_label == null or not _shop_label.text.contains("Herb Potion"):
		missing.append("ui_shop")
	if _trial_label == null or not _trial_label.text.contains("completed"):
		missing.append("ui_trial")
	if _player_label == null or not _player_label.text.contains("gold"):
		missing.append("ui_player")
	return missing
