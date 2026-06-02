# Test Spec — RoomController

**Source:** `addons/mkit/modules/room/room_controller.gd`  
**Test file:** `test/unit/modules/test_room_controller.gd`  
**Extends:** `GutTest`

`RoomController` extends `Node`. It wires to `ServiceRegistry → ContentRegistry`
and `ServiceRegistry → EventRouter` in `_ready`. Tests that require
`EntitySpawner` and real `PackedScene` spawning are marked **integration only**.
Pure unit tests cover room lifecycle, clear detection, and reward generation with
stub dependencies injected directly.

---

## Helpers

```gdscript
class StubContent extends ContentRegistry:
    var _defs: Dictionary = {}
    func get_resource(id: String) -> Resource:
        return _defs.get(id)

func make_room_def(id: String, enemies: Array[String] = [],
                   pools: Array[String] = []) -> RoomDefinition:
    var d = RoomDefinition.new()
    d.room_definition_id = id
    d.enemy_spawn_ids    = enemies
    d.reward_pool_ids    = pools
    return d

var ctrl: RoomController
var content: StubContent
var events: EventRouter
var entity: Node      # parent entity that holds ctrl
```

---

## Setup / Teardown

```gdscript
func before_each() -> void:
    content = StubContent.new()
    events  = EventRouter.new()
    add_child_autofree(events)
    ServiceRegistry.register_service("content", content)
    ServiceRegistry.register_service("events",  events)

    entity = Node.new(); add_child_autofree(entity)
    ctrl = RoomController.new()
    ctrl.reward_count = 3
    entity.add_child(ctrl)
    ctrl._ready()

func after_each() -> void:
    ServiceRegistry.clear()
```

---

## Group: setup

### TC-RC-01 — setup with valid id creates a RoomRuntime
```
ctrl.setup("forest_01")
assert_not_null(ctrl.runtime)
assert_eq(ctrl.runtime.room_definition_id, "forest_01")
```

### TC-RC-02 — setup with empty id is a no-op (runtime stays null)
```
ctrl.setup("")
assert_null(ctrl.runtime)
```

### TC-RC-03 — calling setup twice replaces the previous runtime
```
ctrl.setup("room_a")
first = ctrl.runtime
ctrl.setup("room_b")
assert_ne(ctrl.runtime, first)
assert_eq(ctrl.runtime.room_definition_id, "room_b")
```

---

## Group: enter_room

### TC-RC-04 — enter_room without prior setup creates runtime from room_definition_id
```
ctrl.room_definition_id = "cave_02"
watch_signals(ctrl)
ctrl.enter_room()
assert_not_null(ctrl.runtime)
assert_true(ctrl.runtime.entered)
assert_signal_emitted(ctrl, "room_entered")
```

### TC-RC-05 — enter_room with null runtime and empty room_definition_id is a no-op
```
# ctrl.runtime == null and room_definition_id == "" (default)
watch_signals(ctrl)
ctrl.enter_room()
assert_signal_not_emitted(ctrl, "room_entered")
```

### TC-RC-06 — enter_room emits room_entered with the room_runtime_id
```
ctrl.setup("lobby")
watch_signals(ctrl)
ctrl.enter_room()
assert_signal_emitted(ctrl, "room_entered")
params = get_signal_parameters(ctrl, "room_entered", 0)
assert_eq(params[0], ctrl.runtime.room_runtime_id)
```

---

## Group: check_clear_condition

### TC-RC-07 — check_clear_condition with no active enemies emits room_cleared
```
ctrl.setup("combat_01")
ctrl.runtime.entered = true
# active_enemies is empty by default
watch_signals(ctrl)
ctrl.check_clear_condition()
assert_true(ctrl.runtime.cleared)
assert_signal_emitted(ctrl, "room_cleared")
```

### TC-RC-08 — check_clear_condition with active enemies does not clear
```
ctrl.setup("combat_01")
ctrl.active_enemies["enemy_001"] = Node.new()
watch_signals(ctrl)
ctrl.check_clear_condition()
assert_false(ctrl.runtime.cleared)
assert_signal_not_emitted(ctrl, "room_cleared")
ctrl.active_enemies["enemy_001"].free()
```

### TC-RC-09 — check_clear_condition when already cleared is a no-op
```
ctrl.setup("combat_01")
ctrl.runtime.cleared = true
watch_signals(ctrl)
ctrl.check_clear_condition()
assert_signal_not_emitted(ctrl, "room_cleared")
```

### TC-RC-10 — check_clear_condition with null runtime is a no-op (no crash)
```
# ctrl.runtime is null by default
ctrl.check_clear_condition()   # must not crash
```

### TC-RC-11 — room_cleared also fires EventRouter.room_cleared
```
ctrl.setup("combat_01")
watch_signals(events)
ctrl.check_clear_condition()
assert_signal_emitted(events, "room_cleared")
```

---

## Group: _on_entity_died (via EventRouter integration)

### TC-RC-12 — entity_died for a tracked enemy removes it and triggers clear check
```
ctrl.setup("combat_01")
fake_enemy = Node.new(); add_child_autofree(fake_enemy)
ctrl.active_enemies["e01"] = fake_enemy
ctrl.runtime.active_enemy_ids.append("e01")
watch_signals(ctrl)
events.emit_entity_died("e01", fake_enemy)
assert_false(ctrl.active_enemies.has("e01"))
assert_true(ctrl.runtime.cleared)
assert_signal_emitted(ctrl, "room_cleared")
```

### TC-RC-13 — entity_died for an untracked entity is ignored
```
ctrl.setup("combat_01")
ctrl.active_enemies["e01"] = Node.new()
events.emit_entity_died("unrelated", Node.new())
assert_true(ctrl.active_enemies.has("e01"))
ctrl.active_enemies["e01"].free()
```

---

## Group: generate_reward

### TC-RC-14 — generate_reward with reward_count == 0 emits reward_ready with empty list
```
ctrl.setup("combat_01")
ctrl.reward_count = 0
watch_signals(ctrl)
ctrl.generate_reward()
assert_signal_emitted(ctrl, "reward_ready")
params = get_signal_parameters(ctrl, "reward_ready", 0)
assert_eq(params[0].size(), 0)
```

### TC-RC-15 — generate_reward with null runtime emits reward_ready with empty list
```
# ctrl.runtime == null
watch_signals(ctrl)
ctrl.generate_reward()
assert_signal_emitted(ctrl, "reward_ready")
params = get_signal_parameters(ctrl, "reward_ready", 0)
assert_eq(params[0].size(), 0)
```

### TC-RC-16 — generate_reward with no reward_pool_ids emits reward_ready with empty list
```
content._defs["empty_room"] = make_room_def("empty_room", [], [])
ctrl.setup("empty_room")
watch_signals(ctrl)
ctrl.generate_reward()
params = get_signal_parameters(ctrl, "reward_ready", 0)
assert_eq(params[0].size(), 0)
```

---

## Group: get_definition

### TC-RC-17 — get_definition returns the matching RoomDefinition from content
```
content._defs["dungeon_a"] = make_room_def("dungeon_a")
ctrl.setup("dungeon_a")
def = ctrl.get_definition()
assert_not_null(def)
assert_eq(def.room_definition_id, "dungeon_a")
```

### TC-RC-18 — get_definition returns null when content service is absent
```
ServiceRegistry.unregister_service("content")
ctrl.setup("dungeon_a")
assert_null(ctrl.get_definition())
```

### TC-RC-19 — get_definition returns null when room_definition_id is empty
```
assert_null(ctrl.get_definition())
```
