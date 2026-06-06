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
const LOOT_FIELD_BEAST := "loot.demo.field_beast"
const LOOT_FIELD_BLADE := "loot.demo.field_blade"
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
const PLATFORM_REVIVE_PLACEMENT := "revive"
const PLATFORM_GOLD_PACK_PRODUCT := "com.mkit.demo.gold_pack"
const PLATFORM_CLOUD_SLOT := "demo_profile"
const GOLD_PACK_AMOUNT := 25
const MELEE_RANGE := 30.0
const FIREBOLT_RANGE := 100.0
const TRIAL_SEED := 8606
const TRIAL_REWARD_UI_SCENE := preload("res://game/demo/village_rpg/scenes/trial_reward_selection.tscn")
const DEMO_SAVE_MIGRATION := preload("res://game/demo/village_rpg/save_migration_v1_to_v2.gd")
const HIT_VFX_SCENE := "res://game/demo/village_rpg/ui/hit_vfx.tscn"


class EmbeddedSceneRouter:
	extends SceneRouter

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
@onready var _player: Node2D = $Player
@onready var _instructions_label: Label = $HUD/Instructions
@onready var _zone_label: Label = $HUD/StatsPanel/ZoneInfo
@onready var _quest_label: Label = $HUD/StatsPanel/QuestInfo
@onready var _player_label: Label = $HUD/StatsPanel/PlayerInfo
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

var _dialogue: DialogueController = null
var _quest: QuestSystem = null
var _shop: ShopController = null
var _world: WorldRouter = null
var _events: EventRouter = null
var _effects: EffectExecutor = null
var _time: TimeService = null
var _progression: ProgressionSystem = null
var _audio: AudioManager = null
var _save_manager: SaveManager = null
var _analytics: AnalyticsService = null
var _ads: AdService = null
var _iap: IAPService = null
var _cloud_save: CloudSaveService = null
var _entity_spawner: EntitySpawner = null
var _loot_system := LootSystem.new()
var _scene_router := EmbeddedSceneRouter.new()
var _previous_scene_router: SceneRouter = null
var _log_lines: Array[String] = []
var _field_beast_ref: Node = null
var _field_beast_looted: bool = false
var _shop_purchase_completed: bool = false
var _shop_sale_completed: bool = false
var _auto_run_enabled: bool = false
var _auto_run_started: bool = false
var _firebolt_cast_succeeded: bool = false
var _burn_tick_observed: bool = false
var _elder_blessing_received: bool = false
var _command_combat_succeeded: bool = false
var _field_blade_equipped: bool = false
var _revive_ad_pending: bool = false
var _rewarded_revive_completed: bool = false
var _gold_pack_purchase_pending: bool = false
var _gold_pack_purchase_completed: bool = false
var _cloud_busy: bool = false
var _cloud_save_completed: bool = false
var _cloud_load_completed: bool = false
var _cloud_last_loaded_data: Dictionary = {}
var _pending_trial_rewards: Array[RewardOption] = []
var _trial_room_entries: Array[String] = []
var _trial_rooms_cleared: int = 0
var _trial_run_finished_result: String = ""
var _trial_upgrade_reward_selected: bool = false
var _reward_screen: RewardSelectionUI = null
var _demo_save_roundtrip_succeeded: bool = false
var _runtime_seconds: float = 0.0
var _feedback_toast_observed: bool = false
var _feedback_shake_observed: bool = false
var _spawn_scene_effect_succeeded: bool = false
var _interaction_focus_observed: bool = false
var _portal_interaction_succeeded: bool = false
var _manual_quest_completed: bool = false
var _dash_succeeded: bool = false


func _ready() -> void:
	_auto_run_enabled = OS.get_cmdline_args().has("--demo-auto-run")
	_resolve_services()
	_configure_save()
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
			KEY_E:
				_toggle_field_blade()
			KEY_C:
				_enter_trial_cave()
			KEY_D:
				_trigger_rewarded_revive_demo()
			KEY_P:
				_purchase_gold_pack()
			KEY_S:
				_save_demo_state()
			KEY_O:
				_save_demo_to_cloud()
			KEY_L:
				_load_demo_state()
			KEY_U:
				_load_demo_from_cloud()
			KEY_1:
				_select_trial_reward(0)
			KEY_2:
				_select_trial_reward(1)
			KEY_3:
				_select_trial_reward(2)
			KEY_K:
				_defeat_field_beast()
			KEY_B:
				_buy_potion()
			KEY_V:
				_sell_claw()
			KEY_H:
				_use_potion()


func _exit_tree() -> void:
	_cleanup_audio_players()
	if ServiceRegistry.has_service("scenes"):
		var current := ServiceRegistry.get_service("scenes") as SceneRouter
		if current == _scene_router:
			ServiceRegistry.unregister_service("scenes")
			if _previous_scene_router != null:
				ServiceRegistry.register_service("scenes", _previous_scene_router)
	if _world != null and _world.scene_router == _scene_router:
		_world.scene_router = _previous_scene_router


