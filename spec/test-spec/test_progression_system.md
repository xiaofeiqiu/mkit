# Test Spec — ProgressionSystem

**Source:** `addons/mkit/modules/progression/progression_system.gd`  
**Test file:** `test/unit/modules/test_progression_system.gd`  
**Extends:** `GutTest`

`ProgressionSystem` extends `Saveable` (a `Node`). It reads
`ServiceRegistry → ContentRegistry` for `UpgradeDefinition` and optionally
`ServiceRegistry → EffectExecutor` to apply upgrade effects.

---

## Helpers

```gdscript
func make_upgrade(
    id: String,
    cost: int = 10,
    currency: String = "gold",
    max_level: int = 3,
    prerequisites: Array[String] = []
) -> UpgradeDefinition:
    var def = UpgradeDefinition.new()
    def.upgrade_id              = id
    def.currency_id             = currency
    def.costs                   = []          # flat cost list; see get_cost_for_level
    # Use a simple flat cost: same cost at every level.
    # Adjust if UpgradeDefinition.get_cost_for_level uses an array index.
    for _l in max_level:
        def.costs.append(cost)
    def.max_level               = max_level
    def.prerequisite_upgrade_ids = prerequisites
    def.unlock_content_ids      = []
    def.effects                 = []
    return def

class StubContent extends ContentRegistry:
    var _defs: Dictionary = {}
    func get_resource(id: String) -> Resource:
        return _defs.get(id)

var progression: ProgressionSystem
var content: StubContent
```

---

## Setup / Teardown

```gdscript
func before_each() -> void:
    content = StubContent.new()
    ServiceRegistry.register_service("content", content)

    progression = ProgressionSystem.new()
    add_child_autofree(progression)
    progression._ready()

func after_each() -> void:
    ServiceRegistry.clear()
```

---

## Group: add_currency / get_currency

### TC-PROG-01 — add_currency increases balance and emits currency_changed
```
watch_signals(progression)
progression.add_currency("gold", 100)
assert_eq(progression.get_currency("gold"), 100)
assert_signal_emitted_with_parameters(progression, "currency_changed", ["gold", 100])
```

### TC-PROG-02 — add_currency accumulates across multiple calls
```
progression.add_currency("gold", 50)
progression.add_currency("gold", 30)
assert_eq(progression.get_currency("gold"), 80)
```

### TC-PROG-03 — add_currency with amount == 0 is a no-op
```
watch_signals(progression)
progression.add_currency("gold", 0)
assert_signal_not_emitted(progression, "currency_changed")
assert_eq(progression.get_currency("gold"), 0)
```

### TC-PROG-04 — add_currency with empty currency_id is ignored
```
progression.add_currency("", 50)
assert_eq(progression.get_currency(""), 0)
```

### TC-PROG-05 — get_currency returns 0 for unknown id
```
assert_eq(progression.get_currency("unknown"), 0)
```

### TC-PROG-06 — add_currency with negative amount reduces balance
```
progression.add_currency("gold", 100)
progression.add_currency("gold", -30)
assert_eq(progression.get_currency("gold"), 70)
```

---

## Group: can_unlock

### TC-PROG-07 — can_unlock returns false when definition is missing
```
result = progression.can_unlock("not_defined")
assert_false(result)
```

### TC-PROG-08 — can_unlock returns false when currency is insufficient
```
content._defs["hp_up"] = make_upgrade("hp_up", 50, "gold")
progression.add_currency("gold", 20)   # not enough
assert_false(progression.can_unlock("hp_up"))
```

### TC-PROG-09 — can_unlock returns true when currency is sufficient and no prerequisites
```
content._defs["hp_up"] = make_upgrade("hp_up", 50, "gold")
progression.add_currency("gold", 50)
assert_true(progression.can_unlock("hp_up"))
```

### TC-PROG-10 — can_unlock returns false when prerequisite upgrade is not yet unlocked
```
content._defs["hp_up2"] = make_upgrade("hp_up2", 50, "gold", 3, ["hp_up"])
content._defs["hp_up"]  = make_upgrade("hp_up",  50, "gold")
progression.add_currency("gold", 500)
# hp_up is level 0 → prerequisite not met
assert_false(progression.can_unlock("hp_up2"))
```

### TC-PROG-11 — can_unlock returns true once prerequisite is unlocked
```
content._defs["hp_up"]  = make_upgrade("hp_up",  10, "gold")
content._defs["hp_up2"] = make_upgrade("hp_up2", 10, "gold", 3, ["hp_up"])
progression.add_currency("gold", 500)
progression.unlock_or_level_up("hp_up")
assert_true(progression.can_unlock("hp_up2"))
```

### TC-PROG-12 — can_unlock returns false when already at max_level
```
content._defs["armor"] = make_upgrade("armor", 10, "gold", 1)
progression.add_currency("gold", 500)
progression.unlock_or_level_up("armor")   # reaches max_level == 1
assert_false(progression.can_unlock("armor"))
```

---

## Group: unlock_or_level_up

### TC-PROG-13 — successful unlock deducts currency and emits signals
```
content._defs["speed_up"] = make_upgrade("speed_up", 30, "gold")
progression.add_currency("gold", 100)
watch_signals(progression)
result = progression.unlock_or_level_up("speed_up")
assert_true(result)
assert_eq(progression.get_currency("gold"), 70)
assert_signal_emitted(progression, "currency_changed")
assert_signal_emitted_with_parameters(progression, "upgrade_level_changed", ["speed_up", 1])
```

### TC-PROG-14 — unlock increments level each call
```
content._defs["atk"] = make_upgrade("atk", 10, "gold", 3)
progression.add_currency("gold", 500)
progression.unlock_or_level_up("atk")
progression.unlock_or_level_up("atk")
assert_eq(progression.state.get_upgrade_level("atk"), 2)
```

### TC-PROG-15 — unlock_or_level_up returns false when can_unlock is false
```
content._defs["rare"] = make_upgrade("rare", 999, "gold")
progression.add_currency("gold", 5)
result = progression.unlock_or_level_up("rare")
assert_false(result)
assert_eq(progression.get_currency("gold"), 5)   # no currency spent
```

### TC-PROG-16 — unlock emits content_unlocked for each unlock_content_id
```
def = make_upgrade("combo_unlock", 10, "gold")
def.unlock_content_ids = ["ability_combo_strike", "ability_combo_finish"]
content._defs["combo_unlock"] = def
progression.add_currency("gold", 100)
watch_signals(progression)
progression.unlock_or_level_up("combo_unlock")
# Two content_unlocked signals expected.
assert_signal_emit_count(progression, "content_unlocked", 2)
```

---

## Group: save / load round-trip

### TC-PROG-17 — to_save_data / from_save_data preserves currency and upgrade levels
```
content._defs["hp_up"] = make_upgrade("hp_up", 10, "gold")
progression.add_currency("gold", 100)
progression.unlock_or_level_up("hp_up")

data = progression.to_save_data()

prog2 = ProgressionSystem.new()
add_child_autofree(prog2)
prog2._ready()
prog2.from_save_data(data)

assert_eq(prog2.get_currency("gold"), progression.get_currency("gold"))
assert_eq(prog2.state.get_upgrade_level("hp_up"), 1)
```
