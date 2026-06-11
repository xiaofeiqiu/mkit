extends GutTest


class StubReceiver:
	extends CommandReceiver
	var last_command: GameCommand = null
	var handle_return: bool = true

	func handle_unhandled_command(command: GameCommand) -> bool:
		last_command = command
		return handle_return


var router: CommandService


func before_each() -> void:
	router = CommandService.new()
	add_child_autofree(router)


func after_each() -> void:
	pass


# --- register_receiver / unregister_receiver ---


func test_tc_cr_01_dispatch_routes_to_registered_receiver() -> void:
	var recv := StubReceiver.new()
	recv.auto_register = false
	router.register_receiver("e01", recv)
	var cmd := GameCommand.create("attack", "input", "e01")
	var handled := router.dispatch(cmd)
	assert_true(handled)
	assert_eq(recv.last_command, cmd)
	recv.free()


func test_tc_cr_02_dispatch_fails_gracefully_no_receiver() -> void:
	var cmd := GameCommand.create("attack", "input", "ghost")
	watch_signals(router)
	var handled := router.dispatch(cmd)
	assert_false(handled)
	assert_signal_emitted(router, "command_failed")


func test_tc_cr_03_unregister_prevents_dispatch() -> void:
	var recv := StubReceiver.new()
	recv.auto_register = false
	router.register_receiver("e02", recv)
	router.unregister_receiver("e02")
	var cmd := GameCommand.create("move", "input", "e02")
	var handled := router.dispatch(cmd)
	assert_false(handled)
	recv.free()


func test_tc_cr_04_register_empty_id_is_rejected() -> void:
	var recv := StubReceiver.new()
	recv.auto_register = false
	router.register_receiver("", recv)
	var cmd := GameCommand.create("move", "input", "")
	var handled := router.dispatch(cmd)
	assert_false(handled)
	recv.free()


# --- dispatch signals ---


func test_tc_cr_05_command_dispatched_fires_even_on_fail() -> void:
	var cmd := GameCommand.create("heal", "ui", "nobody")
	watch_signals(router)
	router.dispatch(cmd)
	assert_signal_emitted(router, "command_dispatched")
	assert_signal_emitted(router, "command_failed")


func test_tc_cr_06_command_dispatched_fires_on_success() -> void:
	var recv := StubReceiver.new()
	recv.auto_register = false
	router.register_receiver("p01", recv)
	var cmd := GameCommand.create("dash", "input", "p01")
	watch_signals(router)
	router.dispatch(cmd)
	assert_signal_emitted(router, "command_dispatched")
	assert_signal_not_emitted(router, "command_failed")
	recv.free()


func test_tc_cr_07_command_failed_when_receiver_returns_false() -> void:
	var recv := StubReceiver.new()
	recv.auto_register = false
	recv.handle_return = false
	router.register_receiver("p02", recv)
	var cmd := GameCommand.create("attack", "input", "p02")
	watch_signals(router)
	router.dispatch(cmd)
	assert_signal_emitted(router, "command_failed")
	recv.free()


# --- dispatch edge cases ---


func test_tc_cr_08_dispatch_null_command_returns_false() -> void:
	var handled := router.dispatch(null)
	assert_false(handled)


func test_tc_cr_09_dispatch_empty_target_returns_false() -> void:
	var cmd := GameCommand.create("move", "input", "")
	var handled := router.dispatch(cmd)
	assert_false(handled)


# --- CommandReceiver history ---


func test_tc_cr_13_receive_command_appends_to_history() -> void:
	var recv := StubReceiver.new()
	recv.auto_register = false
	var cmd := GameCommand.create("attack", "src", "target")
	recv.receive_command(cmd)
	assert_eq(recv.command_history.size(), 1)
	assert_eq(recv.command_history[0], cmd)
	recv.free()


func test_tc_cr_14_history_capped_at_max() -> void:
	var recv := StubReceiver.new()
	recv.auto_register = false
	recv.max_history = 3
	for i in 5:
		recv.receive_command(GameCommand.create("cmd", "s", "t"))
	assert_eq(recv.command_history.size(), 3)
	recv.free()


func test_tc_cr_15_receive_null_returns_false() -> void:
	var recv := StubReceiver.new()
	recv.auto_register = false
	var result := recv.receive_command(null)
	assert_false(result)
	recv.free()


func test_tc_cr_16_receive_command_marks_consumed_when_fallback_handles() -> void:
	var recv := StubReceiver.new()
	recv.auto_register = false
	var cmd := GameCommand.create("interact", "src", "target")
	assert_true(recv.receive_command(cmd))
	assert_true(cmd.consumed)
	recv.free()


func test_tc_cr_17_dispatch_rejects_already_consumed_command() -> void:
	var recv := StubReceiver.new()
	recv.auto_register = false
	router.register_receiver("target", recv)
	var cmd := GameCommand.create("interact", "src", "target")
	cmd.mark_consumed()
	watch_signals(router)
	assert_false(router.dispatch(cmd))
	assert_null(recv.last_command)
	assert_signal_emitted(router, "command_dispatched")
	assert_signal_emitted_with_parameters(router, "command_failed", [cmd, "Command already consumed"])
	recv.free()