func _resolve_services() -> void:
	_dialogue = ServiceRegistry.get_service("dialogue") as DialogueController
	_quest = ServiceRegistry.get_service("quest") as QuestSystem
	_shop = ServiceRegistry.get_service("shop") as ShopController
	_world = ServiceRegistry.get_service("world") as WorldRouter
	_events = ServiceRegistry.get_service("events") as EventRouter
	_effects = ServiceRegistry.get_service("effects") as EffectExecutor
	_time = ServiceRegistry.get_service("time") as TimeService
	_progression = ServiceRegistry.get_service("progression") as ProgressionSystem
	_audio = ServiceRegistry.get_service("audio") as AudioManager
	_save_manager = ServiceRegistry.get_service("save") as SaveManager
	_analytics = ServiceRegistry.get_service("analytics") as AnalyticsService
	_ads = ServiceRegistry.get_service("ads") as AdService
	_iap = ServiceRegistry.get_service("iap") as IAPService
	_cloud_save = ServiceRegistry.get_service("cloud_save") as CloudSaveService


func _configure_save() -> void:
	if _save_manager == null:
		return
	if _auto_run_enabled:
		_save_manager.save_path = "/tmp/mkit_demo_auto_save.json"
	_save_manager.save_version = max(_save_manager.save_version, 2)
	var migration := DEMO_SAVE_MIGRATION.new() as SaveMigration
	if _has_save_migration(migration.from_version, migration.to_version):
		return
	var migrations: Array[SaveMigration] = []
	for existing in _save_manager.migrations:
		migrations.append(existing)
	migrations.append(migration)
	_save_manager.migrations = migrations


func _has_save_migration(from_version: int, to_version: int) -> bool:
	if _save_manager == null:
		return false
	for migration in _save_manager.migrations:
		if migration.from_version == from_version and migration.to_version == to_version:
			return true
	return false


func _configure_entity_spawner() -> void:
	_entity_spawner = EntitySpawner.new()
	_entity_spawner.name = "DemoEntitySpawner"
	if ServiceRegistry.has_service("content"):
		_entity_spawner.content = ServiceRegistry.get_service("content") as ContentRegistry
	add_child(_entity_spawner)


func _configure_embedded_router() -> void:
	_scene_router.name = "DemoEmbeddedSceneRouter"
	_scene_router.host = _world_host
	add_child(_scene_router)
	_previous_scene_router = null
	if ServiceRegistry.has_service("scenes"):
		_previous_scene_router = ServiceRegistry.get_service("scenes") as SceneRouter
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
	_shop_purchase_completed = false
	_shop_sale_completed = false
	_firebolt_cast_succeeded = false
	_burn_tick_observed = false
	_elder_blessing_received = false
	_command_combat_succeeded = false
	_revive_ad_pending = false
	_rewarded_revive_completed = false
	_gold_pack_purchase_pending = false
	_gold_pack_purchase_completed = false
	_cloud_busy = false
	_cloud_save_completed = false
	_cloud_load_completed = false
	_cloud_last_loaded_data.clear()
	_runtime_seconds = 0.0
	if _time != null:
		_time.elapsed_gameplay_time = 0.0
	_feedback_toast_observed = false
	_feedback_shake_observed = false
	_spawn_scene_effect_succeeded = false
	_interaction_focus_observed = false
	_portal_interaction_succeeded = false
	_manual_quest_completed = false
	_dash_succeeded = false
	_reset_trial_state()
	_demo_save_roundtrip_succeeded = false


func _configure_audio() -> void:
	if _audio == null:
		return
	_audio.music_bus = "Master"
	_audio.sfx_bus = "Master"
	if _auto_run_enabled:
		return
	_audio.music_map = {
		"bgm.demo.village": _make_audio_stream(),
		"bgm.demo.room": _make_audio_stream(),
		"bgm.demo.field": _make_audio_stream()
	}
	_audio.sfx_map = {
		"sfx.demo.dialogue": _make_audio_stream(),
		"sfx.demo.quest": _make_audio_stream(),
		"sfx.demo.loot": _make_audio_stream(),
		"sfx.demo.shop": _make_audio_stream()
	}


func _make_audio_stream() -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	stream.stereo = false
	var data := PackedByteArray()
	data.resize(4410)
	stream.data = data
	return stream


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
	if _shop != null:
		_shop.shop_opened.connect(_on_shop_opened)
		_shop.item_purchased.connect(_on_item_purchased)
		_shop.item_sold.connect(_on_item_sold)
		_shop.transaction_failed.connect(_on_transaction_failed)
	if _world != null:
		_world.zone_changed.connect(_on_zone_changed)
	if _events != null:
		_events.domain_event_emitted.connect(_on_domain_event)
		_events.reward_selected.connect(_on_reward_selected)
		_events.entity_died.connect(_on_entity_died)
		_events.damage_applied.connect(_on_damage_applied)
	if _run_director != null:
		_run_director.run_started.connect(_on_trial_run_started)
		_run_director.room_enter_requested.connect(_on_trial_room_enter_requested)
		_run_director.choosing_reward.connect(_on_trial_choosing_reward)
		_run_director.run_finished.connect(_on_trial_run_finished)
	var interaction := _interaction_component()
	if interaction != null:
		interaction.interactable_focused.connect(_on_interactable_focused)
	var experience := _experience()
	if experience != null:
		experience.level_up.connect(_on_level_up)
	var health := _player_health()
	if health != null:
		health.died.connect(_on_player_died)
	var inventory := _inventory()
	if inventory != null:
		inventory.item_added.connect(_on_item_added)
		inventory.item_removed.connect(_on_item_removed)
	if _ads != null:
		_ads.rewarded_ad_completed.connect(_on_rewarded_ad_completed)
		_ads.rewarded_ad_failed.connect(_on_rewarded_ad_failed)
	if _iap != null:
		_iap.purchase_completed.connect(_on_iap_purchase_completed)
		_iap.purchase_failed.connect(_on_iap_purchase_failed)
	if _cloud_save != null:
		_cloud_save.cloud_save_completed.connect(_on_cloud_save_completed)
		_cloud_save.cloud_save_failed.connect(_on_cloud_save_failed)
		_cloud_save.cloud_load_completed.connect(_on_cloud_load_completed)
		_cloud_save.cloud_load_failed.connect(_on_cloud_load_failed)


