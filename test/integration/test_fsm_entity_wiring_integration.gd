extends GutTest

# Verifies that a flat Fsm can be mounted on the standard EntityRoot/StateMachine
# node and be driven by the command pipeline (CommandReceiver) with no changes to
# the wiring layer, which now programs against StateMachineBase.


class FsmIdleState:
	extends FsmState

	func handle_command(command: GameCommand) -> bool:
		if command.command_type != "move":
			return false
		blackboard.set_value("last_command_type", command.command_type)
		return request_transition("move", {"reason": command.command_type})


class FsmMoveState:
	extends FsmState
	var entered: bool = false

	func enter(_context: Dictionary = {}) -> void:
		entered = true


var entity: EntityRoot
var sm: Fsm
var idle: FsmIdleState
var move: FsmMoveState
var receiver: CommandReceiver


func before_each() -> void:
	entity = EntityRoot.new()
	entity.name = "FsmEntity"

	var identity := EntityIdentity.new()
	identity.name = "EntityIdentity"
	identity.entity_id = "fsm.int"
	entity.add_child(identity)

	sm = Fsm.new()
	sm.name = "StateMachine"
	sm.auto_start = true
	sm.initial_state_id = "idle"
	idle = FsmIdleState.new()
	idle.name = "Idle"
	idle.state_id = "idle"
	sm.add_child(idle)
	move = FsmMoveState.new()
	move.name = "Move"
	move.state_id = "move"
	sm.add_child(move)
	entity.add_child(sm)

	receiver = CommandReceiver.new()
	receiver.name = "CommandReceiver"
	receiver.auto_register = false
	entity.add_child(receiver)

	add_child_autofree(entity)


func after_each() -> void:
	IntTestHelpers.cleanup_service_registry()


func test_tc_int_fsm_01_wiring_resolves_flat_fsm_as_state_machine_base() -> void:
	var resolved := EntityContract.get_state_machine(receiver) as StateMachineBase
	assert_eq(resolved, sm)
	assert_eq(receiver.state_machine, sm)
	assert_eq(sm.get_current_id(), "idle")


func test_tc_int_fsm_02_command_pipeline_drives_fsm_transition() -> void:
	watch_signals(sm)
	var command := GameCommand.create("move", "input", "fsm.int")
	var handled := receiver.receive_command(command)
	assert_true(handled)
	assert_true(command.consumed)
	assert_eq(sm.get_current_id(), "move")
	assert_eq(sm.previous_id, "idle")
	assert_true(move.entered)
	assert_eq(sm.blackboard.get_value("last_command_type", ""), "move")
	assert_signal_emitted(sm, "state_changed")


func test_tc_int_fsm_03_unconsumed_command_does_not_transition_or_bubble() -> void:
	var command := GameCommand.create("jump", "input", "fsm.int")
	var handled := receiver.receive_command(command)
	assert_false(handled)
	assert_false(command.consumed)
	assert_eq(sm.get_current_id(), "idle")
