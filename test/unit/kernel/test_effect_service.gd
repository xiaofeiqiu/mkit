extends GutTest


class OkEffect:
	extends GameEffect

	func _apply_impl(_ctx: GameplayContext) -> EffectResult:
		return EffectResult.ok("ok_effect")


class FailEffect:
	extends GameEffect

	func _apply_impl(_ctx: GameplayContext) -> EffectResult:
		return EffectResult.fail("fail_effect", "forced failure")


var executor: EffectService
var ctx: GameplayContext


func before_each() -> void:
	executor = EffectService.new()
	ctx = GameplayContext.new()


# --- execute (single) ---


func test_tc_ee_01_execute_returns_ok_for_successful_effect() -> void:
	var result := executor.execute(OkEffect.new(), ctx)
	assert_true(result.success)
	assert_eq(result.effect_id, "ok_effect")


func test_tc_ee_02_execute_returns_fail_for_failing_effect() -> void:
	var result := executor.execute(FailEffect.new(), ctx)
	assert_false(result.success)


func test_tc_ee_03_execute_null_effect_returns_fail() -> void:
	var result := executor.execute(null, ctx)
	assert_false(result.success)
	assert_eq(result.effect_id, "null_effect")


func test_tc_ee_04_result_recorded_when_trace_enabled() -> void:
	executor.trace_enabled = true
	executor.execute(OkEffect.new(), ctx)
	assert_eq(executor.recent_results.size(), 1)


func test_tc_ee_05_result_not_recorded_when_trace_disabled() -> void:
	executor.trace_enabled = false
	executor.execute(OkEffect.new(), ctx)
	assert_eq(executor.recent_results.size(), 0)


func test_tc_ee_06_recent_results_capped_at_max() -> void:
	executor.trace_enabled = true
	executor.max_recent_results = 3
	for i in 5:
		executor.execute(OkEffect.new(), ctx)
	assert_eq(executor.recent_results.size(), 3)


func test_tc_ee_06b_clear_recent_results_empties_buffer() -> void:
	executor.trace_enabled = true
	for i in 3:
		executor.execute(OkEffect.new(), ctx)
	assert_eq(executor.recent_results.size(), 3)
	executor.clear_recent_results()
	assert_eq(executor.recent_results.size(), 0)


# --- execute_many ---


func test_tc_ee_07_execute_many_returns_one_result_per_effect() -> void:
	var effects: Array[GameEffect] = [OkEffect.new(), OkEffect.new(), OkEffect.new()]
	var results := executor.execute_many(effects, ctx)
	assert_eq(results.size(), 3)
	for r in results:
		assert_true(r.success)


func test_tc_ee_08_execute_many_stop_on_failure_halts_after_first_fail() -> void:
	var effects: Array[GameEffect] = [OkEffect.new(), FailEffect.new(), OkEffect.new()]
	var results := executor.execute_many(effects, ctx, true)
	assert_eq(results.size(), 2)
	assert_true(results[0].success)
	assert_false(results[1].success)


func test_tc_ee_09_execute_many_without_stop_runs_all() -> void:
	var effects: Array[GameEffect] = [OkEffect.new(), FailEffect.new(), OkEffect.new()]
	var results := executor.execute_many(effects, ctx, false)
	assert_eq(results.size(), 3)


func test_tc_ee_10_execute_many_empty_returns_empty() -> void:
	var effects: Array[GameEffect] = []
	var results := executor.execute_many(effects, ctx)
	assert_eq(results.size(), 0)


# --- LogEffect (builtin) ---


func test_tc_ee_11_log_effect_always_returns_success() -> void:
	var effect := LogEffect.new()
	effect.message = "test log"
	var result := executor.execute(effect, ctx)
	assert_true(result.success)


# --- HealEffect (builtin) ---


func test_tc_ee_12_heal_effect_fails_when_no_health_component() -> void:
	var target := Node.new()
	add_child_autofree(target)
	ctx.target = target
	var effect := HealEffect.new()
	effect.base_amount = 30.0
	var result := executor.execute(effect, ctx)
	assert_false(result.success)


func test_tc_ee_13_heal_effect_heals_target_with_health_component() -> void:
	var target := Node.new()
	add_child_autofree(target)
	var components := Node.new()
	components.name = "Components"
	target.add_child(components)
	var health := HealthComponent.new()
	health.name = "HealthComponent"
	health.current_hp = 50.0
	components.add_child(health)
	ctx.target = target
	var effect := HealEffect.new()
	effect.base_amount = 20.0
	var result := executor.execute(effect, ctx)
	assert_true(result.success)
	assert_eq(health.current_hp, 70.0)


# --- DealDamageEffect (builtin) ---


func test_tc_ee_14_deal_damage_fails_when_no_health_component() -> void:
	var target := Node.new()
	add_child_autofree(target)
	ctx.target = target
	var effect := DealDamageEffect.new()
	effect.base_amount = 25.0
	var result := executor.execute(effect, ctx)
	assert_false(result.success)


func test_tc_ee_15_deal_damage_reduces_target_hp() -> void:
	var source := Node.new()
	add_child_autofree(source)
	var target := Node.new()
	add_child_autofree(target)
	var components := Node.new()
	components.name = "Components"
	target.add_child(components)
	var health := HealthComponent.new()
	health.name = "HealthComponent"
	health.current_hp = 80.0
	components.add_child(health)
	ctx.source = source
	ctx.target = target
	var effect := DealDamageEffect.new()
	effect.base_amount = 30.0
	effect.can_crit = false
	var result := executor.execute(effect, ctx)
	assert_true(result.success)
	assert_true(health.current_hp < 80.0)


# --- execute_many edge cases ---


# TC-EE-16: null passed directly to execute() returns a fail result (typed Array can't hold null)
func test_tc_ee_16_execute_null_directly_returns_fail() -> void:
	var result := executor.execute(null, ctx)
	assert_false(result.success)
	assert_eq(result.effect_id, "null_effect")
