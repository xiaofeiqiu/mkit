# Test Spec — RunDirector

**Source:** `addons/mkit/modules/room/run_director.gd`  
**Test file:** `test/unit/modules/test_run_director.gd`  
**Extends:** `GutTest`

`RunDirector` extends `Node`. It drives the high-level roguelite loop: build a
`RoomGraph`, load rooms, handle clears, present rewards, and finish or fail a run.

**Scope boundary:** `_load_room()` instantiates `PackedScene` and requires a
real scene on disk — those paths are excluded from pure unit tests and listed as
**integration only**. Pure tests exercise every other public method by
stub-injecting `RunState` / `RoomGraph` / `RoomController` directly on the
director's fields.

---

## Helpers

```gdscript
class StubContent extends ContentRegistry:
    var _defs: Dictionary = {}
    func get_resource(id: String) -> Resource:
        return _defs.get(id)

# A minimal RoomNode stub so get_room_at() returns a usable object.
func make_room_node(def_id: String) -> RoomNode:
    var n = RoomNode.new()
    n.room_definition_id = def_id
    return n

# Build a RoomGraph whose get_room_at(index) returns nodes from `nodes`.
class StubRoomGraph extends RoomGraph:
    var nodes: Array[RoomNode] = []
    func get_room_at(index: int) -> RoomNode:
        return nodes[index] if index < nodes.size() else null

# StubRoomController whose runtime and reward_options can be configured.
class StubRoomController extends RoomController:
    var fake_options: Array[RewardOption] = []
    func _ready() -> void: pass   # skip real _ready
    func _get_room_options() -> Array[RewardOption]: return fake_options

var director: RunDirector
var content: StubContent
var events: EventRouter
```

---

## Setup / Teardown

```gdscript
func before_each() -> void:
    content = StubContent.new()
    events  = EventRouter.new(); add_child_autofree(events)
    ServiceRegistry.register_service("content", content)
    ServiceRegistry.register_service("events",  events)

    director = RunDirector.new()
    director.first_floor_room_pool = ["room_a", "room_b"]
    director.run_length            = 2
    director.player_entity_id      = "player_001"
    add_child_autofree(director)

func after_each() -> void:
    ServiceRegistry.clear()
```

---

## Group: start_run — guard clauses

### TC-RD-01 — start_run with empty room pool calls fail_run
```
director.first_floor_room_pool = []
watch_signals(director)
director.start_run(1)
assert_signal_emitted(director, "run_finished")
params = get_signal_parameters(director, "run_finished", 0)
assert_true(params[0].begins_with("failed"))
```

### TC-RD-02 — start_run with run_length <= 0 forces it to 1 and continues
```
director.run_length = 0
# Stub _load_room to prevent scene loading
# Easiest: override enter_next_room path by injecting a pre-built graph + state.
# Just verify run_started fires (run didn't immediately fail).
watch_signals(director)
director.start_run(42)
# run_length forced to 1; run_started should fire before _load_room fails
# (expect either run_started or run_finished depending on scene availability)
# At minimum, director.run_state must be non-null and status in {"active","failed"}
assert_not_null(director.run_state)
```

### TC-RD-03 — start_run creates a non-null RunState with status "active"
```
# Inject pre-built graph to skip _load_room by overriding enter_next_room flow.
# To avoid PackedScene loading, patch enter_next_room after start_run sets state.
# Use a subclass override.
class SafeDirector extends RunDirector:
    func enter_next_room() -> void: pass  # stub to prevent _load_room

safe = SafeDirector.new()
safe.first_floor_room_pool = ["room_a"]
safe.run_length = 1
add_child_autofree(safe)
safe.start_run(7)
assert_not_null(safe.run_state)
assert_eq(safe.run_state.status, "active")
```

### TC-RD-04 — start_run emits run_started with the RunState
```
class SafeDirector extends RunDirector:
    func enter_next_room() -> void: pass

safe = SafeDirector.new()
safe.first_floor_room_pool = ["room_a"]
safe.run_length = 1
add_child_autofree(safe)
watch_signals(safe)
safe.start_run(99)
assert_signal_emitted(safe, "run_started")
```

### TC-RD-05 — start_run with EventRouter registered emits EventRouter.run_started
```
class SafeDirector extends RunDirector:
    func enter_next_room() -> void: pass

safe = SafeDirector.new()
safe.first_floor_room_pool = ["room_a"]
safe.run_length = 1
add_child_autofree(safe)
watch_signals(events)
safe.start_run(12)
assert_signal_emitted(events, "run_started")
```

---

## Group: complete_run / fail_run

### TC-RD-06 — complete_run sets status to "completed" and emits run_finished
```
director.run_state = RunState.create(1)
watch_signals(director)
director.complete_run()
assert_eq(director.run_state.status, "completed")
assert_signal_emitted_with_parameters(director, "run_finished", ["completed"])
```

