# Test Spec — InventoryController

**Source:** `addons/mkit/modules/inventory/inventory_controller.gd`  
**Test file:** `test/unit/modules/test_inventory_controller.gd`  
**Extends:** `GutTest`

`InventoryController` uses `ServiceRegistry → ContentRegistry` to fetch
`ItemDefinition`. Tests inject a stub `ContentRegistry` so no real resources
are loaded from disk.

---

## Helpers

```gdscript
func make_item_def(id: String, stackable: bool = false, max_stack: int = 1) -> ItemDefinition:
    var def = ItemDefinition.new()
    def.item_id   = id
    def.stackable  = stackable
    def.max_stack  = max_stack
    return def

class StubContent extends ContentRegistry:
    var _defs: Dictionary = {}
    func get_resource(id: String) -> Resource:
        return _defs.get(id)

var inv: InventoryController
var content: StubContent
var entity: Node
```

---

## Setup / Teardown

```gdscript
func before_each() -> void:
    content = StubContent.new()
    ServiceRegistry.register_service("content", content)

    entity = Node.new(); add_child_autofree(entity)
    inv = InventoryController.new()
    inv.capacity = 5
    entity.add_child(inv)
    inv._ready()   # manually trigger since we're not in the game tree

func after_each() -> void:
    ServiceRegistry.clear()
```

---

## Group: add_item (non-stackable)

### TC-INV-01 — add_item returns true and emits item_added
```
content._defs["sword"] = make_item_def("sword")
item = ItemInstance.create("sword", 1)
watch_signals(inv)
result = inv.add_item(item)
assert_true(result)
assert_signal_emitted(inv, "item_added")
assert_signal_emitted(inv, "inventory_changed")
```

### TC-INV-02 — added item is findable by instance_id
```
content._defs["sword"] = make_item_def("sword")
item = ItemInstance.create("sword", 1)
inv.add_item(item)
found = inv.find_item(item.instance_id)
assert_not_null(found)
assert_eq(found.definition_id, "sword")
```

### TC-INV-03 — add_item returns false when inventory is full
```
content._defs["coin"] = make_item_def("coin")
for i in inv.capacity:   # fill all slots
    inv.add_item(ItemInstance.create("coin", 1))
result = inv.add_item(ItemInstance.create("coin", 1))
assert_false(result)
```

### TC-INV-04 — add_item with null returns false
```
result = inv.add_item(null)
assert_false(result)
```

### TC-INV-05 — add_item with quantity <= 0 returns false
```
content._defs["sword"] = make_item_def("sword")
item = ItemInstance.create("sword", 0)
result = inv.add_item(item)
assert_false(result)
```

### TC-INV-06 — add_item with missing definition returns false
```
item = ItemInstance.create("undefined_item", 1)
result = inv.add_item(item)
assert_false(result)
```

---

## Group: add_item (stackable)

### TC-INV-07 — stackable item stacks into existing slot
```
content._defs["potion"] = make_item_def("potion", true, 10)
inv.add_item(ItemInstance.create("potion", 3))
inv.add_item(ItemInstance.create("potion", 4))
found = inv.find_item_by_definition("potion")
assert_eq(found.quantity, 7)
```

### TC-INV-08 — stackable item overflows to a new slot when first slot is full
```
content._defs["arrow"] = make_item_def("arrow", true, 5)
inv.add_item(ItemInstance.create("arrow", 5))   # fill first slot
inv.add_item(ItemInstance.create("arrow", 3))   # needs second slot
var count := 0
for slot in inv.model.slots:
    if slot.item != null and slot.item.definition_id == "arrow":
        count += slot.item.quantity
assert_eq(count, 8)
```

---

## Group: remove_item_by_instance_id

### TC-INV-09 — remove reduces quantity and emits item_removed when qty reaches 0
```
content._defs["potion"] = make_item_def("potion", true, 10)
item = ItemInstance.create("potion", 3)
inv.add_item(item)
found = inv.find_item_by_definition("potion")
watch_signals(inv)
inv.remove_item_by_instance_id(found.instance_id, 3)
assert_signal_emitted(inv, "item_removed")
assert_null(inv.find_item_by_definition("potion"))
```

### TC-INV-10 — remove partial quantity does not emit item_removed
```
content._defs["potion"] = make_item_def("potion", true, 10)
inv.add_item(ItemInstance.create("potion", 5))
found = inv.find_item_by_definition("potion")
watch_signals(inv)
inv.remove_item_by_instance_id(found.instance_id, 2)
assert_signal_not_emitted(inv, "item_removed")
assert_eq(inv.find_item_by_definition("potion").quantity, 3)
```

### TC-INV-11 — remove on missing instance_id returns false
```
result = inv.remove_item_by_instance_id("nonexistent_id")
assert_false(result)
```

### TC-INV-12 — remove with quantity <= 0 returns false
```
content._defs["sword"] = make_item_def("sword")
inv.add_item(ItemInstance.create("sword", 1))
found = inv.find_item_by_definition("sword")
result = inv.remove_item_by_instance_id(found.instance_id, 0)
assert_false(result)
```

---

## Group: find_item / find_item_by_definition

### TC-INV-13 — find_item returns null for unknown instance_id
```
assert_null(inv.find_item("bad_id"))
```

### TC-INV-14 — find_item_by_definition returns null when item not in inventory
```
assert_null(inv.find_item_by_definition("shield"))
```

---

## Group: save / load

### TC-INV-15 — to_save_data / from_save_data round-trip preserves items
```
Arrange: content._defs["key"] = make_item_def("key")
         inv.add_item(ItemInstance.create("key", 1))
Act:     data = inv.to_save_data()
         inv2 = InventoryController.new()
         inv2.from_save_data(data)
Assert:  inv2.model.slots.any(func(s): return s.item != null and s.item.definition_id == "key")
Cleanup: inv2.free()
```

### TC-INV-16 — from_save_data with empty items list produces empty inventory
```
inv.from_save_data({"capacity": 5, "items": [null, null, null, null, null]})
for slot in inv.model.slots:
    assert_null(slot.item)
```

---

## Group: has_item / get_item_count

### TC-INV-17 — has_item returns true when item definition is present in inventory
```
content._defs["shield"] = make_item_def("shield")
inv.add_item(ItemInstance.create("shield", 1))
assert_true(inv.has_item("shield"))
```

### TC-INV-18 — has_item returns false when item not in inventory
```
assert_false(inv.has_item("axe"))
```

### TC-INV-19 — get_item_count returns correct total quantity across stack slots
```
content._defs["arrow"] = make_item_def("arrow", true, 5)
inv.add_item(ItemInstance.create("arrow", 4))
inv.add_item(ItemInstance.create("arrow", 3))   # overflows into second slot
assert_eq(inv.get_item_count("arrow"), 7)
```

### TC-INV-20 — get_item_count returns 0 for absent definition
```
assert_eq(inv.get_item_count("nonexistent"), 0)
```

---

## Group: EventRouter integration

### TC-INV-21 — add_item triggers EventRouter.inventory_changed for the owner entity
```
Arrange: events = EventRouter.new(); add_child_autofree(events)
         ServiceRegistry.register_service("events", events)
         inv.owner_id = "player"     # assuming InventoryController exposes owner_id
         content._defs["key"] = make_item_def("key")
         watch_signals(events)

Act:     inv.add_item(ItemInstance.create("key", 1))

Assert:  assert_signal_emitted_with_parameters(events, "inventory_changed", ["player"])
```
