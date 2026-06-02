# Test Spec — StateMachine

**Source:** `addons/mkit/kernel/state_machine/state_machine.gd`  
**Test file:** `test/unit/kernel/test_state_machine.gd`  
**Extends:** `GutTest`

The HFSM is a `Node` that discovers child `State` nodes in `_ready`. Tests
build minimal scene-tree fragments programmatically.

---

## Scene setup helper

```
Entity (Node)
  └── StateMachine (StateMachine)   auto_start = false
        └── root (State)            state_id = "root", initial_child_state_id = "idle"
              ├── idle (State)      state_id = "idle"
              └── combat (State)    state_id = "combat", initial_child_state_id = "attack"
                    └── attack (State)   state_id = "attack"
```

```gdscript
var entity: Node
var sm: StateMachine
var state_idle: State
var state_combat: State
var state_attack: State

func before_each() -> void:
    entity = Node.new(); add_child_autofree(entity)
    sm = StateMachine.new(); sm.auto_start = false; entity.add_child(sm)
    var root = State.new(); root.state_id = "root"; root.initial_child_state_id = "idle"; sm.add_child(root)
    state_idle   = State.new(); state_idle.state_id   = "idle";   root.add_child(state_idle)
    state_combat = State.new(); state_combat.state_id = "combat"; state_combat.initial_child_state_id = "attack"; root.add_child(state_combat)
    state_attack = State.new(); state_attack.state_id = "attack"; state_combat.add_child(state_attack)
    # _ready has already run; call setup manually to mimic it.
    sm._ready()
```

---

## Group: initial state / startup

### TC-SM-01 — current_leaf_state is null before first transition
```
Assert: sm.current_leaf_state == null
        sm.get_current_path() == ""
```

### TC-SM-02 — transition_to sets the correct leaf state
```
Act:    sm.transition_to("root/idle")
Assert: sm.current_leaf_state == state_idle
        sm.get_current_path() == "root/idle"
```

### TC-SM-03 — auto_start + initial_state_path transitions on _ready
```
Arrange: sm2 = StateMachine.new(); sm2.auto_start = true; sm2.initial_state_path = "root/idle"
         # ... attach same state tree ...
         sm2._ready()
Assert:  sm2.get_current_path() == "root/idle"
```

---

## Group: transition_to

### TC-SM-04 — transition to nested state follows initial_child_state_id
```
Act:    sm.transition_to("root/combat")
Assert: sm.current_leaf_state == state_attack
        sm.get_current_path() == "root/combat/attack"
```

### TC-SM-05 — transitioning to current leaf is a no-op (returns true)
```
sm.transition_to("root/idle")
result = sm.transition_to("root/idle")
assert_true(result)
assert_eq(sm.get_current_path(), "root/idle")
```

### TC-SM-06 — transition to unknown path fails and emits transition_failed
```
watch_signals(sm)
result = sm.transition_to("root/does_not_exist")
assert_false(result)
assert_signal_emitted(sm, "transition_failed")
```

### TC-SM-07 — state_changed emits previous and current paths
```
sm.transition_to("root/idle")
watch_signals(sm)
sm.transition_to("root/combat")
assert_signal_emitted(sm, "state_changed")
params = get_signal_parameters(sm, "state_changed", 0)
assert_eq(params[0], "root/idle")      # previous
assert_eq(params[1], "root/combat/attack")  # current
```

### TC-SM-08 — previous_path is updated after transition
```
sm.transition_to("root/idle")
sm.transition_to("root/combat")
assert_eq(sm.previous_path, "root/idle")
```

---

## Group: can_exit / can_enter guards

### TC-SM-09 — transition is blocked when can_exit returns false
```
Arrange:
    # Override idle state to refuse exit.
    class LockedState extends State:
        func can_exit(_ctx: Dictionary) -> bool: return false

    locked = LockedState.new(); locked.state_id = "locked"
    sm.root_state.add_child(locked)
    sm.transition_to("root/locked")
    watch_signals(sm)

Act:    result = sm.transition_to("root/idle")
Assert: result == false
        sm.get_current_path() == "root/locked"
        assert_signal_emitted(sm, "transition_failed")
```

