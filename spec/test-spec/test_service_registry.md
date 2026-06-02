# Test Spec — ServiceRegistry

**Source:** `addons/mkit/kernel/services/service_registry.gd`  
**Test file:** `test/unit/kernel/test_service_registry.gd`  
**Extends:** `GutTest`

ServiceRegistry is a pure data store with no scene-tree dependencies, so every
case can be exercised on the plain script object (instantiated directly, not
added to the tree).

---

## Setup / Teardown

```gdscript
var reg: Node  # raw instance, not the autoload

func before_each() -> void:
    reg = load("res://addons/mkit/kernel/services/service_registry.gd").new()

func after_each() -> void:
    reg.free()
```

> Tests must NOT use `ServiceRegistry` (the autoload) — they use the local
> `reg` instance so the global singleton state is not polluted.

---

## Group: register_service

### TC-SR-01 — happy path: register and retrieve a service
```
Arrange: obj = Node.new()
Act:     reg.register_service("foo", obj)
Assert:  reg.has_service("foo") == true
         reg.get_service("foo") == obj
Cleanup: obj.free()
```

### TC-SR-02 — registering with empty id is a no-op
```
Arrange: obj = Node.new()
Act:     reg.register_service("", obj)
Assert:  reg.has_service("") == false
Cleanup: obj.free()
```

### TC-SR-03 — registering null service is a no-op
```
Act:     reg.register_service("bar", null)
Assert:  reg.has_service("bar") == false
```

### TC-SR-04 — registering duplicate id replaces the old entry
```
Arrange: obj1 = Node.new(); obj2 = Node.new()
Act:     reg.register_service("dup", obj1)
         reg.register_service("dup", obj2)
Assert:  reg.get_service("dup") == obj2
Cleanup: obj1.free(); obj2.free()
```

---

## Group: has_service

### TC-SR-05 — has_service returns false for missing id
```
Assert: reg.has_service("not_there") == false
```

### TC-SR-06 — has_service returns false for whitespace id
```
Assert: reg.has_service("   ") == false
```

---

## Group: get_service

### TC-SR-07 — get_service returns null for missing id
```
Assert: reg.get_service("missing") == null
```

### TC-SR-08 — get_service returns null for empty id
```
Assert: reg.get_service("") == null
```

---

## Group: unregister_service

### TC-SR-09 — unregister removes an existing service
```
Arrange: obj = Node.new(); reg.register_service("x", obj)
Act:     reg.unregister_service("x")
Assert:  reg.has_service("x") == false
Cleanup: obj.free()
```

### TC-SR-10 — unregister on missing id is safe (no error)
```
Act:    reg.unregister_service("does_not_exist")
Assert: (no crash; no assertion failure)
```

---

## Group: clear

### TC-SR-11 — clear removes all registered services
```
Arrange: reg.register_service("a", Node.new()); reg.register_service("b", Node.new())
Act:     reg.clear()
Assert:  reg.has_service("a") == false
         reg.has_service("b") == false
```

---

## Group: get_typed

### TC-SR-12 — get_typed returns the object when class matches
```
Arrange: obj = EventRouter.new(); reg.register_service("events", obj)
Act:     result = reg.get_typed("events", "EventRouter")
Assert:  result == obj
Cleanup: obj.free()
```

### TC-SR-13 — get_typed still returns the object when class mismatches (warning only)
```
Arrange: obj = Node.new(); reg.register_service("thing", obj)
Act:     result = reg.get_typed("thing", "EventRouter")
Assert:  result == obj   # warning emitted, but object returned
Cleanup: obj.free()
```
