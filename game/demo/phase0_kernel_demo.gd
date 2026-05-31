extends Node2D

# Phase 0 validation driver.
#
# Validation target (from spec/implementation_spec.md):
#   Create a dummy entity. Send a command. State changes. Action runs.
#   Effect logs a result. Debug trace shows state path and recent events.
#
# The dummy entity, services (via GameBootstrap) and DebugOverlay are wired in
# phase0_demo.tscn. This script just feeds commands through the CommandRouter and
# lets the kernel pipeline do the rest. Watch the on-screen DebugOverlay and the
# Output log while it runs.

const TARGET_ID := "dummy_001"


func _ready() -> void:
	# Let GameBootstrap register services and the StateMachine reach its initial
	# state before we start dispatching commands.
	await get_tree().process_frame
	_run_demo()


func _run_demo() -> void:
	var router := ServiceRegistry.get_service("commands") as CommandRouter
	if router == null:
		push_error("CommandRouter service not available")
		return

	print("=== Phase 0 Kernel Demo ===")

	# 1. Send a MOVE command: Idle -> Move
	print("-> dispatch MOVE")
	router.dispatch(GameCommand.create(BuiltinCommands.MOVE, TARGET_ID, TARGET_ID, {
		"direction": Vector2.RIGHT,
	}))
	await get_tree().create_timer(0.4).timeout

	# 2. Send an ATTACK command: Move -> Attack (runs a DemoWaitAction)
	print("-> dispatch ATTACK")
	router.dispatch(GameCommand.create(BuiltinCommands.ATTACK, TARGET_ID, TARGET_ID, {}))
	# Wait for the action (0.3s) to complete, fire the LogEffect, and return to Idle.
	await get_tree().create_timer(0.6).timeout

	# 3. Send a command the current state rejects, to show graceful failure.
	print("-> dispatch STOP_MOVE (expected: unhandled in Idle)")
	var handled := router.dispatch(GameCommand.create(BuiltinCommands.STOP_MOVE, TARGET_ID, TARGET_ID, {}))
	print("   handled = %s" % handled)

	print("=== Phase 0 Demo complete (see DebugOverlay for state path + recent events) ===")


func _unhandled_input(event: InputEvent) -> void:
	# Toggle the debug overlay with F1 if one is registered.
	if event is InputEventKey and event.pressed and event.keycode == KEY_F1:
		if ServiceRegistry.has_service("debug"):
			var overlay := ServiceRegistry.get_service("debug") as DebugOverlay
			if overlay != null:
				overlay.toggle()
