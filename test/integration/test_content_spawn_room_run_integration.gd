extends GutTest


const SPAWN_SCENE_PATH := "res://test/integration/tmp_mkit_int_spawn_probe.tscn"
const ENTITY_SCENE_PATH := "res://test/integration/tmp_mkit_int_room_enemy.tscn"
const ROOM_SCENE_PATH := "res://test/integration/tmp_mkit_int_room_scene.tscn"
const PLAYER_ID := "player_001"
const ROOM_ID := "room.int.combat"
const ENEMY_DEF_ID := "entity.int.enemy"
const ENEMY_ABILITY_ID := "ability.int.enemy"
const LOOT_TABLE_ID := "loot.int.enemy"
const LOOT_ITEM_ID := "item.int.loot"
const FILTERED_LOOT_ITEM_ID := "item.int.filtered"
const REWARD_ITEM_ID := "item.int.reward"
const REWARD_GOOD_ID := "reward.int.good"
const REWARD_FILTERED_ID := "reward.int.filtered"
const SPAWN_PROBE_SCRIPT := preload("res://test/integration/int_spawn_probe.gd")
const SAVE_PATH := "/tmp/mkit_content_spawn_room_run_integration_save.json"

var _current_scene_root: Node = null
var _previous_current_scene: Node = null


func after_each() -> void:
	var tree := get_tree()
	if (
		tree != null
		and _current_scene_root != null
		and tree.current_scene == _current_scene_root
	):
		tree.current_scene = _previous_current_scene
	if _current_scene_root != null and is_instance_valid(_current_scene_root):
		if _current_scene_root.get_parent() != null:
			_current_scene_root.get_parent().remove_child(_current_scene_root)
		_current_scene_root.free()
	IntTestHelpers.remove_file(SPAWN_SCENE_PATH)
	IntTestHelpers.remove_file("%s.uid" % SPAWN_SCENE_PATH)
	IntTestHelpers.remove_file(ENTITY_SCENE_PATH)
	IntTestHelpers.remove_file("%s.uid" % ENTITY_SCENE_PATH)
	IntTestHelpers.remove_file(ROOM_SCENE_PATH)
	IntTestHelpers.remove_file("%s.uid" % ROOM_SCENE_PATH)
	IntTestHelpers.remove_file(SAVE_PATH)
	IntTestHelpers.cleanup_service_registry()
	_current_scene_root = null
	_previous_current_scene = null


func test_tc_int_spawn_room_run_01_spawn_scene_effect_direct_loads_scene_and_sets_transform() -> void:
	_save_spawn_probe_scene()
	var world := _make_current_scene_root("SpawnWorld")
	var bootstrap := GameBootstrap.new()
	bootstrap.save_path = SAVE_PATH
	world.add_child(bootstrap)

	var source := Node2D.new()
	source.name = "Source"
	source.global_position = Vector2(24.0, 32.0)
	world.add_child(source)

	var target := Node2D.new()
	target.name = "Target"
	target.global_position = Vector2(96.0, 128.0)
	world.add_child(target)

	var effects := ServiceRegistry.get_service("effects") as EffectService
	assert_not_null(effects)

	var source_effect := _make_spawn_effect(false)
	var source_context := GameplayContext.new()
	source_context.source = source
	source_context.target = target
	source_context.position = Vector2(8.0, 16.0)
	source_context.direction = Vector2.RIGHT
	var source_result := effects.execute(source_effect, source_context)
	var source_spawn := world.get_child(world.get_child_count() - 1) as Node2D

	assert_true(source_result.success)
	assert_not_null(source_spawn)
	assert_eq(source_result.payload.get("instance", null), source_spawn)
	assert_eq(source_spawn.global_position, source.global_position)
	assert_eq(source_spawn.get("direction"), Vector2.RIGHT)

	var target_effect := _make_spawn_effect(true)
	var target_context := GameplayContext.new()
	target_context.source = source
	target_context.target = target
	target_context.direction = Vector2.DOWN
	var target_result := effects.execute(target_effect, target_context)
	var target_spawn := world.get_child(world.get_child_count() - 1) as Node2D

	assert_true(target_result.success)
	assert_not_null(target_spawn)
	assert_eq(target_result.payload.get("instance", null), target_spawn)
	assert_eq(target_spawn.global_position, target.global_position)
	assert_eq(target_spawn.get("direction"), Vector2.DOWN)

	var position_effect := _make_spawn_effect(false)
	var position_context := GameplayContext.new()
	position_context.position = Vector2(44.0, 55.0)
	var position_result := effects.execute(position_effect, position_context)
	var position_spawn := world.get_child(world.get_child_count() - 1) as Node2D

	assert_true(position_result.success)
	assert_not_null(position_spawn)
	assert_eq(position_result.payload.get("instance", null), position_spawn)
	assert_eq(position_spawn.global_position, position_context.position)