### TC-SM-10 — transition is blocked when can_enter returns false
```
Arrange:
    class GuardedState extends State:
        func can_enter(_ctx: Dictionary) -> bool: return false

    guarded = GuardedState.new(); guarded.state_id = "guarded"
    sm.root_state.add_child(guarded)
    sm.transition_to("root/idle")
    watch_signals(sm)

Act:    result = sm.transition_to("root/guarded")
Assert: result == false
        sm.get_current_path() == "root/idle"
```

---

## Group: handle_command

### TC-SM-11 — handle_command returns false when no active state
```
cmd = GameCommand.create("attack", "input", "e")
result = sm.handle_command(cmd)
assert_false(result)
```

### TC-SM-12 — handle_command delegates to current state chain
```
Arrange:
    class CommandHandlerState extends State:
        var received: GameCommand = null
        func handle_command(cmd: GameCommand) -> bool:
            received = cmd; return true

    handler = CommandHandlerState.new(); handler.state_id = "handler"
    sm.root_state.add_child(handler)
    sm.transition_to("root/handler")

Act:    cmd = GameCommand.create("dash", "src", "handler")
        result = sm.handle_command(cmd)
Assert: result == true
        handler.received == cmd
```

### TC-SM-13 — unhandled command bubbles up to parent state
```
Arrange: # child does not handle; parent does
         class ParentHandlerState extends State:
             var handled: bool = false
             func handle_command(cmd: GameCommand) -> bool:
                 handled = true; return true

         parent_state = ParentHandlerState.new(); parent_state.state_id = "parent"
         parent_state.initial_child_state_id = "child"
         child_state  = State.new(); child_state.state_id = "child"
         sm.root_state.add_child(parent_state)
         parent_state.add_child(child_state)
         sm.transition_to("root/parent")

Act:    sm.handle_command(GameCommand.create("cmd", "s", "t"))
Assert: parent_state.handled == true
```

---

## Group: find_state_by_path

### TC-SM-14 — find_state_by_path returns correct node for valid path
```
sm.transition_to("root/idle")   # ensures setup ran
result = sm.find_state_by_path("root/idle")
assert_eq(result, state_idle)
```

### TC-SM-15 — find_state_by_path returns null for invalid path
```
result = sm.find_state_by_path("root/ghost")
assert_null(result)
```

---

## Group: enter / exit callbacks

### TC-SM-16 — entering a state calls on_enter with correct context
```
Arrange:
    class TrackingState extends State:
        var entered: bool = false
        var enter_from: String = ""
        func on_enter(from_path: String, _ctx: Dictionary) -> void:
            entered = true; enter_from = from_path

    tracker = TrackingState.new(); tracker.state_id = "tracker"
    sm.root_state.add_child(tracker)
    sm.transition_to("root/idle")

Act:    sm.transition_to("root/tracker")
Assert: tracker.entered == true
        tracker.enter_from == "root/idle"
```

### TC-SM-17 — exiting a state calls on_exit
```
Arrange:
    class TrackingState extends State:
        var exited: bool = false
        func on_exit(_to_path: String, _ctx: Dictionary) -> void:
            exited = true

    tracker = TrackingState.new(); tracker.state_id = "tracker"
    sm.root_state.add_child(tracker)
    sm.transition_to("root/tracker")

Act:    sm.transition_to("root/idle")
Assert: tracker.exited == true
```

### TC-SM-18 — on_exit is called before on_enter during a transition
```
Arrange:
    var call_order: Array[String] = []

    class ExitState extends State:
        var order: Array
        func on_exit(_to: String, _ctx: Dictionary) -> void:
            order.append("exit")

    class EnterState extends State:
        var order: Array
        func on_enter(_from: String, _ctx: Dictionary) -> void:
            order.append("enter")

    s_exit  = ExitState.new();  s_exit.state_id  = "s_exit";  s_exit.order  = call_order
    s_enter = EnterState.new(); s_enter.state_id = "s_enter"; s_enter.order = call_order
    sm.root_state.add_child(s_exit)
    sm.root_state.add_child(s_enter)
    sm.transition_to("root/s_exit")

Act:    sm.transition_to("root/s_enter")
Assert: call_order == ["exit", "enter"]
```
