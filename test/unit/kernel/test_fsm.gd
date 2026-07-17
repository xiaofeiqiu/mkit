extends GutTest

var entity: Node
var sm: Fsm
var state_idle: FsmState
var state_move: FsmState


func before_each() -> void:
	entity = Node.new()
	add_child_autofree(entity)
	sm = Fsm.new()
	sm.auto_start = false
	entity.add_child(sm)
	state_idle = FsmState.new()
	state_idle.state_id = "idle"
	sm.add_child(state_idle)
	state_move = FsmState.new()
	state_move.state_id = "move"
	sm.add_child(state_move)
	sm._ready()


# --- initial state / startup ---


func test_tc_fsm_01_current_state_null_before_transition() -> void:
	assert_null(sm.current_state)
	assert_eq(sm.get_current_id(), "")


func test_tc_fsm_02_transition_to_sets_current_state() -> void:
	sm.transition_to("idle")
	assert_eq(sm.current_state, state_idle)
	assert_eq(sm.get_current_id(), "idle")


func test_tc_fsm_03_auto_start_transitions_on_ready() -> void:
	var entity2 := Node.new()
	add_child_autofree(entity2)
	var sm2 := Fsm.new()
	sm2.auto_start = true
	sm2.initial_state_id = "idle"
	entity2.add_child(sm2)
	var idle2 := FsmState.new()
	idle2.state_id = "idle"
	sm2.add_child(idle2)
	sm2._ready()
	assert_eq(sm2.get_current_id(), "idle")


# --- transition_to ---


func test_tc_fsm_04_transition_to_current_state_is_noop() -> void:
	sm.transition_to("idle")
	var result := sm.transition_to("idle")
	assert_true(result)
	assert_eq(sm.get_current_id(), "idle")


func test_tc_fsm_05_transition_to_unknown_fails_and_emits() -> void:
	watch_signals(sm)
	var result := sm.transition_to("does_not_exist")
	assert_false(result)
	assert_signal_emitted(sm, "transition_failed")
	assert_eq(sm.last_failed_transition_reason, "Target state not found")


func test_tc_fsm_06_state_changed_emits_previous_and_current() -> void:
	sm.transition_to("idle")
	watch_signals(sm)
	sm.transition_to("move")
	assert_signal_emitted(sm, "state_changed")
	var params: Array = get_signal_parameters(sm, "state_changed", 0)
	assert_eq(params[0], "idle")
	assert_eq(params[1], "move")


func test_tc_fsm_07_previous_id_updated_after_transition() -> void:
	sm.transition_to("idle")
	sm.transition_to("move")
	assert_eq(sm.previous_id, "idle")


# --- can_exit / can_enter guards ---


func test_tc_fsm_08_transition_blocked_when_can_exit_returns_false() -> void:
	var locked := _LockedState.new()
	locked.state_id = "locked"
	sm.add_child(locked)
	locked.setup(sm, entity)
	sm.transition_to("locked")
	watch_signals(sm)
	var result := sm.transition_to("idle")
	assert_false(result)
	assert_eq(sm.get_current_id(), "locked")
	assert_signal_emitted(sm, "transition_failed")


func test_tc_fsm_09_transition_blocked_when_can_enter_returns_false() -> void:
	var guarded := _GuardedState.new()
	guarded.state_id = "guarded"
	sm.add_child(guarded)
	guarded.setup(sm, entity)
	sm.transition_to("idle")
	watch_signals(sm)
	var result := sm.transition_to("guarded")
	assert_false(result)
	assert_eq(sm.get_current_id(), "idle")
	assert_signal_emitted(sm, "transition_failed")


# --- handle_command ---


func test_tc_fsm_10_handle_command_returns_false_when_no_active_state() -> void:
	var cmd := GameCommand.create("attack", "input", "e")
	var result := sm.handle_command(cmd)
	assert_false(result)


func test_tc_fsm_11_handle_command_delegates_to_current_state() -> void:
	var handler := _CommandHandlerState.new()
	handler.state_id = "handler"
	sm.add_child(handler)
	handler.setup(sm, entity)
	sm.transition_to("handler")
	var cmd := GameCommand.create("dash", "src", "handler")
	var result := sm.handle_command(cmd)
	assert_true(result)
	assert_eq(handler.received, cmd)


