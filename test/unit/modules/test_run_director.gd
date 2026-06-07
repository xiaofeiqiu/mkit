extends GutTest


class StubContent:
	extends ContentService
	var _defs: Dictionary = {}

	func get_resource(id: String) -> Resource:
		return _defs.get(id, null)


class _SafeDirector:
	extends RunDirector

	func enter_next_room() -> void:
		pass


class _SafeDirectorTracked:
	extends RunDirector
	var next_room_called: bool = false

	func enter_next_room() -> void:
		next_room_called = true


class _StubRoomController:
	extends RoomController

	func _ready() -> void:
		pass


class _ProbeRunDirector:
	extends RunDirector

	func get_room_runtime() -> RoomRuntime:
		return _get_active_room_runtime()


var director: RunDirector
var content: StubContent
var events: EventService
var save_manager: SaveService


func before_each() -> void:
	content = StubContent.new()
	add_child_autofree(content)
	events = EventService.new()
	add_child_autofree(events)
	save_manager = SaveService.new()
	add_child_autofree(save_manager)
	save_manager.save_path = "/tmp/mkit_unit_run_director_scope.json"
	ServiceRegistry.register_service("content", content)
	ServiceRegistry.register_service("events", events)
	ServiceRegistry.register_service("save", save_manager)
	ServiceRegistry.register_service("loot", LootService.new())
	director = RunDirector.new()
	director.first_floor_room_pool = ["room_a", "room_b"]
	director.run_length = 2
	director.player_entity_id = "player_001"
	add_child_autofree(director)


func after_each() -> void:
	ServiceRegistry.clear()


# --- start_run guard clauses ---


func test_tc_rd_01_empty_room_pool_calls_fail_run() -> void:
	director.first_floor_room_pool = []
	watch_signals(director)
	director.start_run(1)
	assert_signal_emitted(director, "run_finished")
	var params: Array = get_signal_parameters(director, "run_finished", 0)
	assert_true(str(params[0]).begins_with("failed"))


func test_tc_rd_02_run_length_zero_forces_to_1_and_creates_state() -> void:
	var safe := _SafeDirector.new()
	safe.first_floor_room_pool = ["room_a"]
	safe.run_length = 0
	safe.player_entity_id = "player_001"
	add_child_autofree(safe)
	safe.start_run(42)
	assert_not_null(safe.run_state)


func test_tc_rd_03_start_run_creates_active_run_state() -> void:
	var safe := _SafeDirector.new()
	safe.first_floor_room_pool = ["room_a"]
	safe.run_length = 1
	safe.player_entity_id = "player_001"
	add_child_autofree(safe)
	safe.start_run(7)
	assert_not_null(safe.run_state)
	assert_eq(safe.run_state.status, "active")


func test_tc_rd_04_start_run_emits_run_started() -> void:
	var safe := _SafeDirector.new()
	safe.first_floor_room_pool = ["room_a"]
	safe.run_length = 1
	safe.player_entity_id = "player_001"
	add_child_autofree(safe)
	watch_signals(safe)
	safe.start_run(99)
	assert_signal_emitted(safe, "run_started")


func test_tc_rd_05_start_run_emits_event_router_run_started() -> void:
	var safe := _SafeDirector.new()
	safe.first_floor_room_pool = ["room_a"]
	safe.run_length = 1
	safe.player_entity_id = "player_001"
	add_child_autofree(safe)
	watch_signals(events)
	safe.start_run(12)
	assert_signal_emitted(events, "run_started")


# --- complete_run / fail_run ---


func test_tc_rd_06_complete_run_sets_completed_and_emits() -> void:
	director.run_state = RunState.create(1)
	watch_signals(director)
	director.complete_run()
	assert_eq(director.run_state.status, "completed")
	assert_signal_emitted_with_parameters(director, "run_finished", ["completed"])


func test_tc_rd_07_complete_run_null_state_no_crash() -> void:
	director.complete_run()
	assert_true(true)


