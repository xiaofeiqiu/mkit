extends Node2D


const ZONE_VILLAGE := "zone.phase8.village"
const ZONE_ROOM := "zone.phase8.village_room"
const ZONE_FIELD := "zone.phase8.field"
const QUEST_ID := "quest.phase8.field_report"
const QUEST_OBJECTIVE_ID := "obj.phase8.kill_field_beast"
const SHOP_ID := "shop.phase8.village_supply"
const ITEM_POTION := "item.phase8.herb_potion"
const ITEM_CLAW := "item.phase8.beast_claw"
const ITEM_CHARM := "item.phase8.village_charm"
const ITEM_FIELD_BLADE := "item.phase8.field_blade"
const WEAPON_SLOT := "weapon"
const LOOT_FIELD_BEAST := "loot.phase8.field_beast"
const LOOT_FIELD_BLADE := "loot.phase8.field_blade"
const ABILITY_FIREBOLT := "ability.phase8.firebolt"
const STATUS_BURN := "status.phase8.burn"
const PLAYER_ID := "player_001"
const MELEE_RANGE := 30.0
const FIREBOLT_RANGE := 100.0


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
@onready var _player: Node2D = $Player
@onready var _instructions_label: Label = $HUD/Instructions
@onready var _zone_label: Label = $HUD/StatsPanel/ZoneInfo
@onready var _quest_label: Label = $HUD/StatsPanel/QuestInfo
@onready var _player_label: Label = $HUD/StatsPanel/PlayerInfo
@onready var _inventory_label: Label = $HUD/StatsPanel/InventoryInfo
@onready var _shop_label: Label = $HUD/StatsPanel/ShopInfo
@onready var _event_log_label: Label = $HUD/StatsPanel/EventLog
@onready var _dialogue_ui: DialogueUI = $HUD/DialoguePanel
@onready var _quest_log_ui: QuestLogUI = $HUD/QuestLogPanel
@onready var _shop_ui: ShopUI = $HUD/ShopPanel

var _dialogue: DialogueController = null
var _quest: QuestSystem = null
var _shop: ShopController = null
var _world: WorldRouter = null
var _events: EventRouter = null
var _effects: EffectExecutor = null
var _progression: ProgressionSystem = null
var _audio: AudioManager = null
var _loot_system := LootSystem.new()
var _scene_router := EmbeddedSceneRouter.new()
var _previous_scene_router: SceneRouter = null
var _log_lines: Array[String] = []
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


func _ready() -> void:
	_auto_run_enabled = OS.get_cmdline_args().has("--phase8-auto-run")
	_resolve_services()
	_configure_embedded_router()
	_reset_demo_state()
	_configure_audio()
	_bind_ui()
	_connect_signals()
	_grant_starter_currency()
	_set_instructions()
	_log("[PHASE8] RPG loop demo ready")
	_go_to_zone(ZONE_VILLAGE, "village_square")
	if _auto_run_enabled:
		_run_auto_loop.call_deferred()


func _process(_delta: float) -> void:
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
			KEY_F:
				_cast_firebolt_command()
			KEY_E:
				_toggle_field_blade()
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
	_progression = ServiceRegistry.get_service("progression") as ProgressionSystem
	_audio = ServiceRegistry.get_service("audio") as AudioManager


func _configure_embedded_router() -> void:
	_scene_router.name = "Phase8EmbeddedSceneRouter"
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


