# Test Spec — EntitySpawner

**Source:** `addons/mkit/modules/entity/entity_spawner.gd`  
**Test file:** `test/unit/modules/test_entity_spawner.gd`  
**Extends:** `GutTest`

`EntitySpawner` extends `Node`. It reads `ServiceRegistry → ContentRegistry` for
`EntityDefinition`. Tests that require loading a real `PackedScene` are marked
**integration only** and excluded from the pure unit suite — pure tests cover
all signal-emitting failure paths.

---

## Helpers

```gdscript
class StubContent extends ContentRegistry:
    var _defs: Dictionary = {}
    func get_resource(id: String) -> Resource:
        return _defs.get(id)

func make_def(id: String, scene: String = "") -> EntityDefinition:
    var d = EntityDefinition.new()
    d.entity_definition_id = id
    d.display_name         = "Test " + id
    d.scene_path           = scene
    d.base_stats           = {}
    d.starting_ability_ids = []
    d.tags                 = []
    d.default_faction      = "neutral"
    return d

var spawner: EntitySpawner
var content: StubContent
var parent_node: Node
```

---

## Setup / Teardown

```gdscript
func before_each() -> void:
    content = StubContent.new()
    ServiceRegistry.register_service("content", content)
    spawner = EntitySpawner.new()
    add_child_autofree(spawner)
    spawner._ready()
    parent_node = Node.new()
    add_child_autofree(parent_node)

func after_each() -> void:
    ServiceRegistry.clear()
```

---

## Group: spawn_entity — failure paths (pure unit)

### TC-ES-01 — empty definition_id emits entity_spawn_failed and returns null
```
watch_signals(spawner)
result = spawner.spawn_entity("", parent_node)
assert_null(result)
assert_signal_emitted_with_parameters(spawner, "entity_spawn_failed", ["", "empty_definition_id"])
```

### TC-ES-02 — null parent emits entity_spawn_failed and returns null
```
content._defs["slime"] = make_def("slime")
watch_signals(spawner)
result = spawner.spawn_entity("slime", null)
assert_null(result)
assert_signal_emitted_with_parameters(spawner, "entity_spawn_failed", ["slime", "missing_parent"])
```

### TC-ES-03 — definition not in ContentRegistry emits entity_spawn_failed
```
# "ghost" is absent from content._defs
watch_signals(spawner)
result = spawner.spawn_entity("ghost", parent_node)
assert_null(result)
assert_signal_emitted_with_parameters(spawner, "entity_spawn_failed", ["ghost", "missing_definition"])
```

### TC-ES-04 — definition with empty scene_path emits entity_spawn_failed
```
content._defs["hollow"] = make_def("hollow", "")
watch_signals(spawner)
result = spawner.spawn_entity("hollow", parent_node)
assert_null(result)
assert_signal_emitted_with_parameters(spawner, "entity_spawn_failed", ["hollow", "missing_scene_path"])
```

### TC-ES-05 — spawn with no ContentRegistry service emits entity_spawn_failed
```
ServiceRegistry.unregister_service("content")
watch_signals(spawner)
result = spawner.spawn_entity("anything", parent_node)
assert_null(result)
assert_signal_emitted(spawner, "entity_spawn_failed")
```

---

## Group: spawn_entity — success path (integration; requires real scene on disk)

> Run these in the integration suite with `res://test/fixtures/test_entity.tscn`
> present. Skip in pure unit runs.

### TC-ES-06 (integration) — valid definition spawns node under parent and emits entity_spawned
```
content._defs["test_entity"] = make_def("test_entity", "res://test/fixtures/test_entity.tscn")
watch_signals(spawner)
entity = spawner.spawn_entity("test_entity", parent_node, Vector2(10, 20))
assert_not_null(entity)
assert_true(parent_node.get_children().has(entity))
assert_signal_emitted_with_parameters(spawner, "entity_spawned", [entity, "test_entity"])
```

### TC-ES-07 (integration) — custom runtime_id is written to EntityIdentity
```
content._defs["test_entity"] = make_def("test_entity", "res://test/fixtures/test_entity.tscn")
entity = spawner.spawn_entity("test_entity", parent_node, Vector2.ZERO, "hero_001")
identity = entity.get_node_or_null("EntityIdentity") as EntityIdentity
assert_not_null(identity)
assert_eq(identity.entity_id, "hero_001")
```

### TC-ES-08 (integration) — two spawns with no runtime_id get different entity_ids
```
content._defs["test_entity"] = make_def("test_entity", "res://test/fixtures/test_entity.tscn")
e1 = spawner.spawn_entity("test_entity", parent_node)
e2 = spawner.spawn_entity("test_entity", parent_node)
id1 = (e1.get_node_or_null("EntityIdentity") as EntityIdentity).entity_id
id2 = (e2.get_node_or_null("EntityIdentity") as EntityIdentity).entity_id
assert_ne(id1, id2)
```

### TC-ES-09 (integration) — base_stats are applied to StatsComponent
```
def = make_def("brute", "res://test/fixtures/test_entity.tscn")
def.base_stats = {"attack_power": 15.0, "max_health": 200.0}
content._defs["brute"] = def
entity = spawner.spawn_entity("brute", parent_node)
stats = entity.get_node_or_null("Components/StatsComponent") as StatsComponent
assert_not_null(stats)
assert_eq(stats.get_base_stat("attack_power"), 15.0)
assert_eq(stats.get_base_stat("max_health"), 200.0)
```

### TC-ES-10 (integration) — starting_ability_ids are registered on AbilityController
```
def = make_def("mage", "res://test/fixtures/test_entity.tscn")
def.starting_ability_ids = ["fireball", "blink"]
content._defs["mage"] = def
entity = spawner.spawn_entity("mage", parent_node)
ctrl = entity.get_node_or_null("Controllers/AbilityController") as AbilityController
assert_not_null(ctrl)
assert_true(ctrl.has_ability("fireball"))
assert_true(ctrl.has_ability("blink"))
```