func test_tc_rd_08_complete_run_fires_event_router() -> void:
	director.run_state = RunState.create(1)
	watch_signals(events)
	director.complete_run()
	assert_signal_emitted(events, "run_finished")


func test_tc_rd_09_fail_run_sets_failed_and_emits() -> void:
	director.run_state = RunState.create(1)
	watch_signals(director)
	director.fail_run("timeout")
	assert_eq(director.run_state.status, "failed")
	var params: Array = get_signal_parameters(director, "run_finished", 0)
	assert_true(str(params[0]).contains("timeout"))


func test_tc_rd_10_fail_run_empty_reason_substitutes_unknown() -> void:
	director.run_state = RunState.create(1)
	watch_signals(director)
	director.fail_run("")
	var params: Array = get_signal_parameters(director, "run_finished", 0)
	assert_true(str(params[0]).contains("unknown"))


func test_tc_rd_11_fail_run_null_state_emits_run_finished() -> void:
	watch_signals(director)
	director.fail_run("crash")
	assert_signal_emitted(director, "run_finished")


# --- _on_entity_died ---


func test_tc_rd_12_player_death_triggers_fail_run() -> void:
	director.run_state = RunState.create(1)
	director.run_state.status = "active"
	watch_signals(director)
	var dummy := Node.new()
	add_child_autofree(dummy)
	events.emit_entity_died("player_001", dummy)
	assert_signal_emitted(director, "run_finished")
	var params: Array = get_signal_parameters(director, "run_finished", 0)
	assert_true(str(params[0]).contains("player_died"))


func test_tc_rd_13_non_player_death_does_not_affect_run() -> void:
	director.run_state = RunState.create(1)
	director.run_state.status = "active"
	watch_signals(director)
	var dummy := Node.new()
	add_child_autofree(dummy)
	events.emit_entity_died("enemy_001", dummy)
	assert_signal_not_emitted(director, "run_finished")
	assert_eq(director.run_state.status, "active")


func test_tc_rd_14_entity_died_ignored_when_run_failed() -> void:
	director.run_state = RunState.create(1)
	director.run_state.status = "failed"
	watch_signals(director)
	var dummy := Node.new()
	add_child_autofree(dummy)
	events.emit_entity_died("player_001", dummy)
	assert_signal_not_emitted(director, "run_finished")


func test_tc_rd_15_entity_died_ignored_when_run_completed() -> void:
	director.run_state = RunState.create(1)
	director.run_state.status = "completed"
	watch_signals(director)
	var dummy := Node.new()
	add_child_autofree(dummy)
	events.emit_entity_died("player_001", dummy)
	assert_signal_not_emitted(director, "run_finished")


# --- on_room_cleared ---


func test_tc_rd_16_on_room_cleared_no_rewards_advances_index() -> void:
	var safe := _SafeDirectorTracked.new()
	safe.player_entity_id = "player_001"
	add_child_autofree(safe)
	safe.run_state = RunState.create(1)
	safe.run_state.status = "active"
	safe.run_state.current_room_index = 0
	var rc := _StubRoomController.new()
	rc.runtime = RoomRuntime.create("room_a")
	rc.runtime.reward_options = []
	safe.on_room_cleared(rc)
	assert_eq(safe.run_state.current_room_index, 1)
	assert_true(safe.next_room_called)
	rc.free()


func test_tc_rd_17_on_room_cleared_with_rewards_emits_choosing_reward() -> void:
	var safe := _SafeDirector.new()
	safe.player_entity_id = "player_001"
	add_child_autofree(safe)
	safe.run_state = RunState.create(1)
	safe.run_state.current_room_index = 0
	var rc := _StubRoomController.new()
	rc.runtime = RoomRuntime.create("room_a")
	var opt := RewardOption.new()
	opt.reward_id = "gem"
	rc.runtime.reward_options = [opt]
	watch_signals(safe)
	safe.on_room_cleared(rc)
	assert_eq(safe.run_state.status, "choosing_reward")
	assert_signal_emitted(safe, "choosing_reward")
	rc.free()