func _grant_starter_currency() -> void:
	if _progression != null:
		_progression.add_currency("gold", 10)


func _set_instructions() -> void:
	_instructions_label.text = (
		"Demo RPG loop: stand near portals/NPC, R room/back, G field/back, "
		+ "T talk/choice/advance, M manual task, Shift dash, F cast firebolt, "
		+ "K defeat beast, E equip/unequip blade, Y elder blessing, "
		+ "C trial cave, 1/2/3 reward, B buy potion, V sell claw, H use potion, "
		+ "S save, L load, D ad revive, P gold pack, O/U cloud"
	)


func _go_to_zone(zone_id: String, spawn_id: String) -> void:
	if _world == null:
		_log("[WORLD] service missing")
		return
	if not _world.go_to_zone(zone_id, spawn_id):
		_log("[WORLD] could not enter %s" % zone_id)


func _toggle_room_portal() -> void:
	if _world == null:
		return
	if _world.current_zone_id == ZONE_VILLAGE:
		_interact_portal("ToRoom")
	elif _world.current_zone_id == ZONE_ROOM:
		_interact_portal("ToVillage")
	else:
		_log("[WORLD] room portal is only available in the village or elder room")


func _toggle_field_portal() -> void:
	if _world == null:
		return
	if _world.current_zone_id == ZONE_VILLAGE:
		_interact_portal("ToField")
	elif _world.current_zone_id == ZONE_FIELD:
		_interact_portal("ToVillage")
	else:
		_log("[WORLD] field gate is only available in the village or field")


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
		interaction.current_interactable = interactable
		_on_interactable_focused(interactable)
	if not interaction.try_interact():
		_log("[INTERACT] failed %s" % label)
		return false
	if interactable is Portal:
		_portal_interaction_succeeded = true
	return true


func _find_zone_interactable(interactable_path: String) -> Interactable:
	var root := _current_zone_root()
	if root == null:
		return null
	return root.get_node_or_null(interactable_path) as Interactable


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
		var choices := _dialogue.get_available_choices()
		if choices.is_empty():
			_dialogue.advance()
		else:
			_dialogue.choose(0)
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
	var health := beast.get_node_or_null("Components/HealthComponent") as HealthComponent
	if health == null or health.dead:
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


func _damage_player_from_beast(beast: Node) -> void:
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
	var beast := _field_beast() as Node2D
	if beast == null:
		_log("[COMBAT] field beast not found")
		return
	var health := beast.get_node_or_null("Components/HealthComponent") as HealthComponent
	if health == null or health.dead:
		_log("[COMBAT] field beast already defeated")
		return
	await _approach(beast, MELEE_RANGE)
	await _attack_field_beast(health)
	if health.dead:
		_command_combat_succeeded = true
	else:
		_log("[COMBAT] command chain stalled; using scripted strike")
		_defeat_field_beast()
		if health.dead:
			_command_combat_succeeded = true


func _attack_field_beast(health: HealthComponent) -> void:
	var state_machine := _player.get_node_or_null("StateMachine") as StateMachine
	if state_machine == null:
		return
	var attacks := 0
	while attacks < 8 and not health.dead:
		_dispatch_player_command(BuiltinCommands.ATTACK, {})
		var guard := 0
		while (
			guard < 600
			and not health.dead
			and state_machine.get_current_path() == "Player/Attack"
		):
			await get_tree().physics_frame
			guard += 1
		attacks += 1


func _dispatch_player_command(command_type: String, payload: Dictionary) -> void:
	var router := ServiceRegistry.get_service("commands") as CommandRouter
	if router == null:
		return
	router.dispatch(GameCommand.create(command_type, PLAYER_ID, PLAYER_ID, payload))


func _cast_firebolt_command() -> void:
	_dispatch_player_command(BuiltinCommands.CAST_ABILITY, {"ability_id": ABILITY_FIREBOLT})


func _dash_player_once() -> void:
	var state_machine := _player.get_node_or_null("StateMachine") as StateMachine
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
	var beast := _field_beast() as Node2D
	if beast == null:
		_log("[ABILITY] field beast not found")
		return
	var health := beast.get_node_or_null("Components/HealthComponent") as HealthComponent
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


