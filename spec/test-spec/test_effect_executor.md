# Test Spec — EffectExecutor

**Source:** `addons/mkit/kernel/effects/effect_executor.gd`  
**Test file:** `test/unit/kernel/test_effect_executor.gd`  
**Extends:** `GutTest`

`EffectExecutor` is a `RefCounted` — no scene-tree needed.  
Builtin effect scripts (`LogEffect`, `HealEffect`, `DealDamageEffect`, etc.)
are tested here for their `apply()` return values; scene-mutating effects
(`SpawnSceneEffect`) are excluded from pure unit tests.

---

## Helpers

```gdscript
# Effect that always succeeds.
class OkEffect extends GameEffect:
    func apply(_ctx: GameplayContext) -> EffectResult:
        return EffectResult.ok("ok_effect")

# Effect that always fails.
class FailEffect extends GameEffect:
    func apply(_ctx: GameplayContext) -> EffectResult:
        return EffectResult.fail("fail_effect", "forced failure")
```

---

## Setup / Teardown

```gdscript
var executor: EffectExecutor
var ctx: GameplayContext

func before_each() -> void:
    executor = EffectExecutor.new()
    ctx = GameplayContext.new()
```

---

## Group: execute (single)

### TC-EE-01 — execute returns ok result for successful effect
```
Act:    result = executor.execute(OkEffect.new(), ctx)
Assert: result.success == true
        result.effect_id == "ok_effect"
```

### TC-EE-02 — execute returns fail result for failing effect
```
Act:    result = executor.execute(FailEffect.new(), ctx)
Assert: result.success == false
```

### TC-EE-03 — execute with null effect returns fail result (no crash)
```
Act:    result = executor.execute(null, ctx)
Assert: result.success == false
        result.effect_id == "null_effect"
```

### TC-EE-04 — result is recorded in recent_results when trace_enabled
```
executor.trace_enabled = true
executor.execute(OkEffect.new(), ctx)
assert_eq(executor.recent_results.size(), 1)
```

### TC-EE-05 — result is NOT recorded when trace_enabled is false
```
executor.trace_enabled = false
executor.execute(OkEffect.new(), ctx)
assert_eq(executor.recent_results.size(), 0)
```

### TC-EE-06 — recent_results is capped at max_recent_results
```
executor.max_recent_results = 3
for i in 5:
    executor.execute(OkEffect.new(), ctx)
assert_eq(executor.recent_results.size(), 3)
```

---

## Group: execute_many

### TC-EE-07 — execute_many returns one result per effect
```
effects: Array[GameEffect] = [OkEffect.new(), OkEffect.new(), OkEffect.new()]
results = executor.execute_many(effects, ctx)
assert_eq(results.size(), 3)
assert_true(results.all(func(r): return r.success))
```

### TC-EE-08 — execute_many with stop_on_failure halts after first failure
```
effects: Array[GameEffect] = [OkEffect.new(), FailEffect.new(), OkEffect.new()]
results = executor.execute_many(effects, ctx, true)
assert_eq(results.size(), 2)
assert_true(results[0].success)
assert_false(results[1].success)
```

### TC-EE-09 — execute_many without stop_on_failure runs all effects
```
effects: Array[GameEffect] = [OkEffect.new(), FailEffect.new(), OkEffect.new()]
results = executor.execute_many(effects, ctx, false)
assert_eq(results.size(), 3)
```

### TC-EE-10 — execute_many on empty array returns empty result list
```
results = executor.execute_many([], ctx)
assert_eq(results.size(), 0)
```

---

## Group: LogEffect (builtin)

### TC-EE-11 — LogEffect.apply always returns success
```
Arrange: effect = LogEffect.new(); effect.message = "test log"
Act:     result = executor.execute(effect, ctx)
Assert:  result.success == true
```

---

## Group: HealEffect (builtin)

### TC-EE-12 — HealEffect.apply fails gracefully when target has no ResourcePoolComponent
```
Arrange: target = Node.new(); add_child_autofree(target)
         ctx.target = target
         effect = HealEffect.new(); effect.amount = 30.0
Act:     result = executor.execute(effect, ctx)
Assert:  result.success == false   # no ResourcePoolComponent present
```

### TC-EE-13 — HealEffect.apply heals target when ResourcePoolComponent exists
```
Arrange: target = Node.new(); add_child_autofree(target)
         components = Node.new(); components.name = "Components"; target.add_child(components)
         pool = ResourcePoolComponent.new()
         pool.name = "HealthPool"
         pool.resource_id = "health"
         pool.max_value = 100.0
         pool.current_value = 50.0
         components.add_child(pool)   # path: Components/HealthPool
         ctx.target = target
         effect = HealEffect.new(); effect.amount = 20.0; effect.resource_id = "health"
Act:     result = executor.execute(effect, ctx)
Assert:  result.success == true
         pool.current_value == 70.0
```

---

## Group: DealDamageEffect (builtin)

### TC-EE-14 — DealDamageEffect.apply fails when target has no ResourcePoolComponent
```
Arrange: target = Node.new(); add_child_autofree(target)
         ctx.target = target
         effect = DealDamageEffect.new(); effect.amount = 25.0; effect.resource_id = "health"
Act:     result = executor.execute(effect, ctx)
Assert:  result.success == false
```

### TC-EE-15 — DealDamageEffect.apply reduces target resource when component exists
```
Arrange: target = Node.new(); add_child_autofree(target)
         components = Node.new(); components.name = "Components"; target.add_child(components)
         pool = ResourcePoolComponent.new()
         pool.name = "HealthPool"
         pool.resource_id = "health"
         pool.max_value = 100.0
         pool.current_value = 80.0
         components.add_child(pool)
         ctx.target = target
         effect = DealDamageEffect.new(); effect.amount = 30.0; effect.resource_id = "health"
Act:     result = executor.execute(effect, ctx)
Assert:  result.success == true
         pool.current_value == 50.0

```

---

## Group: execute_many — edge cases

### TC-EE-16 — execute_many with a null entry in the array skips it safely
```
effects: Array[GameEffect] = [OkEffect.new(), null, OkEffect.new()]
results = executor.execute_many(effects, ctx)
# null entry should be skipped; expect 2 successful results
assert_eq(results.size(), 2)
assert_true(results.all(func(r): return r.success))
```
