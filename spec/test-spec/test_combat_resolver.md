# Test Spec — CombatResolver

**Source:** `addons/mkit/modules/combat/combat_resolver.gd`  
**Test file:** `test/unit/modules/test_combat_resolver.gd`  
**Extends:** `GutTest`

`CombatResolver` is a `RefCounted` with a static default instance. Tests
create a fresh instance each run to avoid singleton state bleed. A seeded
`RandomService` stub is injected into `ServiceRegistry` so crit/on-hit rolls
are deterministic.

---

## Helpers

```gdscript
# Minimal entity node with an injectable StatsComponent.
class FakeEntity extends Node:
    var stats_comp: StatsComponent = null
    func _ready() -> void:
        if stats_comp != null:
            var comp_holder = Node.new()
            comp_holder.name = "Components"
            add_child(comp_holder)
            comp_holder.add_child(stats_comp)

# Seeded random that always returns a fixed value.
class FixedRandom extends RandomService:
    var fixed_value: float = 0.0
    func randf() -> float: return fixed_value
    func randi_range(from: int, to: int) -> int: return from
    func randf_range(from: float, to: float) -> float: return fixed_value * (to - from) + from
```

---

## Setup / Teardown

```gdscript
var resolver: CombatResolver
var reg: Node   # local ServiceRegistry instance

func before_each() -> void:
    resolver = CombatResolver.new()
    # inject a fake registry so ServiceRegistry.has_service("random") works
    # (or directly call randf path by not registering random)

func after_each() -> void:
    pass
```

---

## Group: null / missing source or target

### TC-CMBT-01 — resolve with null source returns 0 damage
```
Arrange: req = DamageRequest.new(); req.target = Node.new(); req.base_amount = 50.0
Act:     result = resolver.resolve(req)
Assert:  result.final_amount == 0.0
         result.trace.has("failure")
Cleanup: req.target.free()
```

### TC-CMBT-02 — resolve with null target returns 0 damage
```
Arrange: req = DamageRequest.new(); req.source = Node.new(); req.base_amount = 50.0
Act:     result = resolver.resolve(req)
Assert:  result.final_amount == 0.0
Cleanup: req.source.free()
```

---

## Group: base damage calculation (no stats)

### TC-CMBT-03 — base_amount is the final damage when no stats are present
```
Arrange: src = Node.new(); tgt = Node.new()
         add_child_autofree(src); add_child_autofree(tgt)
         req = DamageRequest.new(); req.source = src; req.target = tgt
         req.base_amount = 30.0; req.can_crit = false
Act:     result = resolver.resolve(req)
Assert:  result.final_amount == 30.0
```

---

## Group: attack_power and damage_multiplier

### TC-CMBT-04 — attack_power is added to base before multiplier
```
Arrange: source entity with StatsComponent:
             attack_power      = 10.0
             damage_multiplier = 1.0
         req.base_amount = 20.0; req.can_crit = false
         target entity with no StatsComponent (defense = 0)
Act:     result = resolver.resolve(req)
Assert:  result.final_amount == 30.0   # (20 + 10) * 1.0 - 0
```

### TC-CMBT-05 — damage_multiplier scales post-attack_power total
```
Arrange: source entity with attack_power = 0, damage_multiplier = 2.0
         req.base_amount = 15.0; req.can_crit = false
         target with defense = 0
Act:     result = resolver.resolve(req)
Assert:  result.final_amount == 30.0   # 15 * 2.0
```

---

## Group: defense

### TC-CMBT-06 — defense reduces final damage
```
Arrange: source has no stats (attack_power = 0, multiplier = 1)
         target has defense = 10
         req.base_amount = 25.0; req.can_crit = false
Act:     result = resolver.resolve(req)
Assert:  result.final_amount == 15.0   # 25 - 10
```

### TC-CMBT-07 — damage cannot go below 0 when defense exceeds total
```
Arrange: target has defense = 100; req.base_amount = 10.0; req.can_crit = false
Act:     result = resolver.resolve(req)
Assert:  result.final_amount == 0.0
```

---

## Group: crit

### TC-CMBT-08 — crit multiplies damage when roll passes
```
Arrange: fixed_random.fixed_value = 0.0   # always passes any crit_chance > 0
         ServiceRegistry.register_service("random", fixed_random)
         source has crit_chance = 0.5, crit_damage = 2.0
         req.base_amount = 20.0; req.can_crit = true; target defense = 0
Act:     result = resolver.resolve(req)
Assert:  result.was_critical == true
         result.final_amount == 40.0   # 20 * 2.0
```

