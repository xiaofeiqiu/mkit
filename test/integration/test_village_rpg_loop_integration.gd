extends GutTest


const VILLAGE_SCENE_PATH := "res://test/integration/tmp_mkit_int_loop_village.tscn"
const FIELD_SCENE_PATH := "res://test/integration/tmp_mkit_int_loop_field.tscn"
const ZONE_VILLAGE := "zone.int.loop.village"
const ZONE_FIELD := "zone.int.loop.field"
const BGM_VILLAGE := "bgm.int.loop.village"
const BGM_FIELD := "bgm.int.loop.field"
const QUEST_ID := "quest.int.loop.field_report"
const OBJECTIVE_ID := "obj.int.loop.kill_beast"
const DIALOGUE_ELDER := "dlg.int.loop.elder"
const NPC_ELDER := "npc.int.loop.elder"
const SHOP_ID := "shop.int.loop.supply"
const ITEM_POTION := "item.int.loop.potion"
const ITEM_CLAW := "item.int.loop.claw"
const ITEM_CHARM := "item.int.loop.charm"
const LOOT_FIELD_BEAST := "loot.int.loop.field_beast"
const BEAST_ID := "enemy.int.loop.field_beast"
const BEAST_TAG := "field_beast"
const CURRENCY := "gold"
const STARTER_GOLD := 20
const REWARD_GOLD := 15
const POTION_VALUE := 10
const CLAW_VALUE := 8
const CLAW_SELL_PRICE := 4
const LEVEL_UP_XP := 60
const VILLAGE_GATE_POS := Vector2(40.0, 40.0)
const VILLAGE_RETURN_POS := Vector2(60.0, 60.0)
const FIELD_ENTRY_POS := Vector2(200.0, 100.0)


var _save_path: String = "/tmp/mkit_village_rpg_loop_integration_save.json"


class TestSceneRouter:
	extends SceneService
	var host: Node = null

	func change_scene(scene_path: String) -> bool:
		if scene_path == "" or host == null:
			scene_change_failed.emit(scene_path, "invalid")
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


class AudioProbe:
	extends AudioService
	var played: Array[String] = []

	func play_music(music_id: String, _fade_seconds: float = 0.0) -> void:
		played.append(music_id)


func after_each() -> void:
	IntTestHelpers.remove_file(VILLAGE_SCENE_PATH)
	IntTestHelpers.remove_file("%s.uid" % VILLAGE_SCENE_PATH)
	IntTestHelpers.remove_file(FIELD_SCENE_PATH)
	IntTestHelpers.remove_file("%s.uid" % FIELD_SCENE_PATH)
	IntTestHelpers.remove_file(_save_path)
	IntTestHelpers.cleanup_service_registry()


