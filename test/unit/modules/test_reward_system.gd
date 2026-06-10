extends GutTest


class StubContent:
	extends ContentService
	var _defs: Dictionary = {}

	func get_resource(id: String) -> Resource:
		return _defs.get(id, null)


class FixedRandom:
	extends RandomService
	var fixed: float = 0.0

	func randf() -> float:
		return fixed

	func randf_range(from: float, to: float) -> float:
		return from + fixed * (to - from)

	func randi_range(from: int, _to: int) -> int:
		return from


class _NeverCondition:
	extends Condition

	func evaluate(_ctx: GameplayContext) -> bool:
		return false


class _FailEffect:
	extends GameEffect

	func apply(_ctx: GameplayContext) -> EffectResult:
		return EffectResult.fail("fe", "forced")


func _make_reward_def(id: String, weight: float = 1.0) -> RewardDefinition:
	var d := RewardDefinition.new()
	d.reward_id = id
	d.weight = weight
	d.conditions = []
	d.effects = []
	return d


var system: RewardSystem
var content: StubContent
var rng: FixedRandom
var ctx: GameplayContext


func before_each() -> void:
	system = RewardSystem.new()
	content = StubContent.new()
	add_child_autofree(content)
	rng = FixedRandom.new()
	ctx = GameplayContext.new()
	ServiceRegistry.register_service("content", content)
	ServiceRegistry.register_service("random", rng)


func after_each() -> void:
	ServiceRegistry.clear()


# --- generate_options guard clauses ---


func test_tc_rwd_01_count_zero_returns_empty() -> void:
	content._defs["gold_bag"] = _make_reward_def("gold_bag")
	var result := system.generate_options(["gold_bag"], 0, ctx)
	assert_eq(result.size(), 0)


func test_tc_rwd_02_empty_pool_ids_returns_empty() -> void:
	var result := system.generate_options([], 3, ctx)
	assert_eq(result.size(), 0)


func test_tc_rwd_03_missing_content_service_returns_empty() -> void:
	ServiceRegistry.unregister_service("content")
	var result := system.generate_options(["any_pool"], 3, ctx)
	assert_eq(result.size(), 0)


func test_tc_rwd_04_unknown_pool_id_produces_no_candidates() -> void:
	var result := system.generate_options(["mystery_pool"], 3, ctx)
	assert_eq(result.size(), 0)


func test_tc_rwd_05_empty_string_entries_skipped() -> void:
	content._defs["sword_pool"] = _make_reward_def("sword_pool")
	var result := system.generate_options(["", "sword_pool", ""], 1, ctx)
	assert_eq(result.size(), 1)
	assert_eq(result[0].reward_id, "sword_pool")


# --- generate_options selection logic ---


func test_tc_rwd_06_returns_up_to_count_when_fewer_candidates() -> void:
	content._defs["r1"] = _make_reward_def("r1")
	content._defs["r2"] = _make_reward_def("r2")
	var result := system.generate_options(["r1", "r2"], 5, ctx)
	assert_eq(result.size(), 2)


func test_tc_rwd_07_returns_exactly_count_when_enough_candidates() -> void:
	for i in 4:
		content._defs["r%d" % i] = _make_reward_def("r%d" % i)
	var ids: Array[String] = []
	for k in content._defs.keys():
		ids.append(k)
	var result := system.generate_options(ids, 3, ctx)
	assert_eq(result.size(), 3)


func test_tc_rwd_08_no_duplicates_in_options() -> void:
	content._defs["gem"] = _make_reward_def("gem")
	content._defs["rune"] = _make_reward_def("rune")
	var result := system.generate_options(["gem", "rune"], 2, ctx)
	var result_ids: Array = result.map(func(o): return o.reward_id)
	assert_eq(result_ids.size(), result_ids.size())
	var unique := {}
	for id in result_ids:
		unique[id] = true
	assert_eq(unique.size(), result_ids.size())


func test_tc_rwd_09_heavier_candidate_wins_when_rng_high() -> void:
	rng.fixed = 0.99
	content._defs["stone"] = _make_reward_def("stone", 1.0)
	content._defs["gold"] = _make_reward_def("gold", 99.0)
	var result := system.generate_options(["stone", "gold"], 1, ctx)
	assert_eq(result[0].reward_id, "gold")


func test_tc_rwd_10_lighter_candidate_wins_when_rng_low() -> void:
	rng.fixed = 0.0
	content._defs["stone"] = _make_reward_def("stone", 1.0)
	content._defs["gold"] = _make_reward_def("gold", 99.0)
	var result := system.generate_options(["stone", "gold"], 1, ctx)
	assert_eq(result[0].reward_id, "stone")


# --- condition filtering ---


func test_tc_rwd_11_entry_with_failed_condition_excluded() -> void:
	var bad := _make_reward_def("bad_reward")
	bad.conditions = [_NeverCondition.new()]
	content._defs["bad_reward"] = bad
	content._defs["good_reward"] = _make_reward_def("good_reward")
	rng.fixed = 0.0
	var result := system.generate_options(["bad_reward", "good_reward"], 2, ctx)
	var result_ids: Array = result.map(func(o): return o.reward_id)
	assert_false(result_ids.has("bad_reward"))
	assert_true(result_ids.has("good_reward"))


func test_tc_rwd_12_null_context_falls_back_no_crash() -> void:
	content._defs["gem"] = _make_reward_def("gem")
	var result := system.generate_options(["gem"], 1, null)
	assert_eq(result.size(), 1)


# --- apply_selected ---


func test_tc_rwd_13_null_option_returns_false() -> void:
	var result := system.apply_selected(null, ctx)
	assert_false(result)


func test_tc_rwd_14_option_no_effects_returns_true_emits_reward_selected() -> void:
	var events := EventService.new()
	add_child_autofree(events)
	ServiceRegistry.register_service("events", events)
	var executor := EffectService.new()
	ServiceRegistry.register_service("effects", executor)
	watch_signals(events)
	var option := RewardOption.new()
	option.reward_id = "speed_up"
	option.effects = []
	var result := system.apply_selected(option, ctx)
	assert_true(result)
	var evt_reward_selected_1 := DomainEventAsserts.last_event(events, "reward_selected")
	assert_not_null(evt_reward_selected_1)
	assert_eq(evt_reward_selected_1.payload.get("reward_id"), "speed_up")


func test_tc_rwd_15_option_with_failing_effect_returns_false() -> void:
	var executor := EffectService.new()
	ServiceRegistry.register_service("effects", executor)
	var option := RewardOption.new()
	option.reward_id = "broken"
	option.effects = [_FailEffect.new()]
	var result := system.apply_selected(option, ctx)
	assert_false(result)


func test_tc_rwd_16_apply_null_context_falls_back_gracefully() -> void:
	var executor := EffectService.new()
	ServiceRegistry.register_service("effects", executor)
	var option := RewardOption.new()
	option.reward_id = "safe"
	option.effects = []
	var result := system.apply_selected(option, null)
	assert_true(result)
