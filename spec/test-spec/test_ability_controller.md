# Test Spec — AbilityController

**Source:** `addons/mkit/modules/abilities/ability_controller.gd`  
**Test file:** `test/unit/modules/test_ability_controller.gd`  
**Extends:** `GutTest`

`AbilityController` depends on:
- `ServiceRegistry` → `ContentRegistry` (to fetch `AbilityDefinition`)
- `ServiceRegistry` → `EffectExecutor` (to run effects on cast)
- `ServiceRegistry` → `ActionRunner` (for cast-time abilities)
- `ConditionEvaluator` (static; no service injection needed)

Tests use a stub `ContentRegistry` that returns hand-crafted `AbilityDefinition`
resources. The `ServiceRegistry` autoload is cleared in `after_each`.

---

## Helpers

```gdscript
# Build a no-cost, instant, no-condition ability definition.
func make_ability(id: String, cooldown: float = 0.0) -> AbilityDefinition:
    var def = AbilityDefinition.new()
    def.ability_id    = id
    def.cooldown      = cooldown
    def.cast_time     = 0.0
    def.cost_type     = "none"
    def.cost_amount   = 0.0
    def.conditions    = []
    def.effects       = []
    return def

# ContentRegistry that serves a fixed dictionary of definitions.
class StubContent extends ContentRegistry:
    var _defs: Dictionary = {}
    func get_resource(id: String) -> Resource:
        return _defs.get(id)

var ctrl: AbilityController
var content: StubContent
var entity: Node
var ctx: GameplayContext
```

---

## Setup / Teardown

```gdscript
func before_each() -> void:
    entity  = Node.new(); add_child_autofree(entity)
    content = StubContent.new()
    ServiceRegistry.register_service("content", content)

    ctrl = AbilityController.new()
    ctrl.auto_register = false  # avoid CommandReceiver-style side-effects
    entity.add_child(ctrl)

    ctx = GameplayContext.new()
    ctx.source = entity

func after_each() -> void:
    ServiceRegistry.clear()
```

---

## Group: register_ability

### TC-AB-01 — register_ability returns true and emits ability_registered
```
content._defs["slam"] = make_ability("slam")
watch_signals(ctrl)
result = ctrl.register_ability("slam")
assert_true(result)
assert_true(ctrl.has_ability("slam"))
assert_signal_emitted_with_parameters(ctrl, "ability_registered", ["slam"])
```

### TC-AB-02 — registering the same ability twice is idempotent
```
content._defs["slam"] = make_ability("slam")
ctrl.register_ability("slam")
result = ctrl.register_ability("slam")
assert_true(result)
assert_eq(ctrl.abilities.size(), 1)
```

### TC-AB-03 — register_ability with empty id returns false
```
result = ctrl.register_ability("")
assert_false(result)
```

### TC-AB-04 — register_ability with missing definition returns false
```
result = ctrl.register_ability("undefined_ability")
assert_false(result)
```

---

## Group: can_cast / get_cast_failure_reason

### TC-AB-05 — can_cast returns false for unregistered ability
```
result = ctrl.can_cast("not_registered", ctx)
assert_false(result)
reason = ctrl.get_cast_failure_reason("not_registered", ctx)
assert_true(reason.begins_with("not_registered"))
```

### TC-AB-06 — can_cast returns true for a valid ready ability
```
content._defs["dash"] = make_ability("dash")
ctrl.register_ability("dash")
assert_true(ctrl.can_cast("dash", ctx))
```

### TC-AB-07 — can_cast returns false when ability is on cooldown
```
Arrange: def = make_ability("dash", 2.0)
         content._defs["dash"] = def
         ctrl.register_ability("dash")
         ctrl.cast("dash", ctx)   # starts cooldown
Act:     result = ctrl.can_cast("dash", ctx)
Assert:  result == false
         ctrl.get_cast_failure_reason("dash", ctx).begins_with("on_cooldown")
```

### TC-AB-08 — can_cast returns false when missing context
```
content._defs["dash"] = make_ability("dash")
ctrl.register_ability("dash")
assert_false(ctrl.can_cast("dash", null))
assert_eq(ctrl.get_cast_failure_reason("dash", null), "missing_context")
```

### TC-AB-09 — can_cast returns false when ability is disabled
```
Arrange: def = make_ability("slam"); content._defs["slam"] = def
         ctrl.register_ability("slam")
         (ctrl.abilities["slam"] as AbilityInstance).enabled = false
Act:     result = ctrl.can_cast("slam", ctx)
Assert:  result == false
         ctrl.get_cast_failure_reason("slam", ctx).begins_with("disabled")
```

---

## Group: cast — instant ability (cast_time == 0)

### TC-AB-10 — cast instant ability emits cast_started and cast_finished
```
content._defs["slash"] = make_ability("slash")
ctrl.register_ability("slash")
watch_signals(ctrl)
ctrl.cast("slash", ctx)
assert_signal_emitted(ctrl, "ability_cast_started")
assert_signal_emitted(ctrl, "ability_cast_finished")
```