func test_tc_int_loop_01_full_village_rpg_loop() -> void:
	_save_village_scene()
	_save_field_scene()

	# boot the real kernel + modules against the loop content database
	var bootstrap := GameBootstrap.new()
	bootstrap.resource_databases = [_make_database()]
	add_child_autofree(bootstrap)

	var content := ServiceRegistry.get_service("content") as ContentService
	var events := ServiceRegistry.get_service("events") as EventService
	var effects := ServiceRegistry.get_service("effects") as EffectService
	var dialogue := ServiceRegistry.get_service("dialogue") as DialogueService
	var quest := ServiceRegistry.get_service("quest") as QuestService
	var shop := ServiceRegistry.get_service("shop") as ShopService
	var progression := ServiceRegistry.get_service("progression") as ProgressionService
	var save := ServiceRegistry.get_service("save") as SaveService
	assert_not_null(content)
	assert_not_null(events)
	assert_not_null(effects)
	assert_not_null(dialogue)
	assert_not_null(quest)
	assert_not_null(shop)
	assert_not_null(progression)
	assert_not_null(save)
	assert_true(content.validate_all().success)
	save.save_path = _save_path

	# swap in a test scene router; the real change_scene_to_file would replace the GUT runner scene
	var host := Node2D.new()
	host.name = "WorldHost"
	add_child_autofree(host)
	var router := TestSceneRouter.new()
	router.host = host
	add_child_autofree(router)
	ServiceRegistry.unregister_service("scenes")
	ServiceRegistry.register_service("scenes", router)

	# probe the audio service so per-zone BGM can be asserted
	var audio := AudioProbe.new()
	add_child_autofree(audio)
	ServiceRegistry.unregister_service("audio")
	ServiceRegistry.register_service("audio", audio)

	var world := ServiceRegistry.get_service("world") as WorldService
	assert_not_null(world)
	world.scene_router = null

	var player := _make_player()
	var inventory := player.get_node("Controllers/InventoryController") as InventoryController
	var experience := player.get_node("Components/ExperienceComponent") as ExperienceComponent
	var elder := _make_elder()
	var beast := _make_beast()
	var loot_system := LootSystem.new()

	watch_signals(dialogue)
	watch_signals(quest)
	watch_signals(events)
	watch_signals(progression)
	watch_signals(shop)
	watch_signals(world)
	watch_signals(inventory)
	watch_signals(experience)
	watch_signals(save)

	# the gold the player carries into the run
	progression.add_currency(CURRENCY, STARTER_GOLD)
	assert_eq(progression.get_currency(CURRENCY), STARTER_GOLD)

	# --- HOP 1: enter the village zone ---
	assert_true(world.go_to_zone(ZONE_VILLAGE, "village_gate"))
	await _settle()
	assert_eq(world.current_zone_id, ZONE_VILLAGE)
	assert_eq(player.global_position, VILLAGE_GATE_POS)
	assert_signal_emitted_with_parameters(world, "zone_changed", ["", ZONE_VILLAGE])
	assert_eq(audio.played.size(), 1)
	assert_eq(audio.played[0], BGM_VILLAGE)

	# --- HOP 2: talk to the elder and accept the quest ---
	assert_null(quest.get_state(QUEST_ID))
	var talk_ctx := GameplayContext.new().with_source(player).with_target(elder)
	var elder_interactable := elder.get_node("Interactable") as DialogueInteractable
	assert_true(elder_interactable.interact(talk_ctx))
	assert_true(dialogue.is_active())
	assert_signal_emitted_with_parameters(dialogue, "dialogue_started", [DIALOGUE_ELDER])
	assert_signal_emitted_with_parameters(events, "npc_talked", [NPC_ELDER])

	dialogue.choose(0)
	assert_false(dialogue.is_active())
	assert_signal_emitted_with_parameters(events, "dialogue_ended", [DIALOGUE_ELDER])
	assert_eq(quest.get_state(QUEST_ID).status, "active")
	assert_signal_emitted_with_parameters(quest, "quest_accepted", [QUEST_ID])
	assert_eq(quest.get_state(QUEST_ID).get_progress(OBJECTIVE_ID), 0)

	# --- HOP 3: travel out to the field through the portal ---
	var to_field := host.get_child(0).get_node_or_null("ToField") as Portal
	assert_not_null(to_field)
	assert_true(to_field.interact(GameplayContext.new().with_source(player)))
	await _settle()
	assert_eq(world.current_zone_id, ZONE_FIELD)
	assert_eq(player.global_position, FIELD_ENTRY_POS)
	assert_signal_emitted_with_parameters(world, "zone_changed", [ZONE_VILLAGE, ZONE_FIELD])
	assert_eq(audio.played.size(), 2)
	assert_eq(audio.played[1], BGM_FIELD)

	# --- HOP 4: defeat the field beast -> objective advance + auto turn-in reward ---
	var beast_health := beast.get_node("Components/HealthComponent") as HealthComponent
	assert_false(beast_health.dead)
	var strike := DealDamageEffect.new()
	strike.effect_id = "fx.int.loop.strike"
	strike.base_amount = 50.0
	strike.can_crit = false
	var strike_ctx := GameplayContext.new().with_source(player).with_target(beast)
	assert_true(effects.execute(strike, strike_ctx).success)
	assert_true(beast_health.dead)
	assert_signal_emitted_with_parameters(events, "entity_died", [BEAST_ID, beast])
	assert_signal_emitted_with_parameters(
		quest, "objective_advanced", [QUEST_ID, OBJECTIVE_ID, 1, 1]
	)
	assert_signal_emitted_with_parameters(quest, "quest_completed", [QUEST_ID])
	assert_signal_emitted_with_parameters(quest, "quest_turned_in", [QUEST_ID])
	assert_eq(quest.get_state(QUEST_ID).status, "turned_in")
	assert_not_null(inventory.find_item_by_definition(ITEM_CHARM))
	assert_eq(progression.get_currency(CURRENCY), STARTER_GOLD + REWARD_GOLD)

	# the game responds to the kill by rolling the beast loot table and granting field XP
	var loot := loot_system.roll_table(
		LOOT_FIELD_BEAST, GameplayContext.new().with_source(beast).with_target(player)
	)
	for item in loot.item_instances:
		assert_true(inventory.add_item(item))
	var claw := inventory.find_item_by_definition(ITEM_CLAW)
	assert_not_null(claw)
	assert_eq(claw.quantity, 1)

	experience.add_xp(LEVEL_UP_XP)
	assert_signal_emitted_with_parameters(experience, "level_up", [1, 2])
	assert_eq(experience.current_level, 2)

	# --- HOP 5: return to the village and restock at the supply shop ---
	var to_village := host.get_child(0).get_node_or_null("ToVillage") as Portal
	assert_not_null(to_village)
	assert_true(to_village.interact(GameplayContext.new().with_source(player)))
	await _settle()
	assert_eq(world.current_zone_id, ZONE_VILLAGE)
	assert_eq(player.global_position, VILLAGE_RETURN_POS)
	assert_signal_emitted_with_parameters(world, "zone_changed", [ZONE_FIELD, ZONE_VILLAGE])
	assert_eq(audio.played.size(), 3)
	assert_eq(audio.played[2], BGM_VILLAGE)

	assert_true(shop.open_shop(SHOP_ID))
	assert_signal_emitted_with_parameters(shop, "shop_opened", [SHOP_ID])
	assert_eq(shop.get_buy_price(ITEM_POTION), POTION_VALUE)

	assert_true(shop.buy(ITEM_POTION, 1, player))
	assert_eq(progression.get_currency(CURRENCY), STARTER_GOLD + REWARD_GOLD - POTION_VALUE)
	assert_not_null(inventory.find_item_by_definition(ITEM_POTION))
	assert_signal_emitted_with_parameters(events, "item_purchased", [SHOP_ID, ITEM_POTION, 1])

	assert_eq(shop.get_sell_price(ITEM_CLAW), CLAW_SELL_PRICE)
	assert_true(shop.sell(claw.instance_id, 1, player))
	assert_null(inventory.find_item_by_definition(ITEM_CLAW))
	assert_signal_emitted_with_parameters(events, "item_sold", [SHOP_ID, ITEM_CLAW, 1])
	var expected_gold := STARTER_GOLD + REWARD_GOLD - POTION_VALUE + CLAW_SELL_PRICE
	assert_eq(progression.get_currency(CURRENCY), expected_gold)

	# --- HOP 6: persist the run and round-trip it through save/load ---
	assert_true(save.save_game(ServiceRegistry))
	assert_signal_emitted_with_parameters(save, "save_completed", [_save_path])

	quest.log = QuestLog.new()
	progression.state = ProgressionState.new()
	assert_null(quest.get_state(QUEST_ID))
	assert_eq(progression.get_currency(CURRENCY), 0)

	assert_true(save.load_game(ServiceRegistry))
	assert_signal_emitted_with_parameters(save, "load_completed", [_save_path])
	assert_eq(quest.get_state(QUEST_ID).status, "turned_in")
	assert_eq(progression.get_currency(CURRENCY), expected_gold)