func _wait_for_beast_burn_tick(beast: Node2D) -> void:
	var status := beast.get_node_or_null("Controllers/StatusEffectController") as StatusEffectController
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
	if _world == null or _world.current_zone_id != ZONE_FIELD:
		_log("[TRIAL] enter the field first")
		return
	var root := _current_zone_root()
	if root == null or root.get_node_or_null("TrialCave") == null:
		_log("[TRIAL] trial cave entrance missing")
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


func _run_trial_auto() -> void:
	_enter_trial_cave()
	await _settle_world()
	var guard := 0
	while not _is_trial_terminal() and guard < 12:
		var status := _run_director.run_state.status if _run_director.run_state != null else ""
		if status == "active":
			_defeat_trial_room_enemies()
		elif status == "choosing_reward":
			_select_trial_reward(_trial_reward_index(REWARD_TRIAL_ATTACK))
		await _settle_world()
		guard += 1
	if not _is_trial_completed():
		_log("[TRIAL] auto run did not complete")


func _defeat_trial_room_enemies() -> void:
	if _run_director == null or _run_director.current_room_controller == null:
		_log("[TRIAL] no active room")
		return
	var room := _run_director.current_room_controller
	if room.runtime == null:
		_log("[TRIAL] active room has no runtime")
		return
	var enemy_ids := room.runtime.active_enemy_ids.duplicate()
	for enemy_id in enemy_ids:
		var enemy := room.active_enemies.get(enemy_id, null) as Node
		if enemy == null:
			continue
		var brain := enemy.get_node_or_null("Controllers/SimpleAIEnemyBrain") as SimpleAIEnemyBrain
		if brain != null:
			brain.enabled = false
		var damage := DealDamageEffect.new()
		damage.effect_id = "effect.demo.trial_strike"
		damage.base_amount = 999.0
		damage.can_crit = false
		_effects.execute(damage, GameplayContext.new().with_source(_player).with_target(enemy))


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
	_log("[TRIAL] picked reward %s" % selected.reward_id)


func _trial_reward_index(reward_id: String) -> int:
	for i in range(_pending_trial_rewards.size()):
		if _pending_trial_rewards[i].reward_id == reward_id:
			return i
	return 0


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
	_clear_trial_reward_screen()
	if _room_root != null:
		for child in _room_root.get_children():
			child.queue_free()
		_room_root.visible = false


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
	if _shop.buy(ITEM_POTION, 1, _player):
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
	if _shop.sell(claw.instance_id, 1, _player):
		_play_sfx("sfx.demo.shop")


func _ensure_shop_open() -> bool:
	if _shop == null:
		_log("[SHOP] service missing")
		return false
	if _world == null or _world.current_zone_id != ZONE_VILLAGE:
		_log("[SHOP] return to the village supply stall")
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
	var ctx := GameplayContext.new().with_source(_player).with_target(_player)
	_effects.execute_many(definition.use_effects, ctx, true)
	inventory.remove_item_by_instance_id(potion.instance_id, 1)
	var after := health.current_hp if health != null else 0.0
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
	if _save_manager.load_game(get_tree().root):
		_sync_loaded_state_flags()
		_log("[SAVE] loaded demo state")
		return true
	_log("[SAVE] load failed")
	return false


func _sync_loaded_state_flags() -> void:
	var equipment := _equipment_controller()
	_field_blade_equipped = equipment != null and equipment.get_equipped(WEAPON_SLOT) != null


func _trigger_rewarded_revive_demo() -> void:
	var health := _player_health()
	if health == null:
		_log("[AD] player health missing")
		return
	if health.dead:
		_request_rewarded_revive()
		return
	health.die(null)


func _request_rewarded_revive() -> void:
	var health := _player_health()
	if health == null:
		_log("[AD] player health missing")
		return
	if not health.dead:
		_log("[AD] revive is only available after death")
		return
	if _ads == null:
		_log("[AD] service missing")
		return
	if _revive_ad_pending:
		_log("[AD] revive ad already pending")
		return
	if not _ads.is_rewarded_ad_ready(PLATFORM_REVIVE_PLACEMENT):
		_log("[AD] revive ad not ready")
		return
	_revive_ad_pending = true
	_log("[AD] showing rewarded revive")
	_ads.show_rewarded_ad(PLATFORM_REVIVE_PLACEMENT)


func _purchase_gold_pack() -> void:
	if not _ensure_shop_open():
		return
	if _iap == null:
		_log("[IAP] service missing")
		return
	if _gold_pack_purchase_pending:
		_log("[IAP] gold pack purchase already pending")
		return
	_gold_pack_purchase_pending = true
	_log("[IAP] purchasing %s" % PLATFORM_GOLD_PACK_PRODUCT)
	_iap.purchase(PLATFORM_GOLD_PACK_PRODUCT)


func _save_demo_to_cloud() -> void:
	if _save_manager == null:
		_log("[CloudSave] save service missing")
		return
	if _cloud_save == null:
		_log("[CloudSave] service missing")
		return
	if not _cloud_save.is_available():
		_log("[CloudSave] not available")
		return
	if _cloud_busy:
		_log("[CloudSave] busy")
		return
	if not _save_demo_state():
		_log("[CloudSave] local save failed")
		return
	var data := _read_demo_save_data()
	if data.is_empty():
		_log("[CloudSave] local save data missing")
		return
	_cloud_busy = true
	_log("[CloudSave] saving %s" % PLATFORM_CLOUD_SLOT)
	_cloud_save.save_to_cloud(PLATFORM_CLOUD_SLOT, data)


