# Test Spec — RewardSystem

**Source:** `addons/mkit/modules/loot/reward_system.gd`  
**Test file:** `test/unit/modules/test_reward_system.gd`  
**Extends:** `GutTest`

`RewardSystem` is a `RefCounted`. It reads `ServiceRegistry → ContentRegistry`
for `RewardDefinition` and optionally `ServiceRegistry → RandomService` for
weighted picks. A seeded `FixedRandom` stub is injected for determinism.

---

## Helpers

```gdscript
class StubContent extends ContentRegistry:
    var _defs: Dictionary = {}
    func get_resource(id: String) -> Resource:
        return _defs.get(id)

class FixedRandom extends RandomService:
    var fixed: float = 0.0
    func randf() -> float: return fixed
    func randf_range(from: float, to: float) -> float:
        return from + fixed * (to - from)
    func randi_range(from: int, to: int) -> int: return from

func make_reward_def(id: String, weight: float = 1.0) -> RewardDefinition:
    var d = RewardDefinition.new()
    d.reward_id    = id
    d.display_name = id
    d.description  = ""
    d.weight       = weight
    d.rarity       = "common"
    d.conditions   = []
    d.effects      = []
    return d

var system: RewardSystem
var content: StubContent
var rng: FixedRandom
var ctx: GameplayContext
```

---

## Setup / Teardown

```gdscript
func before_each() -> void:
    system  = RewardSystem.new()
    content = StubContent.new()
    rng     = FixedRandom.new()
    ctx     = GameplayContext.new()
    ServiceRegistry.register_service("content", content)
    ServiceRegistry.register_service("random",  rng)

func after_each() -> void:
    ServiceRegistry.clear()
```

---

## Group: generate_options — guard clauses

### TC-RWD-01 — count <= 0 returns empty list
```
content._defs["gold_bag"] = make_reward_def("gold_bag")
result = system.generate_options(["gold_bag"], 0, ctx)
assert_eq(result.size(), 0)
```

### TC-RWD-02 — empty pool_ids returns empty list
```
result = system.generate_options([], 3, ctx)
assert_eq(result.size(), 0)
```

### TC-RWD-03 — missing ContentRegistry service returns empty list
```
ServiceRegistry.unregister_service("content")
result = system.generate_options(["any_pool"], 3, ctx)
assert_eq(result.size(), 0)
```

### TC-RWD-04 — unknown pool id (not in ContentRegistry) produces no candidates
```
# "mystery_pool" not in content._defs → zero candidates
result = system.generate_options(["mystery_pool"], 3, ctx)
assert_eq(result.size(), 0)
```

### TC-RWD-05 — empty-string entries in pool_ids are skipped safely
```
content._defs["sword_pool"] = make_reward_def("sword_pool")
result = system.generate_options(["", "sword_pool", ""], 1, ctx)
assert_eq(result.size(), 1)
assert_eq(result[0].reward_id, "sword_pool")
```

---

## Group: generate_options — selection logic

### TC-RWD-06 — returns up to `count` options (fewer candidates than count)
```
content._defs["r1"] = make_reward_def("r1")
content._defs["r2"] = make_reward_def("r2")
result = system.generate_options(["r1", "r2"], 5, ctx)
assert_eq(result.size(), 2)   # only 2 candidates exist
```

### TC-RWD-07 — returns exactly `count` options when enough candidates exist
```
for i in 4:
    content._defs["r%d" % i] = make_reward_def("r%d" % i)
result = system.generate_options(content._defs.keys(), 3, ctx)
assert_eq(result.size(), 3)
```

### TC-RWD-08 — no duplicate reward in the same options list
```
content._defs["gem"] = make_reward_def("gem")
content._defs["rune"] = make_reward_def("rune")
result = system.generate_options(["gem", "rune"], 2, ctx)
ids: Array[String] = result.map(func(o): return o.reward_id)
assert_eq(ids.size(), ids.distinct().size())
```

### TC-RWD-09 — heavier candidate wins weighted pick (rng skewed high)
```
# stone weight=1, gold weight=99; fixed=0.99 → gold wins
rng.fixed = 0.99
content._defs["stone"] = make_reward_def("stone", 1.0)
content._defs["gold"]  = make_reward_def("gold",  99.0)
result = system.generate_options(["stone", "gold"], 1, ctx)
assert_eq(result[0].reward_id, "gold")
```

### TC-RWD-10 — lighter candidate wins when rng skews low
```
rng.fixed = 0.0
content._defs["stone"] = make_reward_def("stone", 1.0)
content._defs["gold"]  = make_reward_def("gold",  99.0)
result = system.generate_options(["stone", "gold"], 1, ctx)
assert_eq(result[0].reward_id, "stone")
```

---

## Group: generate_options — condition filtering

### TC-RWD-11 — entry whose conditions fail is excluded from candidates
```
class NeverCondition extends Condition:
    func evaluate(_ctx: GameplayContext) -> bool: return false

bad = make_reward_def("bad_reward")
bad.conditions = [NeverCondition.new()]
content._defs["bad_reward"]  = bad
content._defs["good_reward"] = make_reward_def("good_reward")

rng.fixed = 0.0
result = system.generate_options(["bad_reward", "good_reward"], 2, ctx)
ids = result.map(func(o): return o.reward_id)
assert_false(ids.has("bad_reward"))
assert_true(ids.has("good_reward"))
```

### TC-RWD-12 — null context falls back to a fresh GameplayContext (no crash)
```
content._defs["gem"] = make_reward_def("gem")
result = system.generate_options(["gem"], 1, null)
assert_eq(result.size(), 1)
```

---

## Group: apply_selected

### TC-RWD-13 — null option returns false
```
result = system.apply_selected(null, ctx)
assert_false(result)
```

### TC-RWD-14 — option with no effects returns true and emits reward_selected via EventRouter
```
events = EventRouter.new(); add_child_autofree(events)
ServiceRegistry.register_service("events", events)
watch_signals(events)

option = RewardOption.new()
option.reward_id = "speed_up"
option.effects   = []

result = system.apply_selected(option, ctx)
assert_true(result)
assert_signal_emitted_with_parameters(events, "reward_selected", ["speed_up"])
```

### TC-RWD-15 — option with a failing effect returns false
```
class FailEffect extends GameEffect:
    func apply(_ctx: GameplayContext) -> EffectResult:
        return EffectResult.fail("fe", "forced")

option = RewardOption.new()
option.reward_id = "broken"
option.effects   = [FailEffect.new()]

result = system.apply_selected(option, ctx)
assert_false(result)
```

### TC-RWD-16 — apply_selected with null context falls back gracefully (no crash)
```
option = RewardOption.new()
option.reward_id = "safe"
option.effects   = []
result = system.apply_selected(option, null)
assert_true(result)
```