func _configure_audio() -> void:
	if _audio == null:
		return
	_audio.music_bus = "Master"
	_audio.sfx_bus = "Master"
	if _auto_run_enabled:
		return
	_audio.music_map = {
		"bgm.phase8.village": _make_audio_stream(),
		"bgm.phase8.room": _make_audio_stream(),
		"bgm.phase8.field": _make_audio_stream()
	}
	_audio.sfx_map = {
		"sfx.phase8.dialogue": _make_audio_stream(),
		"sfx.phase8.quest": _make_audio_stream(),
		"sfx.phase8.loot": _make_audio_stream(),
		"sfx.phase8.shop": _make_audio_stream()
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
		_events.entity_died.connect(_on_entity_died)
		_events.damage_applied.connect(_on_damage_applied)
	var experience := _experience()
	if experience != null:
		experience.level_up.connect(_on_level_up)
	var inventory := _inventory()
	if inventory != null:
		inventory.item_added.connect(_on_item_added)
		inventory.item_removed.connect(_on_item_removed)


func _grant_starter_currency() -> void:
	if _progression != null:
		_progression.add_currency("gold", 10)


func _set_instructions() -> void:
	_instructions_label.text = (
		"Phase 8 RPG loop: R room portal, T talk/choice/advance, R back, G field portal, "
		+ "F cast firebolt, K defeat beast, E equip/unequip blade, Y elder blessing, "
		+ "B buy potion, V sell claw, H use potion"
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
	var root := _current_zone_root()
	if root == null:
		_log("[WORLD] zone scene is not ready")
		return false
	var portal := root.get_node_or_null(portal_name) as Portal
	if portal == null:
		_log("[WORLD] missing portal: %s" % portal_name)
		return false
	var ctx := GameplayContext.new().with_source(_player)
	if not portal.interact(ctx):
		_log("[WORLD] portal failed: %s" % portal_name)
		return false
	return true


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
	var root := _current_zone_root()
	if root == null:
		return
	var elder := root.get_node_or_null("Elder")
	if elder == null:
		_log("[DIALOGUE] elder not found")
		return
	var interactable := elder.get_node_or_null("Controllers/DialogueInteractable") as DialogueInteractable
	if interactable == null:
		_log("[DIALOGUE] elder has no DialogueInteractable")
		return
	var ctx := GameplayContext.new().with_source(_player).with_target(elder)
	if not interactable.interact(ctx):
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
	var root := _current_zone_root()
	if root == null:
		return
	var elder := root.get_node_or_null("Elder")
	if elder == null:
		_log("[DIALOGUE] elder not found")
		return
	var interactable := elder.get_node_or_null("Controllers/DialogueInteractable") as DialogueInteractable
	if interactable == null:
		_log("[DIALOGUE] elder has no DialogueInteractable")
		return
	var ctx := GameplayContext.new().with_source(_player).with_target(elder)
	if not interactable.interact(ctx):
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
	damage.effect_id = "effect.phase8.manual_strike"
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
	damage.effect_id = "effect.phase8.beast_counter"
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
		_play_sfx("sfx.phase8.shop")


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
		_play_sfx("sfx.phase8.shop")


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


func _on_dialogue_started(dialogue_id: String) -> void:
	if _dialogue_ui != null:
		_dialogue_ui.visible = true
	_play_sfx("sfx.phase8.dialogue")
	_log("[DIALOGUE] started %s" % dialogue_id)


func _on_dialogue_ended(dialogue_id: String) -> void:
	_log("[DIALOGUE] ended %s" % dialogue_id)


func _on_quest_accepted(quest_id: String) -> void:
	_play_sfx("sfx.phase8.quest")
	_log("[QUEST] accepted %s" % quest_id)


func _on_objective_advanced(
	quest_id: String, objective_id: String, current: int, required: int
) -> void:
	_log("[QUEST] %s %s %d/%d" % [quest_id, objective_id, current, required])


func _on_quest_turned_in(quest_id: String) -> void:
	_play_sfx("sfx.phase8.quest")
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
	if _shop != null:
		_shop.close_shop()
	if _shop_ui != null:
		_shop_ui.visible = false
	_log("[WORLD] %s -> %s" % [from_zone_id if from_zone_id != "" else "start", to_zone_id])


func _on_damage_applied(result) -> void:
	if result == null:
		return
	_log(
		"[COMBAT] %.0f damage to %s"
		% [result.final_amount, _entity_id(result.target)]
	)


func _on_domain_event(event: DomainEvent) -> void:
	if event == null or event.event_type != "phase8_burn_tick":
		return
	_burn_tick_observed = true
	_log("[STATUS] %s" % str(event.payload.get("message", "burn tick")))


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
	_play_sfx("sfx.phase8.loot")


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
	_log("[XP] level %d -> %d" % [old_level, new_level])


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
		parts.append("%s x%d" % [item.definition_id.replace("item.phase8.", ""), item.quantity])
	_inventory_label.text = "Bag: %s" % (", ".join(parts) if not parts.is_empty() else "empty")


func _update_shop_hud() -> void:
	if _shop == null or _shop.current_shop == null:
		_shop_label.text = "Shop: closed"
		return
	_shop_label.text = "Shop: potion %d gold, claw sells for %d" % [
		_shop.get_buy_price(ITEM_POTION),
		_shop.get_sell_price(ITEM_CLAW)
	]


func _current_zone_root() -> Node:
	if _world_host.get_child_count() == 0:
		return null
	return _world_host.get_child(0)


func _field_beast() -> Node:
	var root := _current_zone_root()
	if root == null:
		return null
	return root.get_node_or_null("FieldBeast")


func _inventory() -> InventoryController:
	return _player.get_node_or_null("Controllers/InventoryController") as InventoryController


func _equipment_controller() -> EquipmentController:
	return _player.get_node_or_null("Controllers/EquipmentController") as EquipmentController


func _player_health() -> HealthComponent:
	return _player.get_node_or_null("Components/HealthComponent") as HealthComponent


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
	_toggle_room_portal()
	await _settle_world()
	_talk_or_advance_dialogue()
	await get_tree().process_frame
	_talk_or_advance_dialogue()
	await get_tree().process_frame
	_talk_or_advance_dialogue()
	await _settle_world()
	_toggle_room_portal()
	await _settle_world()
	_toggle_field_portal()
	await _settle_world()
	await _cast_firebolt_at_beast()
	await _settle_world()
	await _engage_field_beast_via_commands()
	await _settle_world()
	_toggle_field_portal()
	await _settle_world()
	_toggle_room_portal()
	await _settle_world()
	_request_elder_blessing()
	await _settle_world()
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
	if _phase8_loop_complete():
		_log("[AUTO] phase8 RPG loop complete")
	else:
		_log("[AUTO] phase8 RPG loop incomplete")
	_cleanup_audio_players()
	await get_tree().process_frame
	get_tree().quit()


func _settle_world() -> void:
	await get_tree().process_frame
	await get_tree().process_frame


func _phase8_loop_complete() -> bool:
	if _world == null or _world.current_zone_id != ZONE_VILLAGE:
		return false
	if _quest == null:
		return false
	var state := _quest.get_state(QUEST_ID)
	if state == null or state.status != "turned_in":
		return false
	var inventory := _inventory()
	if inventory == null:
		return false
	if inventory.find_item_by_definition(ITEM_CHARM) == null:
		return false
	if inventory.find_item_by_definition(ITEM_POTION) == null:
		return false
	if inventory.find_item_by_definition(ITEM_CLAW) != null:
		return false
	var experience := _experience()
	if experience == null or experience.current_level < 2:
		return false
	if not _firebolt_cast_succeeded:
		return false
	if not _burn_tick_observed:
		return false
	if not _elder_blessing_received:
		return false
	if not _command_combat_succeeded:
		return false
	if not _field_blade_equipped:
		return false
	var equipment := _equipment_controller()
	if equipment == null or equipment.get_equipped(WEAPON_SLOT) == null:
		return false
	var stats := _player_stats()
	if stats == null or stats.get_stat_value("attack_power", 0.0) < 21.0:
		return false
	if not _shop_purchase_completed or not _shop_sale_completed:
		return false
	return _progression != null and _progression.get_currency("gold") >= 30