func test_tc_int_spawn_room_run_02_run_room_entity_reward_and_loot_pipeline() -> void:
	_save_entity_scene()
	_save_room_scene()
	var world := _make_current_scene_root("RunWorld")
	var bootstrap := GameBootstrap.new()
	bootstrap.resource_databases = [_make_content_database()]
	bootstrap.save_path = SAVE_PATH
	world.add_child(bootstrap)
	_replace_random_service()

	var player := IntTestHelpers.make_inventory_entity("Player", PLAYER_ID, 8)
	player.add_to_group("player")
	world.add_child(player)

	var room_root := Node2D.new()
	room_root.name = "RoomRoot"
	world.add_child(room_root)

	var director := RunDirector.new()
	director.name = "RunDirector"
	director.first_floor_room_pool = [ROOM_ID]
	director.run_length = 1
	director.player_entity_id = PLAYER_ID
	world.add_child(director)

	var events := ServiceRegistry.get_service("events") as EventService
	assert_not_null(events)
	watch_signals(director)
	watch_signals(events)

	director.start_run(12345)

	assert_not_null(director.run_state)
	assert_eq(director.run_state.status, "active")
	assert_not_null(director.room_graph)
	assert_eq(director.room_graph.nodes.size(), 1)
	assert_eq(director.room_graph.start_node.room_definition_id, ROOM_ID)
	assert_eq(director.room_graph.boss_node.room_definition_id, ROOM_ID)
	assert_eq(director.run_state.current_room_id, ROOM_ID)
	assert_eq(director.run_state.room_history, [ROOM_ID])
	assert_signal_emitted(director, "run_started")
	assert_signal_emitted_with_parameters(events, "run_started", [director.run_state.run_id, 12345])

	var room := director.current_room_controller
	assert_not_null(room)
	if room == null:
		return
	assert_not_null(room.runtime)
	assert_true(room.runtime.entered)
	assert_eq(room.runtime.definition_id, ROOM_ID)

	var enemies := room.get_node("../Enemies")
	assert_eq(enemies.get_child_count(), 1)
	var enemy := enemies.get_child(0) as Node2D
	assert_not_null(enemy)
	var identity := enemy.get_node("EntityIdentity") as EntityIdentity
	var stats := enemy.get_node("Components/StatsComponent") as StatsComponent
	var abilities := enemy.get_node("Controllers/AbilityController") as AbilityController
	assert_eq(identity.definition_id, ENEMY_DEF_ID)
	assert_eq(identity.display_name, "Integration Enemy")
	assert_eq(identity.faction, "hostile")
	assert_true(identity.tags.has("int_enemy"))
	assert_eq(stats.get_stat_value("max_hp"), 44.0)
	assert_true(abilities.has_ability(ENEMY_ABILITY_ID))
	assert_eq(enemy.global_position, Vector2(64.0, 32.0))
	assert_eq(room.active_enemies.size(), 1)
	assert_eq(room.runtime.active_enemy_ids.size(), 1)

	var loot := LootService.new()
	var loot_context := GameplayContext.new().with_source(enemy)
	var loot_result := loot.roll_table(LOOT_TABLE_ID, loot_context)
	assert_eq(loot_result.item_instances.size(), 1)
	assert_eq(loot_result.item_instances[0].definition_id, LOOT_ITEM_ID)
	assert_eq(loot_result.item_instances[0].quantity, 3)
	assert_false(loot_result.item_instances[0].definition_id == FILTERED_LOOT_ITEM_ID)

	watch_signals(room)
	var enemy_id := room.runtime.active_enemy_ids[0]
	events.emit_entity_died(enemy_id, enemy)

	assert_true(room.runtime.cleared)
	assert_eq(room.active_enemies.size(), 0)
	assert_eq(room.runtime.active_enemy_ids.size(), 0)
	assert_eq(room.runtime.reward_options.size(), 1)
	assert_eq(room.runtime.reward_options[0].reward_id, REWARD_GOOD_ID)
	assert_signal_emitted(room, "reward_ready")
	assert_signal_emitted(room, "room_cleared")
	assert_signal_emitted_with_parameters(events, "room_cleared", [room.runtime.room_runtime_id])
	assert_eq(director.run_state.status, "choosing_reward")
	assert_signal_emitted(director, "choosing_reward")

	var inventory := player.get_node("Controllers/InventoryController") as InventoryController
	watch_signals(inventory)
	director.select_reward(room.runtime.reward_options[0])

	assert_signal_emitted_with_parameters(events, "reward_selected", [REWARD_GOOD_ID])
	assert_signal_emitted(inventory, "item_added")
	assert_not_null(inventory.find_item_by_definition(REWARD_ITEM_ID))
	assert_true(director.run_state.reward_history.has(REWARD_GOOD_ID))
	assert_eq(director.run_state.current_room_index, 1)
	assert_eq(director.run_state.status, "completed")
	assert_signal_emitted_with_parameters(director, "run_finished", ["completed"])
	assert_signal_emitted_with_parameters(
		events, "run_finished", [director.run_state.run_id, "completed"]
	)