func test_tc_rd_18_on_room_cleared_null_state_no_crash() -> void:
	director.on_room_cleared(null)
	assert_true(true)


# --- select_reward ---


func test_tc_rd_19_select_reward_null_option_is_noop() -> void:
	director.run_state = RunState.create(1)
	director.run_state.current_room_index = 0
	director.select_reward(null)
	assert_eq(director.run_state.current_room_index, 0)


func test_tc_rd_20_select_reward_applies_advances_and_continues() -> void:
	var safe := _SafeDirectorTracked.new()
	safe.player_entity_id = "player_001"
	add_child_autofree(safe)
	safe.run_state = RunState.create(1)
	safe.run_state.current_room_index = 0
	safe.run_state.status = "choosing_reward"
	var executor := EffectService.new()
	ServiceRegistry.register_service("effects", executor)
	var opt := RewardOption.new()
	opt.reward_id = "speed_up"
	opt.effects = []
	safe.select_reward(opt)
	assert_eq(safe.run_state.current_room_index, 1)
	assert_true(safe.next_room_called)
	assert_true(safe.run_state.reward_history.has("speed_up"))


func test_tc_rd_21_scoped_save_restore_without_scene_root() -> void:
	var source := _ProbeRunDirector.new()
	source.first_floor_room_pool = ["room_a", "room_b"]
	source.run_length = 2
	source.player_entity_id = "player_001"
	source.run_state = RunState.create(8606)
	source.run_state.status = "choosing_reward"
	source.run_state.current_room_index = 1
	source.run_state.current_room_id = "room_b"
	source.run_state.run_length = 2
	source.run_state.first_floor_room_pool = ["room_a", "room_b"]
	source.run_state.reward_history = ["reward.prev_1", "reward.prev_2"]
	source.room_graph = DungeonGenerator.new().generate_linear(source.first_floor_room_pool, 8606, 2)
	var runtime := RoomRuntime.create("room_b", "runtime_room_b")
	runtime.cleared = true
	runtime.active_enemy_ids = ["enemy_001", "enemy_002"]
	var pending_reward := RewardOption.new()
	pending_reward.reward_id = "reward.pending"
	runtime.reward_options = [pending_reward]
	source.current_room_controller = RoomController.new()
	source.current_room_controller.runtime = runtime
	add_child_autofree(source)

	assert_true(save_manager.save_game(null))
	source.free()

	var loaded := _ProbeRunDirector.new()
	loaded.player_entity_id = "player_001"
	loaded.first_floor_room_pool = ["room_a", "room_b"]
	loaded.run_length = 1
	add_child_autofree(loaded)
	assert_true(save_manager.load_game(null))

	assert_not_null(loaded.run_state)
	assert_eq(loaded.run_state.status, "choosing_reward")
	assert_eq(loaded.run_state.current_room_index, 1)
	assert_eq(loaded.run_state.current_room_id, "room_b")
	assert_eq(loaded.run_state.run_length, 2)
	assert_eq(loaded.run_state.first_floor_room_pool, ["room_a", "room_b"])
	assert_eq(loaded.run_state.reward_history, ["reward.prev_1", "reward.prev_2"])
	assert_eq(loaded.get_save_scopes(), ["world.run", "world.room", "world.reward"])
	assert_not_null(loaded.room_graph)
	assert_eq(loaded.room_graph.nodes.size(), 2)
	var restored_runtime := loaded.get_room_runtime()
	assert_not_null(restored_runtime)
	assert_eq(restored_runtime.room_runtime_id, "runtime_room_b")
	assert_eq(restored_runtime.definition_id, "room_b")
	assert_eq(restored_runtime.active_enemy_ids, ["enemy_001", "enemy_002"])
	assert_eq(restored_runtime.reward_options[0].reward_id, "reward.pending")
