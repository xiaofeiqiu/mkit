# Test Spec — LootSystem

**Source:** `addons/mkit/modules/loot/loot_system.gd`  
**Test file:** `test/unit/modules/test_loot_system.gd`  
**Extends:** `GutTest`

`LootSystem` is a `RefCounted`. It reads from `ServiceRegistry → ContentRegistry`
and optionally `ServiceRegistry → RandomService`. A seeded stub is injected to
make weight rolls deterministic.

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

func make_entry(content_id: String, weight: float, min_q: int = 1, max_q: int = 1) -> LootEntry:
    var e = LootEntry.new()
    e.content_id   = content_id
    e.weight       = weight
    e.min_quantity = min_q
    e.max_quantity = max_q
    e.conditions   = []
    return e

func make_table(entries: Array, rolls: int = 1, allow_empty: bool = false, empty_weight: float = 0.0) -> LootTableDefinition:
    var t = LootTableDefinition.new()
    t.entries      = entries
    t.rolls        = rolls
    t.allow_empty  = allow_empty
    t.empty_weight = empty_weight
    return t
```

---

## Setup / Teardown

```gdscript
var loot: LootSystem
var content: StubContent
var rng: FixedRandom
var ctx: GameplayContext

func before_each() -> void:
    loot    = LootSystem.new()
    content = StubContent.new()
    rng     = FixedRandom.new()
    ctx     = GameplayContext.new()
    ServiceRegistry.register_service("content", content)
    ServiceRegistry.register_service("random", rng)

func after_each() -> void:
    ServiceRegistry.clear()
```

---

## Group: roll (direct table object)

### TC-LOOT-01 — roll on an empty table returns empty result
```
table = make_table([], 1)
result = loot.roll(table, ctx)
assert_eq(result.item_instances.size(), 0)
```

### TC-LOOT-02 — roll with rolls == 0 returns empty result
```
table = make_table([make_entry("coin", 1.0)], 0)
result = loot.roll(table, ctx)
assert_eq(result.item_instances.size(), 0)
```

### TC-LOOT-03 — single-entry table always returns that entry (fixed rng)
```
rng.fixed = 0.0   # always picks first / lowest-bucket item
table = make_table([make_entry("gem", 1.0)], 1)
result = loot.roll(table, ctx)
assert_eq(result.item_instances.size(), 1)
assert_eq(result.item_instances[0].definition_id, "gem")
```

### TC-LOOT-04 — roll result contains one item per roll (n rolls = n items max)
```
table = make_table([make_entry("coin", 1.0)], 3)
result = loot.roll(table, ctx)
assert_eq(result.item_instances.size(), 3)
```

### TC-LOOT-05 — allow_empty: roll lands in empty bucket → no item for that roll
```
rng.fixed = 0.0   # with allow_empty, r < empty_weight → empty
table = make_table([make_entry("gem", 10.0)], 1, true, 100.0)
# total_weight = 110; fixed r = 0.0 * 110 = 0, which is < empty_weight (100)
result = loot.roll(table, ctx)
assert_eq(result.item_instances.size(), 0)
assert_eq(result.debug_rolls[0]["result"], "empty")
```

### TC-LOOT-06 — weighted roll picks heavier entry when rng skews high
```
# Two entries: "stone" weight=1, "gold" weight=99; total=100
# fixed=0.99 → r = 99; stone bucket ends at 1, gold ends at 100 → gold wins
rng.fixed = 0.99
table = make_table([make_entry("stone", 1.0), make_entry("gold", 99.0)], 1)
result = loot.roll(table, ctx)
assert_eq(result.item_instances[0].definition_id, "gold")
```

### TC-LOOT-07 — quantity is rolled between min and max
```
# FixedRandom.randi_range always returns from (=min_quantity)
table = make_table([make_entry("arrow", 1.0, 3, 7)], 1)
result = loot.roll(table, ctx)
assert_eq(result.item_instances[0].quantity, 3)   # min value
```

---

## Group: roll_table (via ContentRegistry)

### TC-LOOT-08 — roll_table with missing service returns empty result
```
ServiceRegistry.unregister_service("content")
result = loot.roll_table("goblin_drops", ctx)
assert_eq(result.item_instances.size(), 0)
```

### TC-LOOT-09 — roll_table with unknown table id returns empty result
```
result = loot.roll_table("no_such_table", ctx)
assert_eq(result.item_instances.size(), 0)
```

### TC-LOOT-10 — roll_table with valid table produces expected output
```
table = make_table([make_entry("potion", 1.0)], 1)
content._defs["chest_loot"] = table
result = loot.roll_table("chest_loot", ctx)
assert_eq(result.item_instances.size(), 1)
assert_eq(result.item_instances[0].definition_id, "potion")
```

### TC-LOOT-11 — roll_table with empty id returns empty result
```
result = loot.roll_table("", ctx)
assert_eq(result.item_instances.size(), 0)
```

---

## Group: condition filtering

### TC-LOOT-12 — entries whose conditions fail are excluded from candidates
```
Arrange: # condition that always returns false
         class NeverCondition extends Condition:
             func evaluate(_ctx: GameplayContext) -> bool: return false

         e1 = make_entry("gem",  1.0); e1.conditions = [NeverCondition.new()]
         e2 = make_entry("coin", 1.0)
         rng.fixed = 0.0
         table = make_table([e1, e2], 1)
Act:     result = loot.roll(table, ctx)
Assert:  result.item_instances[0].definition_id == "coin"
```

---

## Group: debug_rolls

### TC-LOOT-13 — debug_rolls has one entry per roll
```
table = make_table([make_entry("gem", 1.0)], 3)
result = loot.roll(table, ctx)
assert_eq(result.debug_rolls.size(), 3)
```