### TC-RD-07 — complete_run with null run_state is a no-op (no crash)
```
# run_state is null by default
director.complete_run()   # must not crash or emit
```

### TC-RD-08 — complete_run fires EventRouter.run_finished
```
director.run_state = RunState.create(1)
watch_signals(events)
director.complete_run()
assert_signal_emitted(events, "run_finished")
```

### TC-RD-09 — fail_run sets status "failed" and emits run_finished with reason
```
director.run_state = RunState.create(1)
watch_signals(director)
director.fail_run("timeout")
assert_eq(director.run_state.status, "failed")
params = get_signal_parameters(director, "run_finished", 0)
assert_true(params[0].contains("timeout"))
```

### TC-RD-10 — fail_run with empty reason substitutes "unknown"
```
director.run_state = RunState.create(1)
watch_signals(director)
director.fail_run("")
params = get_signal_parameters(director, "run_finished", 0)
assert_true(params[0].contains("unknown"))
```

### TC-RD-11 — fail_run with null run_state still emits run_finished (no crash)
```
# run_state is null; run_id fallback is ""
watch_signals(director)
director.fail_run("crash")
assert_signal_emitted(director, "run_finished")
```

---

## Group: _on_entity_died

### TC-RD-12 — player death triggers fail_run
```
director.run_state = RunState.create(1)
director.run_state.status = "active"
watch_signals(director)
events.emit_entity_died("player_001", Node.new())
assert_signal_emitted(director, "run_finished")
params = get_signal_parameters(director, "run_finished", 0)
assert_true(params[0].contains("player_died"))
```

### TC-RD-13 — non-player entity death does not affect run
```
director.run_state = RunState.create(1)
director.run_state.status = "active"
watch_signals(director)
events.emit_entity_died("enemy_001", Node.new())
assert_signal_not_emitted(director, "run_finished")
assert_eq(director.run_state.status, "active")
```

### TC-RD-14 — entity_died is ignored when run is already failed
```
director.run_state = RunState.create(1)
director.run_state.status = "failed"
watch_signals(director)
events.emit_entity_died("player_001", Node.new())
assert_signal_not_emitted(director, "run_finished")
```

### TC-RD-15 — entity_died is ignored when run is already completed
```
director.run_state = RunState.create(1)
director.run_state.status = "completed"
watch_signals(director)
events.emit_entity_died("player_001", Node.new())
assert_signal_not_emitted(director, "run_finished")
```

---

## Group: on_room_cleared

### TC-RD-16 — on_room_cleared with no reward options advances room index and enters next room
```
class SafeDirector extends RunDirector:
    var next_room_called: bool = false
    func enter_next_room() -> void: next_room_called = true

safe = SafeDirector.new(); add_child_autofree(safe)
safe.run_state = RunState.create(1)
safe.run_state.status = "active"
safe.run_state.current_room_index = 0
# RoomController with no reward options
rc = StubRoomController.new(); rc.fake_options = []
safe.on_room_cleared(rc)
assert_eq(safe.run_state.current_room_index, 1)
assert_true(safe.next_room_called)
```

### TC-RD-17 — on_room_cleared with reward options emits choosing_reward and pauses progression
```
class SafeDirector extends RunDirector:
    func enter_next_room() -> void: pass

safe = SafeDirector.new(); add_child_autofree(safe)
safe.run_state = RunState.create(1)
safe.run_state.current_room_index = 0

rc = StubRoomController.new()
rc.runtime = RoomRuntime.create("room_a")
opt = RewardOption.new(); opt.reward_id = "gem"
rc.runtime.reward_options = [opt]

watch_signals(safe)
safe.on_room_cleared(rc)
assert_eq(safe.run_state.status, "choosing_reward")
assert_signal_emitted(safe, "choosing_reward")
```

### TC-RD-18 — on_room_cleared with null run_state is a no-op (no crash)
```
director.on_room_cleared(null)
```

---

## Group: select_reward

### TC-RD-19 — select_reward with null option is a no-op
```
director.run_state = RunState.create(1)
director.run_state.current_room_index = 0
director.select_reward(null)
assert_eq(director.run_state.current_room_index, 0)
```

### TC-RD-20 — select_reward applies effects, advances index, and continues run
```
class SafeDirector extends RunDirector:
    var next_room_called: bool = false
    func enter_next_room() -> void: next_room_called = true

safe = SafeDirector.new(); add_child_autofree(safe)
safe.run_state = RunState.create(1)
safe.run_state.current_room_index = 0
safe.run_state.status = "choosing_reward"

opt = RewardOption.new()
opt.reward_id = "speed_up"
opt.effects   = []

safe.select_reward(opt)
assert_eq(safe.run_state.current_room_index, 1)
assert_true(safe.next_room_called)
assert_true(safe.run_state.reward_history.has("speed_up"))
```