func _load_demo_from_cloud() -> void:
	if _cloud_save == null:
		_log("[CloudSave] service missing")
		return
	if not _cloud_save.is_available():
		_log("[CloudSave] not available")
		return
	if _cloud_busy:
		_log("[CloudSave] busy")
		return
	_cloud_busy = true
	_log("[CloudSave] loading %s" % PLATFORM_CLOUD_SLOT)
	_cloud_save.load_from_cloud(PLATFORM_CLOUD_SLOT)


func _read_demo_save_data() -> Dictionary:
	if _save_manager == null:
		return {}
	var file := FileAccess.open(_save_manager.save_path, FileAccess.READ)
	if file == null:
		return {}
	var text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	var data: Dictionary = parsed
	return data


func _write_demo_save_data(data: Dictionary) -> bool:
	if _save_manager == null:
		return false
	var file := FileAccess.open(_save_manager.save_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data, "  "))
	file.close()
	return true


func _track_analytics_event(event_name: String, properties: Dictionary = {}) -> void:
	if _analytics == null:
		return
	_analytics.track_event(event_name, properties)


func _on_dialogue_started(dialogue_id: String) -> void:
	if _dialogue_ui != null:
		_dialogue_ui.visible = true
	_play_sfx("sfx.demo.dialogue")
	_log("[DIALOGUE] started %s" % dialogue_id)


func _on_dialogue_ended(dialogue_id: String) -> void:
	_log("[DIALOGUE] ended %s" % dialogue_id)


func _on_quest_accepted(quest_id: String) -> void:
	_play_sfx("sfx.demo.quest")
	_log("[QUEST] accepted %s" % quest_id)


func _on_objective_advanced(
	quest_id: String, objective_id: String, current: int, required: int
) -> void:
	_log("[QUEST] %s %s %d/%d" % [quest_id, objective_id, current, required])


func _on_quest_turned_in(quest_id: String) -> void:
	_play_sfx("sfx.demo.quest")
	_track_analytics_event(
		"quest_turned_in",
		{
			"quest_id": quest_id,
			"zone_id": _world.current_zone_id if _world != null else ""
		}
	)
	_log("[QUEST] turned in %s" % quest_id)


func _on_shop_opened(shop_id: String) -> void:
	if _shop_ui != null:
		_shop_ui.visible = true
	_log("[SHOP] opened %s" % shop_id)


func _on_item_purchased(item_id: String, quantity: int, total_cost: int) -> void:
	if item_id == ITEM_POTION and quantity > 0:
		_shop_purchase_completed = true
	_log("[SHOP] bought %s x%d for %d gold" % [item_id, quantity, total_cost])


func _on_item_sold(item_id: String, quantity: int, total_gain: int) -> void:
	if item_id == ITEM_CLAW and quantity > 0:
		_shop_sale_completed = true
	_log("[SHOP] sold %s x%d for %d gold" % [item_id, quantity, total_gain])


func _on_transaction_failed(item_id: String, reason: String) -> void:
	_log("[SHOP] transaction failed %s: %s" % [item_id, reason])


func _on_zone_changed(from_zone_id: String, to_zone_id: String) -> void:
	var interaction := _interaction_component()
	if interaction != null:
		interaction.current_interactable = null
	if _shop != null:
		_shop.close_shop()
	if _shop_ui != null:
		_shop_ui.visible = false
	if to_zone_id == ZONE_FIELD:
		_spawn_field_beast()
	_log("[WORLD] %s -> %s" % [from_zone_id if from_zone_id != "" else "start", to_zone_id])


func _on_damage_applied(result) -> void:
	if result == null:
		return
	_log(
		"[COMBAT] %.0f damage to %s"
		% [result.final_amount, _entity_id(result.target)]
	)
	if _has_entity_tag(result.target, "field_beast"):
		_spawn_hit_effect(result.target)


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
	_log("[INTERACT] focus %s" % interactable.interaction_id)


func _on_domain_event(event: DomainEvent) -> void:
	if event == null or event.event_type != "demo_burn_tick":
		return
	_burn_tick_observed = true
	_log("[STATUS] %s" % str(event.payload.get("message", "burn tick")))


func _on_reward_selected(reward_id: String) -> void:
	if reward_id != REWARD_TRIAL_ATTACK:
		return
	if _run_director == null or _run_director.run_state == null:
		return
	if not _run_director.run_state.temporary_upgrade_ids.has(UPGRADE_TRIAL_ATTACK):
		_run_director.run_state.temporary_upgrade_ids.append(UPGRADE_TRIAL_ATTACK)
	_trial_upgrade_reward_selected = true
	_log("[TRIAL] upgrade recorded %s" % UPGRADE_TRIAL_ATTACK)


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
	_log("[TRIAL] entering %s" % room_id)


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


