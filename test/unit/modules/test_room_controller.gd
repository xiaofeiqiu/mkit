extends GutTest


class StubContent:
	extends ContentService
	var _defs: Dictionary = {}

	func get_resource(id: String) -> Resource:
		return _defs.get(id, null)


func _make_room_def(
	id: String, enemies: Array[String] = [], pools: Array[String] = []
) -> RoomDefinition:
	var d := RoomDefinition.new()
	d.room_id = id
	d.enemy_spawn_ids = enemies
	d.reward_pool_ids = pools
	return d


var ctrl: RoomController
var content: StubContent
var events: EventService
var entity: Node


func before_each() -> void:
	content = StubContent.new()
	add_child_autofree(content)
	events = EventService.new()
	add_child_autofree(events)
	ServiceRegistry.register_service("content", content)
	ServiceRegistry.register_service("events", events)
	entity = Node.new()
	add_child_autofree(entity)
	ctrl = RoomController.new()
	ctrl.reward_count = 3
	entity.add_child(ctrl)
	ctrl._ready()


func after_each() -> void:
	ServiceRegistry.clear()


# --- setup ---


func test_tc_rc_01_setup_valid_id_creates_runtime() -> void:
	ctrl.setup("forest_01")
	assert_not_null(ctrl.runtime)
	assert_eq(ctrl.runtime.definition_id, "forest_01")


func test_tc_rc_02_setup_empty_id_is_noop() -> void:
	ctrl.setup("")
	assert_null(ctrl.runtime)


func test_tc_rc_03_setup_twice_replaces_previous_runtime() -> void:
	ctrl.setup("room_a")
	var first := ctrl.runtime
	ctrl.setup("room_b")
	assert_ne(ctrl.runtime, first)
	assert_eq(ctrl.runtime.definition_id, "room_b")


# --- enter_room ---


func test_tc_rc_04_enter_room_without_setup_creates_runtime_from_id() -> void:
	ctrl.room_definition_id = "cave_02"
	watch_signals(ctrl)
	ctrl.enter_room()
	assert_not_null(ctrl.runtime)
	assert_true(ctrl.runtime.entered)
	assert_signal_emitted(ctrl, "room_entered")


func test_tc_rc_05_enter_room_null_runtime_empty_id_is_noop() -> void:
	watch_signals(ctrl)
	ctrl.enter_room()
	assert_signal_not_emitted(ctrl, "room_entered")


func test_tc_rc_06_enter_room_emits_room_entered_with_runtime_id() -> void:
	ctrl.setup("lobby")
	watch_signals(ctrl)
	ctrl.enter_room()
	assert_signal_emitted(ctrl, "room_entered")
	var params: Array = get_signal_parameters(ctrl, "room_entered", 0)
	assert_eq(params[0], ctrl.runtime.room_runtime_id)


# --- check_clear_condition ---


func test_tc_rc_07_check_clear_no_active_enemies_emits_room_cleared() -> void:
	ctrl.setup("combat_01")
	ctrl.runtime.entered = true
	watch_signals(ctrl)
	ctrl.check_clear_condition()
	assert_true(ctrl.runtime.cleared)
	assert_signal_emitted(ctrl, "room_cleared")


func test_tc_rc_08_check_clear_with_active_enemies_does_not_clear() -> void:
	ctrl.setup("combat_01")
	var fake_enemy := Node.new()
	ctrl.active_enemies["enemy_001"] = fake_enemy
	watch_signals(ctrl)
	ctrl.check_clear_condition()
	assert_false(ctrl.runtime.cleared)
	assert_signal_not_emitted(ctrl, "room_cleared")
	fake_enemy.free()


func test_tc_rc_09_check_clear_already_cleared_is_noop() -> void:
	ctrl.setup("combat_01")
	ctrl.runtime.cleared = true
	watch_signals(ctrl)
	ctrl.check_clear_condition()
	assert_signal_not_emitted(ctrl, "room_cleared")


func test_tc_rc_10_check_clear_null_runtime_no_crash() -> void:
	ctrl.check_clear_condition()
	assert_true(true)


func test_tc_rc_11_room_cleared_fires_event_router() -> void:
	ctrl.setup("combat_01")
	watch_signals(events)
	ctrl.check_clear_condition()
	assert_signal_emitted(events, "room_cleared")


# --- _on_entity_died integration ---


func test_tc_rc_12_entity_died_tracked_enemy_removes_and_triggers_clear() -> void:
	ctrl.setup("combat_01")
	var fake_enemy := Node.new()
	add_child_autofree(fake_enemy)
	ctrl.active_enemies["e01"] = fake_enemy
	ctrl.runtime.active_enemy_ids.append("e01")
	watch_signals(ctrl)
	events.emit_entity_died("e01", fake_enemy)
	assert_false(ctrl.active_enemies.has("e01"))
	assert_true(ctrl.runtime.cleared)
	assert_signal_emitted(ctrl, "room_cleared")


func test_tc_rc_13_entity_died_untracked_entity_ignored() -> void:
	ctrl.setup("combat_01")
	var tracked := Node.new()
	ctrl.active_enemies["e01"] = tracked
	var unrelated := Node.new()
	add_child_autofree(unrelated)
	events.emit_entity_died("unrelated", unrelated)
	assert_true(ctrl.active_enemies.has("e01"))
	tracked.free()


# --- generate_reward ---


func test_tc_rc_14_generate_reward_zero_count_emits_empty_options() -> void:
	ctrl.setup("combat_01")
	ctrl.reward_count = 0
	watch_signals(ctrl)
	ctrl.generate_reward()
	assert_signal_emitted(ctrl, "reward_ready")
	var params: Array = get_signal_parameters(ctrl, "reward_ready", 0)
	assert_eq(params[0].size(), 0)


func test_tc_rc_15_generate_reward_null_runtime_emits_empty() -> void:
	watch_signals(ctrl)
	ctrl.generate_reward()
	assert_signal_emitted(ctrl, "reward_ready")
	var params: Array = get_signal_parameters(ctrl, "reward_ready", 0)
	assert_eq(params[0].size(), 0)


func test_tc_rc_16_generate_reward_no_pool_ids_emits_empty() -> void:
	content._defs["empty_room"] = _make_room_def("empty_room", [], [])
	ctrl.setup("empty_room")
	watch_signals(ctrl)
	ctrl.generate_reward()
	var params: Array = get_signal_parameters(ctrl, "reward_ready", 0)
	assert_eq(params[0].size(), 0)


# --- get_definition ---


func test_tc_rc_17_get_definition_returns_matching_definition() -> void:
	content._defs["dungeon_a"] = _make_room_def("dungeon_a")
	ctrl.setup("dungeon_a")
	var def := ctrl.get_definition()
	assert_not_null(def)


func test_tc_rc_18_get_definition_null_when_no_content_service() -> void:
	ServiceRegistry.unregister_service("content")
	ctrl.setup("dungeon_a")
	assert_null(ctrl.get_definition())


func test_tc_rc_19_get_definition_null_when_empty_id() -> void:
	assert_null(ctrl.get_definition())
