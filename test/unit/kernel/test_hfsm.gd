extends GutTest

var entity: Node
var sm: Hfsm
var state_idle: HfsmState
var state_combat: HfsmState
var state_attack: HfsmState


func before_each() -> void:
	entity = Node.new()
	add_child_autofree(entity)
	sm = Hfsm.new()
	sm.auto_start = false
	entity.add_child(sm)
	var root := HfsmState.new()
	root.state_id = "root"
	root.initial_child_state_id = "idle"
	sm.add_child(root)
	state_idle = HfsmState.new()
	state_idle.state_id = "idle"
	root.add_child(state_idle)
	state_combat = HfsmState.new()
	state_combat.state_id = "combat"
	state_combat.initial_child_state_id = "attack"
	root.add_child(state_combat)
	state_attack = HfsmState.new()
	state_attack.state_id = "attack"
	state_combat.add_child(state_attack)
	sm._ready()


# --- initial state / startup ---


func test_tc_sm_01_current_leaf_state_null_before_transition() -> void:
	assert_null(sm.current_leaf_state)
	assert_eq(sm.get_current_path(), "")


func test_tc_sm_02_transition_to_sets_correct_leaf() -> void:
	sm.transition_to("root/idle")
	assert_eq(sm.current_leaf_state, state_idle)
	assert_eq(sm.get_current_path(), "root/idle")


func test_tc_sm_03_auto_start_transitions_on_ready() -> void:
	var entity2 := Node.new()
	add_child_autofree(entity2)
	var sm2 := Hfsm.new()
	sm2.auto_start = true
	sm2.initial_state_path = "root/idle"
	entity2.add_child(sm2)
	var root2 := HfsmState.new()
	root2.state_id = "root"
	root2.initial_child_state_id = "idle"
	sm2.add_child(root2)
	var idle2 := HfsmState.new()
	idle2.state_id = "idle"
	root2.add_child(idle2)
	sm2._ready()
	assert_eq(sm2.get_current_path(), "root/idle")


# --- transition_to ---


func test_tc_sm_04_transition_to_nested_follows_initial_child() -> void:
	sm.transition_to("root/combat")
	assert_eq(sm.current_leaf_state, state_attack)
	assert_eq(sm.get_current_path(), "root/combat/attack")


func test_tc_sm_05_transition_to_current_leaf_is_noop() -> void:
	sm.transition_to("root/idle")
	var result := sm.transition_to("root/idle")
	assert_true(result)
	assert_eq(sm.get_current_path(), "root/idle")


func test_tc_sm_06_transition_to_unknown_fails_and_emits() -> void:
	watch_signals(sm)
	var result := sm.transition_to("root/does_not_exist")
	assert_false(result)
	assert_signal_emitted(sm, "transition_failed")


func test_tc_sm_07_state_changed_emits_previous_and_current() -> void:
	sm.transition_to("root/idle")
	watch_signals(sm)
	sm.transition_to("root/combat")
	assert_signal_emitted(sm, "state_changed")
	var params: Array = get_signal_parameters(sm, "state_changed", 0)
	assert_eq(params[0], "root/idle")
	assert_eq(params[1], "root/combat/attack")


func test_tc_sm_08_previous_path_updated_after_transition() -> void:
	sm.transition_to("root/idle")
	sm.transition_to("root/combat")
	assert_eq(sm.previous_path, "root/idle")


# --- can_exit / can_enter guards ---


func test_tc_sm_09_transition_blocked_when_can_exit_returns_false() -> void:
	var locked := _LockedState.new()
	locked.state_id = "locked"
	sm.root_state.add_child(locked)
	locked.setup(sm, entity, sm.root_state)
	sm.transition_to("root/locked")
	watch_signals(sm)
	var result := sm.transition_to("root/idle")
	assert_false(result)
	assert_eq(sm.get_current_path(), "root/locked")
	assert_signal_emitted(sm, "transition_failed")


func test_tc_sm_10_transition_blocked_when_can_enter_returns_false() -> void:
	var guarded := _GuardedState.new()
	guarded.state_id = "guarded"
	sm.root_state.add_child(guarded)
	guarded.setup(sm, entity, sm.root_state)
	sm.transition_to("root/idle")
	watch_signals(sm)
	var result := sm.transition_to("root/guarded")
	assert_false(result)
	assert_eq(sm.get_current_path(), "root/idle")


# --- handle_command ---


func test_tc_sm_11_handle_command_returns_false_when_no_active_state() -> void:
	var cmd := GameCommand.create("attack", "input", "e")
	var result := sm.handle_command(cmd)
	assert_false(result)