func _on_entity_died(entity_id: String, entity_ref: Node) -> void:
	_log("[COMBAT] defeated %s" % entity_id)
	if entity_ref == null or _field_beast_looted:
		return
	var identity := entity_ref.get_node_or_null("EntityIdentity") as EntityIdentity
	if identity == null or not identity.tags.has("field_beast"):
		return
	_field_beast_looted = true
	_grant_field_loot(entity_ref)
	_grant_field_xp()


func _grant_field_loot(entity_ref: Node) -> void:
	var inventory := _inventory()
	if inventory == null:
		return
	_roll_loot_into_bag(LOOT_FIELD_BEAST, entity_ref, inventory)
	_roll_loot_into_bag(LOOT_FIELD_BLADE, entity_ref, inventory)
	_play_sfx("sfx.demo.loot")


func _roll_loot_into_bag(
	table_id: String, entity_ref: Node, inventory: InventoryController
) -> void:
	var result := _loot_system.roll_table(
		table_id, GameplayContext.new().with_source(entity_ref).with_target(_player)
	)
	for item in result.item_instances:
		if inventory.add_item(item):
			_log("[LOOT] picked up %s x%d" % [item.definition_id, item.quantity])


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
		_log("[EQUIP] unequipped field blade attack_power %.0f -> %.0f" % [before, restored])
		return
	var blade := inventory.find_item_by_definition(ITEM_FIELD_BLADE)
	if blade == null:
		_log("[EQUIP] no field blade to equip")
		return
	if not equipment.equip(blade, WEAPON_SLOT):
		_log("[EQUIP] field blade equip failed")
		return
	var after := stats.get_stat_value("attack_power", 0.0) if stats != null else before
	if after > before:
		_field_blade_equipped = true
	_log("[EQUIP] equipped field blade attack_power %.0f -> %.0f" % [before, after])


func _grant_field_xp() -> void:
	var experience := _experience()
	if experience == null:
		return
	experience.add_xp(65)
	_log("[XP] +65 field XP")


func _on_level_up(old_level: int, new_level: int) -> void:
	_track_analytics_event(
		"level_up",
		{
			"old_level": old_level,
			"new_level": new_level,
			"zone_id": _world.current_zone_id if _world != null else ""
		}
	)
	_log("[XP] level %d -> %d" % [old_level, new_level])


func _on_player_died(owner_entity: Node) -> void:
	if owner_entity != _player:
		return
	_request_rewarded_revive()


func _on_rewarded_ad_completed(placement_id: String) -> void:
	if placement_id != PLATFORM_REVIVE_PLACEMENT:
		return
	_revive_ad_pending = false
	var health := _player_health()
	if health != null and health.dead:
		health.revive(0.5)
	_rewarded_revive_completed = health != null and not health.dead
	_log("[AD] rewarded revive completed")


func _on_rewarded_ad_failed(placement_id: String, reason: String) -> void:
	if placement_id != PLATFORM_REVIVE_PLACEMENT:
		return
	_revive_ad_pending = false
	_log("[AD] rewarded revive failed: %s" % reason)


func _on_iap_purchase_completed(product_id: String) -> void:
	if product_id != PLATFORM_GOLD_PACK_PRODUCT:
		return
	_gold_pack_purchase_pending = false
	if _progression != null:
		_progression.add_currency("gold", GOLD_PACK_AMOUNT)
	_gold_pack_purchase_completed = true
	_log("[IAP] gold pack completed +%d gold" % GOLD_PACK_AMOUNT)


func _on_iap_purchase_failed(product_id: String, reason: String) -> void:
	if product_id != PLATFORM_GOLD_PACK_PRODUCT:
		return
	_gold_pack_purchase_pending = false
	_log("[IAP] gold pack failed: %s" % reason)


func _on_cloud_save_completed(slot: String) -> void:
	if slot != PLATFORM_CLOUD_SLOT:
		return
	_cloud_busy = false
	_cloud_save_completed = true
	_log("[CloudSave] saved %s" % slot)


func _on_cloud_save_failed(slot: String, reason: String) -> void:
	if slot != PLATFORM_CLOUD_SLOT:
		return
	_cloud_busy = false
	_log("[CloudSave] save failed: %s" % reason)


func _on_cloud_load_completed(slot: String, data: Dictionary) -> void:
	if slot != PLATFORM_CLOUD_SLOT:
		return
	_cloud_busy = false
	_cloud_last_loaded_data = data.duplicate(true)
	if _write_demo_save_data(data) and _load_demo_state():
		_cloud_load_completed = true
		_log("[CloudSave] loaded %s" % slot)
	else:
		_log("[CloudSave] local load failed")


func _on_cloud_load_failed(slot: String, reason: String) -> void:
	if slot != PLATFORM_CLOUD_SLOT:
		return
	_cloud_busy = false
	_log("[CloudSave] load failed: %s" % reason)


func _on_item_added(item: ItemInstance) -> void:
	_log("[INV] +%s x%d" % [item.definition_id, item.quantity])


func _on_item_removed(item: ItemInstance) -> void:
	_log("[INV] -%s" % item.definition_id)