func _settle() -> void:
	await get_tree().process_frame
	await get_tree().process_frame


func _make_database() -> ResourceDatabase:
	var village := _make_zone(ZONE_VILLAGE, VILLAGE_SCENE_PATH, "village_gate", BGM_VILLAGE)
	var field := _make_zone(ZONE_FIELD, FIELD_SCENE_PATH, "field_entry", BGM_FIELD)

	var potion := IntTestHelpers.make_item_definition(ITEM_POTION, true, 99, POTION_VALUE)
	var claw := IntTestHelpers.make_item_definition(ITEM_CLAW, true, 99, CLAW_VALUE)
	var charm := IntTestHelpers.make_item_definition(ITEM_CHARM, true, 99, 0)

	var objective := IntTestHelpers.make_quest_objective_definition(
		OBJECTIVE_ID, "enemy_killed", "tags", BEAST_TAG, 1
	)
	var grant_charm := IntTestHelpers.make_grant_item_effect(
		"fx.int.loop.reward_charm", ITEM_CHARM, 1, true
	)
	var grant_gold := IntTestHelpers.make_grant_currency_effect(
		"fx.int.loop.reward_gold", CURRENCY, REWARD_GOLD
	)
	var objectives: Array[QuestObjectiveDefinition] = [objective]
	var rewards: Array[GameEffect] = [grant_charm, grant_gold]
	var quest := IntTestHelpers.make_quest_definition(
		QUEST_ID, "Field Report", objectives, rewards, true
	)

	var accept := AcceptQuestEffect.new()
	accept.effect_id = "fx.int.loop.accept"
	accept.quest_id = QUEST_ID
	var choice_effects: Array[GameEffect] = [accept]
	var accept_choice := DialogueChoice.new()
	accept_choice.text = "I'll cull the field beast"
	accept_choice.next_node_id = ""
	accept_choice.effects = choice_effects
	var elder_choices: Array[DialogueChoice] = [accept_choice]
	var elder_node := DialogueNode.new()
	elder_node.node_id = "n.offer"
	elder_node.speaker_id = "elder"
	elder_node.text = "A beast prowls the field. Will you help?"
	elder_node.choices = elder_choices
	var elder_nodes: Array[DialogueNode] = [elder_node]
	var elder_dialogue := DialogueDefinition.new()
	elder_dialogue.dialogue_id = DIALOGUE_ELDER
	elder_dialogue.start_node_id = "n.offer"
	elder_dialogue.nodes = elder_nodes

	var potion_entry := ShopEntry.new()
	potion_entry.item_id = ITEM_POTION
	var entries: Array[ShopEntry] = [potion_entry]
	var shop := ShopDefinition.new()
	shop.shop_id = SHOP_ID
	shop.display_name = "Village Supply"
	shop.currency_id = CURRENCY
	shop.entries = entries
	shop.buy_price_multiplier = 1.0
	shop.sell_price_multiplier = 0.5
	shop.allow_sell = true

	var claw_entry := LootEntry.new()
	claw_entry.content_id = ITEM_CLAW
	claw_entry.weight = 1.0
	claw_entry.min_quantity = 1
	claw_entry.max_quantity = 1
	var loot_entries: Array[LootEntry] = [claw_entry]
	var loot := LootTableDefinition.new()
	loot.loot_table_id = LOOT_FIELD_BEAST
	loot.rolls = 1
	loot.entries = loot_entries
	loot.allow_empty = false

	var resources: Array[Resource] = [
		village, field, potion, claw, charm, quest, elder_dialogue, shop, loot
	]
	return IntTestHelpers.make_resource_database("village_rpg_loop_int", resources)