### TC-AB-11 — cast starts cooldown and emits cooldown_started
```
Arrange: def = make_ability("slash", 1.5); content._defs["slash"] = def
         ctrl.register_ability("slash")
         watch_signals(ctrl)
Act:     ctrl.cast("slash", ctx)
Assert:  assert_signal_emitted(ctrl, "cooldown_started")
         ctrl.is_cooldown_ready("slash") == false
         ctrl.get_cooldown_remaining("slash") > 0.0
```

### TC-AB-12 — cast returns false for unregistered ability and emits ability_failed
```
watch_signals(ctrl)
result = ctrl.cast("unknown", ctx)
assert_false(result)
assert_signal_emitted(ctrl, "ability_failed")
```

### TC-AB-13 — cast returns false with null context and emits ability_failed
```
content._defs["slash"] = make_ability("slash")
ctrl.register_ability("slash")
watch_signals(ctrl)
result = ctrl.cast("slash", null)
assert_false(result)
assert_signal_emitted_with_parameters(ctrl, "ability_failed", ["slash", "missing_context"])
```

---

## Group: cooldown tick

### TC-AB-14 — cooldown_remaining decreases after _process tick
```
Arrange: def = make_ability("dash", 2.0); content._defs["dash"] = def
         ctrl.register_ability("dash")
         ctrl.cast("dash", ctx)
         remaining_before = ctrl.get_cooldown_remaining("dash")
Act:     ctrl._process(0.5)
Assert:  ctrl.get_cooldown_remaining("dash") < remaining_before
```

### TC-AB-15 — ability becomes ready once cooldown expires
```
Arrange: def = make_ability("dash", 0.1); content._defs["dash"] = def
         ctrl.register_ability("dash"); ctrl.cast("dash", ctx)
Act:     ctrl._process(0.2)
Assert:  ctrl.is_cooldown_ready("dash") == true
```

---

## Group: cost checking

### TC-AB-16 — cast fails when entity lacks enough resource for cost
```
Arrange: def = make_ability("fireball")
         def.cost_type = "mana"; def.cost_amount = 30.0
         content._defs["fireball"] = def
         ctrl.register_ability("fireball")
         # entity has no ResourcePoolComponent → cost check fails
         watch_signals(ctrl)
Act:     result = ctrl.cast("fireball", ctx)
Assert:  result == false
         assert_signal_emitted(ctrl, "ability_failed")
```

---

## Group: condition evaluation

### TC-AB-17 — cast fails when an ability condition evaluates to false
```
Arrange:
    class NeverCondition extends Condition:
        func evaluate(_ctx: GameplayContext) -> bool: return false

    def = make_ability("slam"); def.conditions = [NeverCondition.new()]
    content._defs["slam"] = def
    ctrl.register_ability("slam")
    watch_signals(ctrl)

Act:     result = ctrl.cast("slam", ctx)
Assert:  result == false
         assert_signal_emitted(ctrl, "ability_failed")
```

### TC-AB-18 — cast succeeds when all conditions pass
```
Arrange:
    class AlwaysCondition extends Condition:
        func evaluate(_ctx: GameplayContext) -> bool: return true

    def = make_ability("slam"); def.conditions = [AlwaysCondition.new()]
    content._defs["slam"] = def
    ctrl.register_ability("slam")
    watch_signals(ctrl)

Act:     result = ctrl.cast("slam", ctx)
Assert:  result == true
         assert_signal_emitted(ctrl, "ability_cast_finished")
```

---

## Group: channeled cast (cast_time > 0)

### TC-AB-19 — cast with cast_time > 0 emits cast_started but not cast_finished immediately
```
Arrange: def = make_ability("charge"); def.cast_time = 1.0
         content._defs["charge"] = def
         ctrl.register_ability("charge")
         watch_signals(ctrl)

Act:     ctrl.cast("charge", ctx)

Assert:  assert_signal_emitted(ctrl, "ability_cast_started")
         assert_signal_not_emitted(ctrl, "ability_cast_finished")
```

### TC-AB-20 — cast_finished fires after cast_time elapses (_process ticks)
```
Arrange: def = make_ability("charge"); def.cast_time = 0.5
         content._defs["charge"] = def
         ctrl.register_ability("charge")
         ctrl.cast("charge", ctx)
         watch_signals(ctrl)

Act:     ctrl._process(0.6)   # advance past cast_time

Assert:  assert_signal_emitted(ctrl, "ability_cast_finished")
```

### TC-AB-21 — interrupting a channeled cast emits ability_interrupted and suppresses cast_finished
```
Arrange: def = make_ability("charge"); def.cast_time = 2.0
         content._defs["charge"] = def
         ctrl.register_ability("charge")
         ctrl.cast("charge", ctx)
         watch_signals(ctrl)

Act:     ctrl.interrupt_cast("charge")

Assert:  assert_signal_emitted(ctrl, "ability_interrupted")
         assert_signal_not_emitted(ctrl, "ability_cast_finished")
```

---

## Group: unregister_ability

### TC-AB-22 — unregister_ability removes ability from controller
```
Arrange: content._defs["slash"] = make_ability("slash")
         ctrl.register_ability("slash")

Act:     ctrl.unregister_ability("slash")

Assert:  ctrl.has_ability("slash") == false
```

### TC-AB-23 — unregister_ability on non-registered id is a no-op (no crash)
```
ctrl.unregister_ability("ghost_ability")
```
