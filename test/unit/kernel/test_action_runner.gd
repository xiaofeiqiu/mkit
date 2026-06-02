extends GutTest


class InstantAction:
	extends GameAction

	func _on_start() -> void:
		complete()


class NeverEndingAction:
	extends GameAction

	func _on_start() -> void:
		pass


var runner: ActionRunner


func before_each() -> void:
	runner = ActionRunner.new()
	add_child_autofree(runner)


# --- start_action ---


func test_tc_ar_01_start_action_returns_action_and_emits_started() -> void:
	var action := InstantAction.new()
	var ctx := ActionContext.new()
	watch_signals(runner)
	var result := runner.start_action(action, ctx)
	assert_eq(result, action)
	assert_signal_emitted(runner, "action_started")


func test_tc_ar_02_start_action_null_action_returns_null() -> void:
	var result := runner.start_action(null, ActionContext.new())
	assert_null(result)


func test_tc_ar_03_start_action_null_context_returns_null() -> void:
	var result := runner.start_action(InstantAction.new(), null)
	assert_null(result)


func test_tc_ar_04_started_action_appears_in_active_actions() -> void:
	var action := NeverEndingAction.new()
	runner.start_action(action, ActionContext.new())
	assert_true(runner.active_actions.has(action))


# --- action lifecycle — completion ---


func test_tc_ar_05_finished_action_removed_after_process() -> void:
	var action := InstantAction.new()
	runner.start_action(action, ActionContext.new())
	runner._process(0.016)
	assert_false(runner.active_actions.has(action))


func test_tc_ar_06_action_completed_signal_fires_when_finished() -> void:
	var action := InstantAction.new()
	runner.start_action(action, ActionContext.new())
	watch_signals(runner)
	runner._process(0.016)
	assert_signal_emitted(runner, "action_completed")


# --- action lifecycle — cancellation ---


func test_tc_ar_07_cancel_actions_for_source_cancels_matching() -> void:
	var source := Node.new()
	add_child_autofree(source)
	var action := NeverEndingAction.new()
	var ctx := ActionContext.new()
	ctx.source = source
	runner.start_action(action, ctx)
	watch_signals(runner)
	runner.cancel_actions_for_source(source, "test")
	runner._process(0.016)
	assert_signal_emitted(runner, "action_cancelled")
	assert_false(runner.active_actions.has(action))


func test_tc_ar_08_cancel_ignores_actions_from_other_sources() -> void:
	var src_a := Node.new()
	var src_b := Node.new()
	add_child_autofree(src_a)
	add_child_autofree(src_b)
	var action := NeverEndingAction.new()
	var ctx := ActionContext.new()
	ctx.source = src_a
	runner.start_action(action, ctx)
	runner.cancel_actions_for_source(src_b, "irrelevant")
	assert_true(runner.active_actions.has(action))


func test_tc_ar_09_cancel_with_null_source_is_safe() -> void:
	runner.cancel_actions_for_source(null)
	assert_true(true)


# --- multiple concurrent actions ---


func test_tc_ar_10_multiple_actions_run_in_parallel() -> void:
	var a1 := NeverEndingAction.new()
	var a2 := NeverEndingAction.new()
	runner.start_action(a1, ActionContext.new())
	runner.start_action(a2, ActionContext.new())
	assert_eq(runner.active_actions.size(), 2)


func test_tc_ar_11_same_action_twice_does_not_double_connect_signals() -> void:
	var action := NeverEndingAction.new()
	runner.start_action(action, ActionContext.new())
	runner.start_action(action, ActionContext.new())
	assert_eq(runner.active_actions.size(), 2)
	assert_eq(action.completed.get_connections().size(), 1)
