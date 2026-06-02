# Test Spec — ActionRunner

**Source:** `addons/mkit/kernel/actions/action_runner.gd`  
**Test file:** `test/unit/kernel/test_action_runner.gd`  
**Extends:** `GutTest`

`ActionRunner` uses `_process` and optionally `TimeService`. Tests call
`_process(delta)` manually to drive the update loop without waiting for frames.

---

## Helpers

```gdscript
# Action that finishes immediately on the first update tick.
class InstantAction extends GameAction:
    func start(_ctx: ActionContext) -> void:
        _finish()

# Action that requires manual external cancel.
class NeverEndingAction extends GameAction:
    func start(_ctx: ActionContext) -> void:
        pass  # stays active until cancelled
```

---

## Setup / Teardown

```gdscript
var runner: ActionRunner

func before_each() -> void:
    runner = ActionRunner.new()
    add_child_autofree(runner)
    # Do NOT register a TimeService so delta passes through unscaled.

func after_each() -> void:
    pass  # autofree handles runner
```

---

## Group: start_action

### TC-AR-01 — start_action returns the action and emits action_started
```
Arrange: action = InstantAction.new()
         ctx    = ActionContext.new()
         watch_signals(runner)
Act:     result = runner.start_action(action, ctx)
Assert:  result == action
         assert_signal_emitted(runner, "action_started")
```

### TC-AR-02 — start_action with null action returns null safely
```
Act:    result = runner.start_action(null, ActionContext.new())
Assert: result == null
```

### TC-AR-03 — start_action with null context returns null safely
```
Act:    result = runner.start_action(InstantAction.new(), null)
Assert: result == null
```

### TC-AR-04 — started action appears in active_actions
```
Arrange: action = NeverEndingAction.new()
Act:     runner.start_action(action, ActionContext.new())
Assert:  runner.active_actions.has(action)
```

---

## Group: action lifecycle — completion

### TC-AR-05 — finished action is removed from active_actions after _process
```
Arrange: action = InstantAction.new(); ctx = ActionContext.new()
         runner.start_action(action, ctx)
Act:     runner._process(0.016)
Assert:  runner.active_actions.has(action) == false
```

### TC-AR-06 — action_completed signal fires when action finishes
```
Arrange: action = InstantAction.new()
         runner.start_action(action, ActionContext.new())
         watch_signals(runner)
Act:     runner._process(0.016)
Assert:  assert_signal_emitted(runner, "action_completed")
```

---

## Group: action lifecycle — cancellation

### TC-AR-07 — cancel_actions_for_source cancels matching actions
```
Arrange: source = Node.new(); add_child_autofree(source)
         action = NeverEndingAction.new()
         ctx    = ActionContext.new(); ctx.source = source
         runner.start_action(action, ctx)
         watch_signals(runner)
Act:     runner.cancel_actions_for_source(source, "test")
         runner._process(0.016)
Assert:  assert_signal_emitted(runner, "action_cancelled")
         runner.active_actions.has(action) == false
```

### TC-AR-08 — cancel_actions_for_source ignores actions from other sources
```
Arrange: src_a = Node.new(); src_b = Node.new()
         add_child_autofree(src_a); add_child_autofree(src_b)
         action = NeverEndingAction.new()
         ctx    = ActionContext.new(); ctx.source = src_a
         runner.start_action(action, ctx)
Act:     runner.cancel_actions_for_source(src_b, "irrelevant")
Assert:  runner.active_actions.has(action) == true
```

### TC-AR-09 — cancel_actions_for_source with null source is safe
```
Act:    runner.cancel_actions_for_source(null)
Assert: (no crash)
```

---

## Group: multiple concurrent actions

### TC-AR-10 — multiple actions can run in parallel
```
Arrange: a1 = NeverEndingAction.new(); a2 = NeverEndingAction.new()
         runner.start_action(a1, ActionContext.new())
         runner.start_action(a2, ActionContext.new())
Assert:  runner.active_actions.size() == 2
```

### TC-AR-11 — starting the same action instance twice does not double-connect signals
```
Arrange: action = NeverEndingAction.new()
         runner.start_action(action, ActionContext.new())
         runner.start_action(action, ActionContext.new())   # second start
Assert:  runner.active_actions.size() == 2   # duplicated in list (expected)
         action.completed.get_connections().size() == 1  # signal not double-connected
```