func test_tc_sm_12_handle_command_delegates_to_current_state() -> void:
	var handler := _CommandHandlerState.new()
	handler.state_id = "handler"
	sm.root_state.add_child(handler)
	handler.setup(sm, entity, sm.root_state)
	sm.transition_to("root/handler")
	var cmd := GameCommand.create("dash", "src", "handler")
	var result := sm.handle_command(cmd)
	assert_true(result)
	assert_eq(handler.received, cmd)


func test_tc_sm_13_unhandled_command_bubbles_to_parent() -> void:
	var parent_state := _ParentHandlerState.new()
	parent_state.state_id = "parent"
	parent_state.initial_child_state_id = "child"
	var child_state := _CommandHandlerState.new()
	child_state.state_id = "child"
	child_state.consumes = false
	sm.root_state.add_child(parent_state)
	parent_state.add_child(child_state)
	parent_state.setup(sm, entity, sm.root_state)
	sm.transition_to("root/parent")
	sm.handle_command(GameCommand.create("cmd", "s", "t"))
	assert_true(parent_state.handled)
	assert_eq(child_state.received_count, 1)


# --- find_state_by_path ---


func test_tc_sm_14_find_state_by_path_returns_correct_node() -> void:
	sm.transition_to("root/idle")
	var result := sm.find_state_by_path("root/idle")
	assert_eq(result, state_idle)


func test_tc_sm_15_find_state_by_path_returns_null_for_invalid() -> void:
	var result := sm.find_state_by_path("root/ghost")
	assert_null(result)


# --- enter / exit callbacks ---


func test_tc_sm_16_entering_state_calls_on_enter() -> void:
	var tracker := _TrackingEnterState.new()
	tracker.state_id = "tracker"
	sm.root_state.add_child(tracker)
	tracker.setup(sm, entity, sm.root_state)
	sm.transition_to("root/idle")
	sm.transition_to("root/tracker")
	assert_true(tracker.entered)


func test_tc_sm_17_exiting_state_calls_on_exit() -> void:
	var tracker := _TrackingExitState.new()
	tracker.state_id = "tracker"
	sm.root_state.add_child(tracker)
	tracker.setup(sm, entity, sm.root_state)
	sm.transition_to("root/tracker")
	sm.transition_to("root/idle")
	assert_true(tracker.exited)


func test_tc_sm_18_on_exit_called_before_on_enter() -> void:
	var call_order: Array[String] = []
	var s_exit := _OrderedExitState.new()
	s_exit.state_id = "s_exit"
	s_exit.order = call_order
	var s_enter := _OrderedEnterState.new()
	s_enter.state_id = "s_enter"
	s_enter.order = call_order
	sm.root_state.add_child(s_exit)
	sm.root_state.add_child(s_enter)
	s_exit.setup(sm, entity, sm.root_state)
	s_enter.setup(sm, entity, sm.root_state)
	sm.transition_to("root/s_exit")
	sm.transition_to("root/s_enter")
	assert_eq(call_order, ["exit", "enter"])


# --- Inner helper state classes ---


class _LockedState:
	extends HfsmState

	func can_exit(_ctx: Dictionary = {}) -> bool:
		return false


class _GuardedState:
	extends HfsmState

	func can_enter(_ctx: Dictionary = {}) -> bool:
		return false


class _CommandHandlerState:
	extends HfsmState
	var received: GameCommand = null
	var received_count: int = 0
	var consumes: bool = true

	func handle_command(cmd: GameCommand) -> bool:
		received = cmd
		received_count += 1
		return consumes


class _ParentHandlerState:
	extends HfsmState
	var handled: bool = false

	func handle_command(cmd: GameCommand) -> bool:
		super.handle_command(cmd)
		handled = true
		return true


class _TrackingEnterState:
	extends HfsmState
	var entered: bool = false
	var enter_from: String = ""

	func enter(context: Dictionary = {}) -> void:
		entered = true
		enter_from = context.get("from_path", "")


class _TrackingExitState:
	extends HfsmState
	var exited: bool = false

	func exit(_context: Dictionary = {}) -> void:
		exited = true


class _OrderedExitState:
	extends HfsmState
	var order: Array = []

	func exit(_context: Dictionary = {}) -> void:
		order.append("exit")


class _OrderedEnterState:
	extends HfsmState
	var order: Array = []

	func enter(_context: Dictionary = {}) -> void:
		order.append("enter")