func test_tc_int_spawn_room_run_03_object_pool_acquire_release_roundtrip() -> void:
	_save_spawn_probe_scene()
	var bootstrap := GameBootstrap.new()
	bootstrap.save_path = SAVE_PATH
	add_child_autofree(bootstrap)
	var pool := ServiceRegistry.get_service("pool") as PoolService
	assert_not_null(pool)

	var parent := Node2D.new()
	parent.name = "PoolParent"
	add_child_autofree(parent)

	var first := pool.acquire(SPAWN_SCENE_PATH, parent)
	assert_not_null(first)
	assert_eq(first.get_parent(), parent)
	assert_eq(first.process_mode, Node.PROCESS_MODE_INHERIT)

	pool.release(SPAWN_SCENE_PATH, first)
	assert_eq(first.process_mode, Node.PROCESS_MODE_DISABLED)

	var second := pool.acquire(SPAWN_SCENE_PATH, parent)
	assert_eq(second, first)
	assert_eq(second.process_mode, Node.PROCESS_MODE_INHERIT)
	pool.clear_pool(SPAWN_SCENE_PATH)


func _make_current_scene_root(root_name: String) -> Node2D:
	var root := Node2D.new()
	root.name = root_name
	var tree := get_tree()
	tree.root.add_child(root)
	_previous_current_scene = tree.current_scene
	_current_scene_root = root
	tree.current_scene = root
	return root


func _make_spawn_effect(spawn_at_target: bool) -> SpawnSceneEffect:
	var effect := SpawnSceneEffect.new()
	effect.effect_id = "fx.int.spawn"
	effect.scene_path = SPAWN_SCENE_PATH
	effect.spawn_at_target = spawn_at_target
	return effect


func _replace_random_service() -> void:
	var random := IntTestHelpers.DeterministicRandom.new()
	random.randf_range_values = [0.0, 0.0]
	random.randi_range_values = [3]
	ServiceRegistry.unregister_service("random")
	ServiceRegistry.register_service("random", random)


func _make_content_database() -> ResourceDatabase:
	var resources: Array[Resource] = [
		_make_item(REWARD_ITEM_ID),
		_make_item(LOOT_ITEM_ID),
		_make_item(FILTERED_LOOT_ITEM_ID),
		_make_ability(),
		_make_entity_definition(),
		_make_room_definition(),
		_make_loot_table(),
		_make_reward(REWARD_GOOD_ID, true),
		_make_reward(REWARD_FILTERED_ID, false)
	]
	return IntTestHelpers.make_resource_database("spawn_room_run_int", resources)


func _make_item(item_id: String) -> ItemDefinition:
	var item := ItemDefinition.new()
	item.item_id = item_id
	item.display_name = item_id
	item.stackable = true
	item.max_stack = 99
	return item