### TC-CMBT-09 — crit does not trigger when can_crit = false
```
Arrange: fixed_random.fixed_value = 0.0
         source has crit_chance = 1.0, crit_damage = 3.0
         req.base_amount = 20.0; req.can_crit = false
Act:     result = resolver.resolve(req)
Assert:  result.was_critical == false
         result.final_amount == 20.0
```

### TC-CMBT-10 — crit does not trigger when roll fails
```
Arrange: fixed_random.fixed_value = 0.99   # misses any chance < 1.0
         source has crit_chance = 0.5
         req.base_amount = 20.0; req.can_crit = true
Act:     result = resolver.resolve(req)
Assert:  result.was_critical == false
```

---

## Group: on-hit status application

### TC-CMBT-11 — on_hit_status with chance 1.0 always applies
```
Arrange: fixed_random.fixed_value = 0.0
         req.on_hit_statuses = [{"status_id": "poison", "chance": 1.0, "stacks": 2, "duration": 5.0}]
         req.can_crit = false; req.base_amount = 10.0; src and tgt valid nodes
Act:     result = resolver.resolve(req)
Assert:  result.applied_status_effects.has("poison")
         result.status_applications[0]["stacks"] == 2
```

### TC-CMBT-12 — on_hit_status with chance 0 never applies
```
Arrange: fixed_random.fixed_value = 0.5
         req.on_hit_statuses = [{"status_id": "freeze", "chance": 0.0}]
Act:     result = resolver.resolve(req)
Assert:  result.applied_status_effects.is_empty()
```

### TC-CMBT-13 — on_hit_status is skipped if was_evaded
```
# Use a subclass that forces evade to demonstrate status-skip behaviour.
class EvadingResolver extends CombatResolver:
    func _calculate_evade(_req: DamageRequest, _src_stats, _tgt_stats) -> bool:
        return true   # always evade

Arrange: evading = EvadingResolver.new()
         fixed_random.fixed_value = 0.0
         ServiceRegistry.register_service("random", fixed_random)
         req = DamageRequest.new()
         req.source       = Node.new(); add_child_autofree(req.source)
         req.target       = Node.new(); add_child_autofree(req.target)
         req.base_amount  = 20.0; req.can_crit = false
         req.on_hit_statuses = [{"status_id": "poison", "chance": 1.0, "stacks": 1, "duration": 3.0}]

Act:     result = evading.resolve(req)

Assert:  result.was_evaded == true
         result.applied_status_effects.is_empty()
```

---

## Group: evade

### TC-CMBT-16 — evade chance of 1.0 always produces was_evaded == true
```
# Source has evade_chance = 1.0 on target StatsComponent.
# fixed_random.fixed_value = 0.0 → roll passes every evade check.
Arrange: fixed_random.fixed_value = 0.0
         ServiceRegistry.register_service("random", fixed_random)
         tgt = FakeEntity.new(); add_child_autofree(tgt)
         tgt.stats_comp = StatsComponent.new()
         tgt.stats_comp.set_base_stat("evade_chance", 1.0)
         req = DamageRequest.new()
         req.source = Node.new(); add_child_autofree(req.source)
         req.target = tgt; req.base_amount = 20.0; req.can_crit = false

Act:     result = resolver.resolve(req)

Assert:  result.was_evaded == true
         result.final_amount == 0.0
```

### TC-CMBT-17 — evade chance of 0.0 never produces was_evaded
```
Arrange: fixed_random.fixed_value = 0.5
         tgt = FakeEntity.new(); add_child_autofree(tgt)
         tgt.stats_comp = StatsComponent.new()
         tgt.stats_comp.set_base_stat("evade_chance", 0.0)
         req = DamageRequest.new()
         req.source = Node.new(); add_child_autofree(req.source)
         req.target = tgt; req.base_amount = 20.0; req.can_crit = false

Act:     result = resolver.resolve(req)

Assert:  result.was_evaded == false
         result.final_amount > 0.0
```

---

## Group: trace dict

### TC-CMBT-14 — resolve populates trace with expected keys
```
Arrange: valid src and tgt; req.base_amount = 10.0; req.can_crit = false
Act:     result = resolver.resolve(req)
Assert:  result.trace.has("base")
         result.trace.has("after_attack_power")
         result.trace.has("after_damage_multiplier")
         result.trace.has("after_crit")
         result.trace.has("after_defense")
```

---

## Group: get_default singleton

### TC-CMBT-15 — get_default returns the same instance on repeated calls
```
r1 = CombatResolver.get_default()
r2 = CombatResolver.get_default()
assert_eq(r1, r2)
```