func _make_zone(
	zone_id: String, scene_path: String, default_spawn: String, bgm: String
) -> ZoneDefinition:
	var zone := ZoneDefinition.new()
	zone.zone_id = zone_id
	zone.scene_path = scene_path
	zone.default_spawn_id = default_spawn
	zone.bgm_id = bgm
	return zone


func _make_curve() -> ExperienceCurve:
	var curve := ExperienceCurve.new()
	curve.max_level = 20
	var thresholds: Array[int] = [50]
	curve.xp_thresholds = thresholds
	return curve


func _make_player() -> Node2D:
	var player := Node2D.new()
	player.name = "Player"
	var identity := EntityIdentity.new()
	identity.name = "EntityIdentity"
	identity.entity_id = "player"
	player.add_child(identity)
	var components := Node.new()
	components.name = "Components"
	player.add_child(components)
	var experience := ExperienceComponent.new()
	experience.name = "ExperienceComponent"
	experience.curve = _make_curve()
	experience.starting_level = 1
	components.add_child(experience)
	var controllers := Node.new()
	controllers.name = "Controllers"
	player.add_child(controllers)
	var inventory := InventoryController.new()
	inventory.name = "InventoryController"
	inventory.capacity = 10
	controllers.add_child(inventory)
	player.add_to_group("player")
	add_child_autofree(player)
	return player


func _make_elder() -> Node:
	var elder := Node2D.new()
	elder.name = "Elder"
	var identity := EntityIdentity.new()
	identity.name = "EntityIdentity"
	identity.entity_id = NPC_ELDER
	elder.add_child(identity)
	var interactable := DialogueInteractable.new()
	interactable.name = "Interactable"
	interactable.npc_id = NPC_ELDER
	interactable.dialogue_id = DIALOGUE_ELDER
	elder.add_child(interactable)
	add_child_autofree(elder)
	return elder


func _make_beast() -> Node:
	var tags: Array[String] = [BEAST_TAG]
	var beast := IntTestHelpers.make_health_entity("FieldBeast", BEAST_ID, 10.0, tags)
	add_child_autofree(beast)
	return beast


func _save_village_scene() -> void:
	var root := Node2D.new()
	root.name = "Village"
	var gate := SpawnPoint.new()
	gate.name = "VillageGate"
	gate.spawn_id = "village_gate"
	gate.position = VILLAGE_GATE_POS
	root.add_child(gate)
	var return_point := SpawnPoint.new()
	return_point.name = "VillageReturn"
	return_point.spawn_id = "village_return"
	return_point.position = VILLAGE_RETURN_POS
	root.add_child(return_point)
	var portal := Portal.new()
	portal.name = "ToField"
	portal.target_zone_id = ZONE_FIELD
	portal.target_spawn_id = "field_entry"
	root.add_child(portal)
	_save_packed_scene(root, VILLAGE_SCENE_PATH)


func _save_field_scene() -> void:
	var root := Node2D.new()
	root.name = "Field"
	var entry := SpawnPoint.new()
	entry.name = "FieldEntry"
	entry.spawn_id = "field_entry"
	entry.position = FIELD_ENTRY_POS
	root.add_child(entry)
	var portal := Portal.new()
	portal.name = "ToVillage"
	portal.target_zone_id = ZONE_VILLAGE
	portal.target_spawn_id = "village_return"
	root.add_child(portal)
	_save_packed_scene(root, FIELD_SCENE_PATH)


func _save_packed_scene(root: Node, path: String) -> void:
	IntTestHelpers.assign_owner(root, root)
	var packed := PackedScene.new()
	var pack_error := packed.pack(root)
	assert_eq(pack_error, OK)
	if pack_error == OK:
		assert_eq(ResourceSaver.save(packed, path), OK)
	root.free()