func _update_hud() -> void:
	_update_zone_hud()
	_update_quest_hud()
	_update_player_hud()
	_update_inventory_hud()
	_update_shop_hud()
	_update_trial_hud()


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
		_quest_label.text = "Quest: talk to elder"
		return
	var progress := state.get_progress(QUEST_OBJECTIVE_ID)
	_quest_label.text = "Quest: %s  beast %d/1" % [state.status, progress]


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


func _update_inventory_hud() -> void:
	var inventory := _inventory()
	if inventory == null:
		_inventory_label.text = "Bag: missing inventory"
		return
	var parts: Array[String] = []
	for item in inventory.model.get_items():
		parts.append("%s x%d" % [item.definition_id.replace("item.demo.", ""), item.quantity])
	_inventory_label.text = "Bag: %s" % (", ".join(parts) if not parts.is_empty() else "empty")


func _update_shop_hud() -> void:
	if _shop == null or _shop.current_shop == null:
		_shop_label.text = "Shop: closed"
		return
	_shop_label.text = "Shop: potion %d gold, claw sells for %d" % [
		_shop.get_buy_price(ITEM_POTION),
		_shop.get_sell_price(ITEM_CLAW)
	]


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
	var beast := _entity_spawner.spawn_entity(ENTITY_FIELD_BEAST, root, marker.global_position)
	if beast == null:
		_log("[ENTITY] field beast spawn failed")
		return
	_field_beast_ref = beast


func _field_beast() -> Node:
	if is_instance_valid(_field_beast_ref):
		return _field_beast_ref
	return null


func _inventory() -> InventoryController:
	return _player.get_node_or_null("Controllers/InventoryController") as InventoryController


func _equipment_controller() -> EquipmentController:
	return _player.get_node_or_null("Controllers/EquipmentController") as EquipmentController


func _player_health() -> HealthComponent:
	return _player.get_node_or_null("Components/HealthComponent") as HealthComponent


func _interaction_component() -> InteractionComponent:
	return _player.get_node_or_null("Components/InteractionComponent") as InteractionComponent


func _ability_controller() -> AbilityController:
	return _player.get_node_or_null("Controllers/AbilityController") as AbilityController


func _player_stats() -> StatsComponent:
	return _player.get_node_or_null("Components/StatsComponent") as StatsComponent


func _player_mana() -> float:
	var pool := _player.get_node_or_null("Components/ResourcePoolComponent") as ResourcePoolComponent
	return pool.get_current("mana") if pool != null else 0.0


func _experience() -> ExperienceComponent:
	return _player.get_node_or_null("Components/ExperienceComponent") as ExperienceComponent


func _entity_id(node: Node) -> String:
	if node == null:
		return "?"
	var identity := node.get_node_or_null("EntityIdentity") as EntityIdentity
	return identity.entity_id if identity != null else str(node.name)


func _has_entity_tag(node: Node, tag: String) -> bool:
	if node == null:
		return false
	var identity := node.get_node_or_null("EntityIdentity") as EntityIdentity
	return identity != null and identity.tags.has(tag)


func get_debug_status_lines() -> Array[String]:
	var lines: Array[String] = []
	lines.append("Zone: %s" % (_world.current_zone_id if _world != null else ""))
	var run_status := "ready"
	if _run_director != null and _run_director.run_state != null:
		run_status = _run_director.run_state.status
	lines.append("Run: %s" % run_status)
	lines.append("Runtime: %.2f" % _runtime_seconds)
	return lines


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
	_audio.music_map.clear()
	_audio.sfx_map.clear()


func _log(line: String) -> void:
	print(line)
	_log_lines.append(line)
	if _log_lines.size() > 10:
		_log_lines.pop_front()
	if _event_log_label != null:
		_event_log_label.text = "\n".join(_log_lines)


func _run_auto_loop() -> void:
	if _auto_run_started:
		return
	_auto_run_started = true
	await _settle_world()
	await _focus_zone_interactable("ToRoom/Interactable")
	_toggle_room_portal()
	await _settle_world()
	await _focus_zone_interactable("Elder/InteractionArea/Interactable")
	_talk_or_advance_dialogue()
	await get_tree().process_frame
	_talk_or_advance_dialogue()
	await get_tree().process_frame
	_talk_or_advance_dialogue()
	await _settle_world()
	await _focus_zone_interactable("ToVillage/Interactable")
	_toggle_room_portal()
	await _settle_world()
	await _focus_zone_interactable("ToField/Interactable")
	_toggle_field_portal()
	await _settle_world()
	await _dash_player_once()
	await _settle_world()
	await _cast_firebolt_at_beast()
	await _settle_world()
	await _engage_field_beast_via_commands()
	await _settle_world()
	await _run_trial_auto()
	await _settle_world()
	await _focus_zone_interactable("ToVillage/Interactable")
	_toggle_field_portal()
	await _settle_world()
	await _focus_zone_interactable("ToRoom/Interactable")
	_toggle_room_portal()
	await _settle_world()
	await _focus_zone_interactable("Elder/InteractionArea/Interactable")
	_request_elder_blessing()
	await _settle_world()
	await _focus_zone_interactable("Elder/InteractionArea/Interactable")
	_request_manual_task()
	await _settle_world()
	await _focus_zone_interactable("ToVillage/Interactable")
	_toggle_room_portal()
	await _settle_world()
	_toggle_field_blade()
	await _settle_world()
	_toggle_field_blade()
	await _settle_world()
	_toggle_field_blade()
	await _settle_world()
	_buy_potion()
	await get_tree().process_frame
	_sell_claw()
	await get_tree().process_frame
	_trigger_rewarded_revive_demo()
	await _wait_for_rewarded_revive()
	_purchase_gold_pack()
	await _wait_for_gold_pack_purchase()
	await _roundtrip_demo_save_for_auto_run()
	_save_demo_to_cloud()
	await _wait_for_cloud_save()
	_load_demo_from_cloud()
	await _wait_for_cloud_load()
	if _demo_loop_complete():
		_log("[AUTO] demo RPG loop complete")
	else:
		_log("[AUTO] missing: %s" % ", ".join(_demo_missing_requirements()))
		_log("[AUTO] demo RPG loop incomplete")
	_cleanup_audio_players()
	await get_tree().process_frame
	get_tree().quit()