func _make_ability() -> AbilityDefinition:
	var ability := AbilityDefinition.new()
	ability.ability_id = ENEMY_ABILITY_ID
	ability.display_name = "Integration Ability"
	ability.cooldown = 0.0
	return ability


func _make_entity_definition() -> EntityDefinition:
	var definition := EntityDefinition.new()
	definition.entity_definition_id = ENEMY_DEF_ID
	definition.display_name = "Integration Enemy"
	definition.scene_path = ENTITY_SCENE_PATH
	definition.default_faction = "hostile"
	definition.tags = ["int_enemy"]
	definition.base_stats = {"max_hp": 44.0, "attack_power": 12.0}
	definition.starting_ability_ids = [ENEMY_ABILITY_ID]
	definition.loot_table_id = LOOT_TABLE_ID
	return definition


func _make_room_definition() -> RoomDefinition:
	var definition := RoomDefinition.new()
	definition.room_id = ROOM_ID
	definition.scene_path = ROOM_SCENE_PATH
	definition.enemy_spawn_ids = [ENEMY_DEF_ID]
	definition.reward_pool_ids = [REWARD_FILTERED_ID, REWARD_GOOD_ID]
	return definition


func _make_loot_table() -> LootTableDefinition:
	var filtered := _make_loot_entry(FILTERED_LOOT_ITEM_ID, 100.0, 1, 1, false)
	var valid := _make_loot_entry(LOOT_ITEM_ID, 1.0, 2, 4, true)
	var table := LootTableDefinition.new()
	table.loot_table_id = LOOT_TABLE_ID
	table.rolls = 1
	table.allow_empty = false
	table.entries = [filtered, valid]
	return table


func _make_loot_entry(
	item_id: String,
	weight: float,
	min_quantity: int,
	max_quantity: int,
	passing: bool
) -> LootEntry:
	var entry := LootEntry.new()
	entry.content_id = item_id
	entry.weight = weight
	entry.min_quantity = min_quantity
	entry.max_quantity = max_quantity
	entry.conditions = [_make_condition(passing)]
	return entry


func _make_reward(reward_id: String, passing: bool) -> RewardDefinition:
	var reward := RewardDefinition.new()
	reward.reward_id = reward_id
	reward.display_name = reward_id
	reward.weight = 1.0
	reward.conditions = [_make_condition(passing)]
	if passing:
		var grant := IntTestHelpers.make_grant_item_effect(
			"fx.int.reward_item", REWARD_ITEM_ID, 1, true
		)
		reward.effects = [grant]
	return reward


func _make_condition(passing: bool) -> Condition:
	if passing:
		return IntTestHelpers.PassingCondition.new()
	return IntTestHelpers.FailingCondition.new()


func _save_spawn_probe_scene() -> void:
	var probe := Node2D.new()
	probe.name = "SpawnProbe"
	probe.set_script(SPAWN_PROBE_SCRIPT)
	_save_packed_scene(probe, SPAWN_SCENE_PATH)


func _save_entity_scene() -> void:
	var entity := IntTestHelpers.make_health_entity("Enemy", "enemy.int.room", 10.0)
	entity.name = "Enemy"
	var abilities := IntTestHelpers.add_ability_controller(entity, [ENEMY_ABILITY_ID])
	abilities.starting_ability_ids = [ENEMY_ABILITY_ID]

	_save_packed_scene(entity, ENTITY_SCENE_PATH)


func _save_room_scene() -> void:
	var room := Node2D.new()
	room.name = "Room"

	var enemies := Node2D.new()
	enemies.name = "Enemies"
	room.add_child(enemies)

	var spawner := EntitySpawner.new()
	spawner.name = "EntitySpawner"
	room.add_child(spawner)

	var controller := RoomController.new()
	controller.name = "RoomController"
	controller.reward_count = 2
	controller.spawn_positions = [Vector2(64.0, 32.0)]
	room.add_child(controller)

	_save_packed_scene(room, ROOM_SCENE_PATH)


func _save_packed_scene(root: Node, path: String) -> void:
	IntTestHelpers.assign_owner(root, root)
	var packed := PackedScene.new()
	var pack_error := packed.pack(root)
	assert_eq(pack_error, OK)
	if pack_error == OK:
		assert_eq(ResourceSaver.save(packed, path), OK)
	root.free()
