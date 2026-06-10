extends GutTest


const VILLAGE_SCENE_PATH := "res://test/integration/tmp_mkit_int_world_village.tscn"
const FIELD_SCENE_PATH := "res://test/integration/tmp_mkit_int_world_field.tscn"
const ZONE_VILLAGE := "zone.int.village"
const ZONE_FIELD := "zone.int.field"
const QUEST_REACH_ID := "quest.int.reach"
const OBJECTIVE_ID := "obj.reach_field"
const REWARD_ITEM_ID := "item.int.world_reward"
const VILLAGE_GATE_POS := Vector2(50.0, 50.0)
const VILLAGE_RETURN_POS := Vector2(70.0, 70.0)
const FIELD_ENTRY_POS := Vector2(300.0, 120.0)
const SAVE_PATH := "/tmp/mkit_world_pipeline_integration_save.json"


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
	IntTestHelpers.remove_file(SAVE_PATH)
	IntTestHelpers.cleanup_service_registry()


func test_tc_int_world_01_portal_navigation_places_player_and_advances_quest() -> void:
	_save_village_scene()
	_save_field_scene()

	var bootstrap := ModuleBootstrap.new()
	bootstrap.resource_databases = [_make_database()]
	bootstrap.save_path = SAVE_PATH
	add_child_autofree(bootstrap)

	var content := ServiceRegistry.get_service("content") as ContentService
	var events := ServiceRegistry.get_service("events") as EventService
	var quest := ServiceRegistry.get_service("quest") as QuestService
	var progression := ServiceRegistry.get_service("progression") as ProgressionService
	assert_not_null(content)
	assert_not_null(events)
	assert_not_null(quest)
	assert_not_null(progression)

	var host := Node2D.new()
	host.name = "WorldHost"
	add_child_autofree(host)
	var router := TestSceneRouter.new()
	router.host = host
	add_child_autofree(router)
	ServiceRegistry.unregister_service("scenes")
	ServiceRegistry.register_service("scenes", router)

	var audio := AudioProbe.new()
	add_child_autofree(audio)
	ServiceRegistry.unregister_service("audio")
	ServiceRegistry.register_service("audio", audio)

	var world := ServiceRegistry.get_service("world") as WorldService
	assert_not_null(world)
	world.scene_router = null

	var player := _make_player()
	var inventory := player.get_node("Controllers/InventoryController") as InventoryController

	var accept_context := GameplayContext.new().with_source(player)
	assert_true(quest.accept_quest(QUEST_REACH_ID, accept_context))
	assert_eq(quest.get_state(QUEST_REACH_ID).status, "active")

	watch_signals(world)
	watch_signals(events)
	watch_signals(quest)

	assert_true(world.go_to_zone(ZONE_VILLAGE, "village_gate"))
	await _settle()

	assert_eq(world.current_zone_id, ZONE_VILLAGE)
	assert_eq(player.global_position, VILLAGE_GATE_POS)
	assert_signal_emitted_with_parameters(world, "zone_changed", ["", ZONE_VILLAGE])
	assert_eq(audio.played.size(), 1)
	assert_eq(audio.played[0], "bgm.village")
	assert_eq(quest.get_state(QUEST_REACH_ID).get_progress(OBJECTIVE_ID), 0)

	var portal := host.get_child(0).get_node_or_null("ToField") as Portal
	assert_not_null(portal)
	assert_true(portal.interact(GameplayContext.new().with_source(player)))
	await _settle()

	assert_eq(world.current_zone_id, ZONE_FIELD)
	assert_eq(player.global_position, FIELD_ENTRY_POS)
	assert_signal_emitted_with_parameters(world, "zone_changed", [ZONE_VILLAGE, ZONE_FIELD])
	var evt_zone_changed_1 := DomainEventAsserts.last_event(events, "zone_changed")
	assert_not_null(evt_zone_changed_1)
	assert_eq(evt_zone_changed_1.payload.get("from_zone_id"), ZONE_VILLAGE)
	assert_eq(evt_zone_changed_1.payload.get("to_zone_id"), ZONE_FIELD)
	assert_eq(audio.played.size(), 2)
	assert_eq(audio.played[1], "bgm.field")

	assert_eq(quest.get_state(QUEST_REACH_ID).status, "turned_in")
	assert_signal_emitted_with_parameters(quest, "quest_turned_in", [QUEST_REACH_ID])
	assert_not_null(inventory.find_item_by_definition(REWARD_ITEM_ID))
	assert_eq(progression.get_currency("gold"), 5)
	assert_eq(world.get_current_zone().zone_id, ZONE_FIELD)


func _settle() -> void:
	await get_tree().process_frame
	await get_tree().process_frame


func _make_database() -> ResourceDatabase:
	var village := _make_zone(ZONE_VILLAGE, VILLAGE_SCENE_PATH, "village_gate", "bgm.village")
	var field := _make_zone(ZONE_FIELD, FIELD_SCENE_PATH, "field_entry", "bgm.field")
	var reward_item := IntTestHelpers.make_item_definition(REWARD_ITEM_ID, true, 99)
	var objective := IntTestHelpers.make_quest_objective_definition(
		OBJECTIVE_ID, "zone_entered", "zone_id", ZONE_FIELD, 1
	)
	var grant_item := IntTestHelpers.make_grant_item_effect(
		"fx.int.world_reward_item", REWARD_ITEM_ID, 1, true
	)
	var grant_gold := IntTestHelpers.make_grant_currency_effect(
		"fx.int.world_reward_gold", "gold", 5
	)
	var objectives: Array[QuestObjectiveDefinition] = [objective]
	var rewards: Array[GameEffect] = [grant_item, grant_gold]
	var quest := IntTestHelpers.make_quest_definition(
		QUEST_REACH_ID, "Reach the Field", objectives, rewards, true
	)
	var resources: Array[Resource] = [village, field, reward_item, quest]
	return IntTestHelpers.make_resource_database("world_int", resources)


func _make_zone(
	zone_id: String, scene_path: String, default_spawn: String, bgm: String
) -> ZoneDefinition:
	var zone := ZoneDefinition.new()
	zone.zone_id = zone_id
	zone.scene_path = scene_path
	zone.default_spawn_id = default_spawn
	zone.bgm_id = bgm
	return zone


func _make_player() -> Node2D:
	var player := IntTestHelpers.make_inventory_entity("Player", "player", 10)
	player.add_to_group("player")
	add_child_autofree(player)
	return player


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