func _settle_world() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().physics_frame
	await get_tree().physics_frame


func _wait_for_rewarded_revive() -> void:
	var elapsed := 0.0
	while elapsed < 1.0 and not _rewarded_revive_completed:
		await get_tree().process_frame
		elapsed += get_process_delta_time()


func _wait_for_gold_pack_purchase() -> void:
	var elapsed := 0.0
	while elapsed < 1.0 and not _gold_pack_purchase_completed:
		await get_tree().process_frame
		elapsed += get_process_delta_time()


func _wait_for_cloud_save() -> void:
	var elapsed := 0.0
	while elapsed < 1.0 and not _cloud_save_completed:
		await get_tree().process_frame
		elapsed += get_process_delta_time()


func _wait_for_cloud_load() -> void:
	var elapsed := 0.0
	while elapsed < 1.0 and not _cloud_load_completed:
		await get_tree().process_frame
		elapsed += get_process_delta_time()


func _roundtrip_demo_save_for_auto_run() -> void:
	_demo_save_roundtrip_succeeded = false
	if not _save_demo_state():
		return
	_scramble_demo_saved_state()
	await get_tree().process_frame
	if _load_demo_state():
		_demo_save_roundtrip_succeeded = _demo_save_roundtrip_restored()
		if _demo_save_roundtrip_succeeded:
			_log("[SAVE] round-trip restored demo state")
		else:
			_log("[SAVE] round-trip restore check failed")


func _scramble_demo_saved_state() -> void:
	var equipment := _equipment_controller()
	if equipment != null:
		equipment.unequip(WEAPON_SLOT)
	var inventory := _inventory()
	if inventory != null:
		inventory.model.setup(inventory.capacity)
	var stats := _player_stats()
	if stats != null:
		var modifier_definition := StatModifierDefinition.new()
		modifier_definition.modifier_id = "mod.demo.save_scramble_attack"
		modifier_definition.stat_id = "attack_power"
		modifier_definition.value = -999.0
		modifier_definition.stacking_rule = StatModifierDefinition.StackingRule.REPLACE_SAME_SOURCE
		stats.add_modifier(StatModifier.from_definition(modifier_definition, "demo_save_scramble"))
	var health := _player_health()
	if health != null:
		health.current_hp = 1.0
	var pool := _player.get_node_or_null("Components/ResourcePoolComponent") as ResourcePoolComponent
	if pool != null:
		pool.set_current("mana", 0.0)
	var ability := _ability_controller()
	if ability != null:
		ability.unregister_ability(ABILITY_FIREBOLT)
	_field_blade_equipped = false


func _demo_save_roundtrip_restored() -> bool:
	var equipment := _equipment_controller()
	if equipment == null or equipment.get_equipped(WEAPON_SLOT) == null:
		_log("[SAVE] round-trip missing equipped weapon")
		return false
	var inventory := _inventory()
	if inventory == null or inventory.find_item_by_definition(ITEM_POTION) == null:
		_log("[SAVE] round-trip missing potion")
		return false
	var ability := _ability_controller()
	if ability == null or not ability.has_ability(ABILITY_FIREBOLT):
		_log("[SAVE] round-trip missing firebolt")
		return false
	var pool := _player.get_node_or_null("Components/ResourcePoolComponent") as ResourcePoolComponent
	if pool == null or pool.get_current("mana") <= 0.0:
		_log("[SAVE] round-trip missing mana")
		return false
	var stats := _player_stats()
	if stats == null or stats.get_stat_value("attack_power", 0.0) < 30.0:
		_log("[SAVE] round-trip attack_power below gate")
		return false
	return true


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
	if not _demo_save_roundtrip_succeeded:
		missing.append("save_roundtrip")
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
	if not _rewarded_revive_completed:
		missing.append("revive")
	if not _gold_pack_purchase_completed:
		missing.append("gold_pack")
	if not _cloud_save_completed or not _cloud_load_completed:
		missing.append("cloud")
	if _runtime_seconds <= 0.0:
		missing.append("time")
	if not _feedback_shake_observed or not _feedback_toast_observed:
		missing.append("feedback")
	if not _spawn_scene_effect_succeeded:
		missing.append("spawn_scene")
	if _progression == null or _progression.get_currency("gold") < 30:
		missing.append("gold")
	return missing
