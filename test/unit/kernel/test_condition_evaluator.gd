extends GutTest


class PassingCondition:
	extends Condition
	var calls: int = 0

	func _evaluate_impl(_context: GameplayContext) -> bool:
		calls += 1
		return true


class FailingCondition:
	extends Condition
	var calls: int = 0
	var reason: String = "blocked"

	func _evaluate_impl(_context: GameplayContext) -> bool:
		calls += 1
		return false

	func get_failure_reason(_context: GameplayContext) -> String:
		return reason


func test_tc_cond_01_evaluate_all_ignores_null_and_returns_true_when_all_pass() -> void:
	var passing := PassingCondition.new()
	var conditions: Array[Condition] = [null, passing]

	assert_true(ConditionEvaluator.evaluate_all(conditions, GameplayContext.new()))
	assert_eq(passing.calls, 1)


func test_tc_cond_02_evaluate_all_stops_on_first_failure() -> void:
	var failing := FailingCondition.new()
	var skipped := PassingCondition.new()
	var conditions: Array[Condition] = [failing, skipped]

	assert_false(ConditionEvaluator.evaluate_all(conditions, GameplayContext.new()))
	assert_eq(failing.calls, 1)
	assert_eq(skipped.calls, 0)
	var effect := GameEffect.new()
	effect.conditions = [failing]
	effect.apply(GameplayContext.new())
	assert_eq(failing.calls, 2)


func test_tc_cond_03_collect_failures_returns_reasons_for_failed_conditions_only() -> void:
	var failing_a := FailingCondition.new()
	failing_a.reason = "missing_target"
	var passing := PassingCondition.new()
	var failing_b := FailingCondition.new()
	failing_b.reason = "out_of_range"
	var conditions: Array[Condition] = [null, failing_a, passing, failing_b]

	var failures := ConditionEvaluator.collect_failures(conditions, GameplayContext.new())

	assert_eq(failures, ["missing_target", "out_of_range"])
	assert_eq(failing_a.calls, 1)
	assert_eq(passing.calls, 1)
	assert_eq(failing_b.calls, 1)
