# Test Spec — EventRouter

**Source:** `addons/mkit/kernel/events/event_router.gd`  
**Test file:** `test/unit/kernel/test_event_router.gd`  
**Extends:** `GutTest`

`EventRouter` extends `Node` but has no `_ready` logic that requires the scene
tree, so it can be added with `add_child_autofree` and tested synchronously.

---

## Setup / Teardown

```gdscript
var events: EventRouter

func before_each() -> void:
    events = EventRouter.new()
    add_child_autofree(events)
```

---

## Group: emit_domain_event

### TC-ER-01 — domain_event_emitted signal fires with correct event
```
Arrange: evt = DomainEvent.create("test_event", "src", "tgt", {"key": 1})
         watch_signals(events)
Act:     events.emit_domain_event(evt)
Assert:  assert_signal_emitted(events, "domain_event_emitted")
         assert_signal_emitted_with_parameters(events, "domain_event_emitted", [evt])
```

### TC-ER-02 — recent_events grows with each emission
```
Act:    for i in 3:
            events.emit_domain_event(DomainEvent.create("e", "s", "t", {}))
Assert: events.recent_events.size() == 3
```

### TC-ER-03 — recent_events is capped at max_recent_events
```
Arrange: events.max_recent_events = 5
Act:     for i in 8:
             events.emit_domain_event(DomainEvent.create("e", "s", "t", {}))
Assert:  events.recent_events.size() == 5
```

### TC-ER-04 — oldest event is discarded when buffer is full
```
Arrange: events.max_recent_events = 2
         evt1 = DomainEvent.create("first", "s", "t", {})
         evt2 = DomainEvent.create("second", "s", "t", {})
         evt3 = DomainEvent.create("third", "s", "t", {})
Act:     events.emit_domain_event(evt1)
         events.emit_domain_event(evt2)
         events.emit_domain_event(evt3)
Assert:  events.recent_events[0] == evt2
         events.recent_events[1] == evt3
```

---

## Group: typed emit helpers

### TC-ER-05 — emit_room_cleared fires room_cleared signal with correct id
```
watch_signals(events)
events.emit_room_cleared("room_forest_01")
assert_signal_emitted_with_parameters(events, "room_cleared", ["room_forest_01"])
```

### TC-ER-06 — emit_room_cleared also emits domain_event_emitted
```
watch_signals(events)
events.emit_room_cleared("r01")
assert_signal_emitted(events, "domain_event_emitted")
# The latest domain event has event_type == "room_cleared"
assert_eq(events.recent_events.back().event_type, "room_cleared")
```

### TC-ER-07 — emit_entity_died fires entity_died with id and node ref
```
Arrange: node = Node.new(); add_child_autofree(node)
         watch_signals(events)
Act:     events.emit_entity_died("enemy_01", node)
Assert:  assert_signal_emitted_with_parameters(events, "entity_died", ["enemy_01", node])
```

### TC-ER-08 — emit_inventory_changed fires inventory_changed with owner_id
```
watch_signals(events)
events.emit_inventory_changed("player")
assert_signal_emitted_with_parameters(events, "inventory_changed", ["player"])
```

### TC-ER-09 — emit_run_started fires run_started and records domain event
```
watch_signals(events)
events.emit_run_started("run_001", 42)
assert_signal_emitted_with_parameters(events, "run_started", ["run_001", 42])
var de = events.recent_events.back()
assert_eq(de.event_type, "run_started")
assert_eq(de.data.get("seed"), 42)
```

### TC-ER-10 — emit_run_finished fires run_finished and records result
```
watch_signals(events)
events.emit_run_finished("run_001", "victory")
assert_signal_emitted_with_parameters(events, "run_finished", ["run_001", "victory"])
assert_eq(events.recent_events.back().data.get("result"), "victory")
```

### TC-ER-11 — emit_reward_selected fires reward_selected
```
watch_signals(events)
events.emit_reward_selected("hp_up", "chest_01")
assert_signal_emitted_with_parameters(events, "reward_selected", ["hp_up"])
```

### TC-ER-12 — emit_damage_applied fires damage_applied and creates domain event
```
Arrange: # create a minimal DamageResult stand-in (plain Object is enough)
         class FakeDamageResult:
             var source: Node = null
             var target: Node = null
             func to_debug_dict() -> Dictionary: return {"final": 10.0}
         result = FakeDamageResult.new()
         watch_signals(events)
Act:     events.emit_damage_applied(result)
Assert:  assert_signal_emitted(events, "damage_applied")
         assert_eq(events.recent_events.back().event_type, "damage_applied")
```
