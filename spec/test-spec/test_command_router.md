# Test Spec — CommandRouter + CommandReceiver

**Sources:**  
`addons/mkit/kernel/commands/command_router.gd`  
`addons/mkit/kernel/commands/command_receiver.gd`  
**Test file:** `test/unit/kernel/test_command_router.gd`  
**Extends:** `GutTest`

Both classes are tested together because `CommandReceiver` depends on
`CommandRouter` only through `ServiceRegistry`, which is faked in setup.

---

## Helpers (inner classes in the test file)

```gdscript
# Minimal receiver that records commands and returns a fixed value.
class StubReceiver extends CommandReceiver:
    var last_command: GameCommand = null
    var handle_return: bool = true

    func receive_command(command: GameCommand) -> bool:
        last_command = command
        return handle_return
```

---

## Setup / Teardown

```gdscript
var router: CommandRouter
var fake_registry: Node  # same script as ServiceRegistry, not the autoload

func before_each() -> void:
    router = CommandRouter.new()
    add_child_autofree(router)

func after_each() -> void:
    # router is freed by autofree
    pass
```

> `CommandReceiver._ready()` auto-registers via `ServiceRegistry`, so tests
> that create a receiver manually must either set `auto_register = false` or
> inject a fake registry service before adding the receiver to the tree.

---

## Group: register_receiver / unregister_receiver

### TC-CR-01 — dispatch routes to registered receiver
```
Arrange: recv = StubReceiver.new(); recv.auto_register = false
         router.register_receiver("e01", recv)
         cmd  = GameCommand.create("attack", "input", "e01")
Act:     handled = router.dispatch(cmd)
Assert:  handled == true
         recv.last_command == cmd
Cleanup: recv.free()
```

### TC-CR-02 — dispatch fails gracefully when no receiver registered
```
Arrange: cmd = GameCommand.create("attack", "input", "ghost")
Act:     watch_signals(router)
         handled = router.dispatch(cmd)
Assert:  handled == false
         assert_signal_emitted(router, "command_failed")
```

### TC-CR-03 — unregister prevents future dispatches
```
Arrange: recv = StubReceiver.new(); recv.auto_register = false
         router.register_receiver("e02", recv)
         router.unregister_receiver("e02")
         cmd = GameCommand.create("move", "input", "e02")
Act:     handled = router.dispatch(cmd)
Assert:  handled == false
Cleanup: recv.free()
```

### TC-CR-04 — registering empty id is rejected
```
Arrange: recv = StubReceiver.new(); recv.auto_register = false
Act:     router.register_receiver("", recv)
Assert:  (no crash; receiver not reachable via dispatch)
Cleanup: recv.free()
```

---

## Group: dispatch signals

### TC-CR-05 — command_dispatched fires even when dispatch fails
```
Arrange: cmd = GameCommand.create("heal", "ui", "nobody")
         watch_signals(router)
Act:     router.dispatch(cmd)
Assert:  assert_signal_emitted(router, "command_dispatched")
         assert_signal_emitted(router, "command_failed")
```

### TC-CR-06 — command_dispatched fires on success
```
Arrange: recv = StubReceiver.new(); recv.auto_register = false
         router.register_receiver("p01", recv)
         cmd = GameCommand.create("dash", "input", "p01")
         watch_signals(router)
Act:     router.dispatch(cmd)
Assert:  assert_signal_emitted(router, "command_dispatched")
         assert_signal_not_emitted(router, "command_failed")
Cleanup: recv.free()
```

### TC-CR-07 — command_failed fires when receiver returns false
```
Arrange: recv = StubReceiver.new(); recv.auto_register = false
         recv.handle_return = false
         router.register_receiver("p02", recv)
         cmd = GameCommand.create("attack", "input", "p02")
         watch_signals(router)
Act:     router.dispatch(cmd)
Assert:  assert_signal_emitted(router, "command_failed")
Cleanup: recv.free()
```

---

## Group: dispatch edge cases

### TC-CR-08 — dispatch with null command returns false safely
```
Act:    handled = router.dispatch(null)
Assert: handled == false
```

### TC-CR-09 — dispatch with empty target_id returns false
```
Arrange: cmd = GameCommand.create("move", "input", "")
Act:     handled = router.dispatch(cmd)
Assert:  handled == false
```

---

## Group: broadcast

### TC-CR-10 — broadcast delivers to all listed receivers
```
Arrange: r1 = StubReceiver.new(); r1.auto_register = false
         r2 = StubReceiver.new(); r2.auto_register = false
         router.register_receiver("e01", r1)
         router.register_receiver("e02", r2)
         cmd = GameCommand.create("stun", "aoe", "")
         ids: Array[String] = ["e01", "e02"]
Act:     count = router.broadcast(cmd, ids)
Assert:  count == 2
         r1.last_command != null
         r2.last_command != null
Cleanup: r1.free(); r2.free()
```

### TC-CR-11 — broadcast skips empty ids and missing ids in the list
```
Arrange: r1 = StubReceiver.new(); r1.auto_register = false
         router.register_receiver("e01", r1)
         cmd = GameCommand.create("aoe", "src", "")
         ids: Array[String] = ["e01", "", "missing"]
Act:     count = router.broadcast(cmd, ids)
Assert:  count == 1
Cleanup: r1.free()
```

### TC-CR-12 — broadcast with empty receiver_ids returns 0
```
Arrange: cmd = GameCommand.create("aoe", "src", "")
Act:     count = router.broadcast(cmd, [])
Assert:  count == 0
```

---

## Group: CommandReceiver — command history

### TC-CR-13 — receive_command appends to history
```
Arrange: recv = StubReceiver.new(); recv.auto_register = false
         cmd = GameCommand.create("attack", "src", "target")
Act:     recv.receive_command(cmd)
Assert:  recv.command_history.size() == 1
         recv.command_history[0] == cmd
Cleanup: recv.free()
```

### TC-CR-14 — history is capped at max_history
```
Arrange: recv = StubReceiver.new(); recv.auto_register = false
         recv.max_history = 3
Act:     for i in 5: recv.receive_command(GameCommand.create("cmd", "s", "t"))
Assert:  recv.command_history.size() == 3
Cleanup: recv.free()
```

### TC-CR-15 — receive_command with null returns false safely
```
Arrange: recv = StubReceiver.new(); recv.auto_register = false
Act:     result = recv.receive_command(null)
Assert:  result == false
Cleanup: recv.free()
```