func test_tc_fsm_12_unhandled_command_does_not_bubble() -> void:
	var silent := _NonConsumingState.new()
	silent.state_id = "silent"
	sm.add_child(silent)
	silent.setup(sm, entity)
	sm.transition_to("silent")
	var result := sm.handle_command(GameCommand.create("cmd", "s", "t"))
	assert_false(result)
	assert_true(silent.saw_command)


# --- find_state ---


func test_tc_fsm_13_find_state_returns_correct_node() -> void:
	assert_eq(sm.find_state("idle"), state_idle)


func test_tc_fsm_14_find_state_returns_null_for_invalid() -> void:
	assert_null(sm.find_state("ghost"))


# --- enter / exit / tick callbacks ---


func test_tc_fsm_15_entering_state_calls_on_enter() -> void:
	var tracker := _TrackingState.new()
	tracker.state_id = "tracker"
	sm.add_child(tracker)
	tracker.setup(sm, entity)
	sm.transition_to("tracker")
	assert_true(tracker.entered)


func test_tc_fsm_16_exiting_state_calls_on_exit() -> void:
	var tracker := _TrackingState.new()
	tracker.state_id = "tracker"
	sm.add_child(tracker)
	tracker.setup(sm, entity)
	sm.transition_to("tracker")
	sm.transition_to("idle")
	assert_true(tracker.exited)


func test_tc_fsm_17_on_exit_called_before_on_enter() -> void:
	var call_order: Array[String] = []
	var from_state := _OrderedState.new()
	from_state.state_id = "from"
	from_state.order = call_order
	var to_state := _OrderedState.new()
	to_state.state_id = "to"
	to_state.order = call_order
	sm.add_child(from_state)
	sm.add_child(to_state)
	from_state.setup(sm, entity)
	to_state.setup(sm, entity)
	sm.transition_to("from")
	call_order.clear()
	sm.transition_to("to")
	assert_eq(call_order, ["exit:from", "enter:to"])


func test_tc_fsm_18_update_only_ticks_current_state() -> void:
	var tracker := _TrackingState.new()
	tracker.state_id = "tracker"
	sm.add_child(tracker)
	tracker.setup(sm, entity)
	sm.transition_to("tracker")
	sm._process(0.5)
	sm._physics_process(0.25)
	assert_eq(tracker.update_delta, 0.5)
	assert_eq(tracker.physics_delta, 0.25)
	# idle is not current, so it must never tick
	var idle_tracker := _TrackingState.new()
	idle_tracker.state_id = "idle_tracker"
	sm.add_child(idle_tracker)
	idle_tracker.setup(sm, entity)
	sm._process(0.5)
	assert_eq(idle_tracker.update_delta, 0.0)


# --- Inner helper state classes ---


class _LockedState:
	extends FsmState

	func can_exit(_ctx: Dictionary = {}) -> bool:
		return false


class _GuardedState:
	extends FsmState

	func can_enter(_ctx: Dictionary = {}) -> bool:
		return false


class _CommandHandlerState:
	extends FsmState
	var received: GameCommand = null

	func handle_command(cmd: GameCommand) -> bool:
		received = cmd
		return true


class _NonConsumingState:
	extends FsmState
	var saw_command: bool = false

	func handle_command(_cmd: GameCommand) -> bool:
		saw_command = true
		return false


class _TrackingState:
	extends FsmState
	var entered: bool = false
	var exited: bool = false
	var update_delta: float = 0.0
	var physics_delta: float = 0.0

	func enter(_context: Dictionary = {}) -> void:
		entered = true

	func exit(_context: Dictionary = {}) -> void:
		exited = true

	func update(delta: float) -> void:
		update_delta = delta

	func physics_update(delta: float) -> void:
		physics_delta = delta


class _OrderedState:
	extends FsmState
	var order: Array = []

	func enter(_context: Dictionary = {}) -> void:
		order.append("enter:%s" % state_id)

	func exit(_context: Dictionary = {}) -> void:
		order.append("exit:%s" % state_id)
