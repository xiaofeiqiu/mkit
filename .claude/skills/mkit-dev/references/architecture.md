# mkit architecture reference

How the framework is shaped, so a change lands in the right place and follows the
grain of the codebase. The canonical project docs live in `docs/readme.md`,
`docs/pipeline.md`, the layer docs, and `docs/ref/`; this is the working summary.

## Contents
- [Layers and dependency direction](#layers-and-dependency-direction)
- [The one runtime pipeline](#the-one-runtime-pipeline)
- [Resource / Instance / Node data model](#resource--instance--node-data-model)
- [Folder map](#folder-map)
- [Services and the registry](#services-and-the-registry)
- [Entity node layout](#entity-node-layout)
- [Bootstrap flow](#bootstrap-flow)

## Layers and dependency direction

```
Game Content (res://game/)  ->  Module Layer  ->  Kernel Layer  ->  Platform Adapter Layer
```

Dependencies point **only inward/downward**. `game/` may use modules + kernel;
modules may use the kernel; the kernel depends only on *abstract platform
interfaces*. A reverse edge (the addon importing from `game/`, the kernel
referencing a module type) breaks reusability and is never acceptable.

- **Kernel** (`addons/mkit/kernel/`): runtime foundation — `services/`,
  `events/`, `commands/`, `context/`, `registry/` (content), `state_machine/`
  (HFSM), `actions/`, `conditions/`, `effects/`, `save/`, `bootstrap/`,
  `debug/`. Built-in actions/conditions/effects live in `builtin/` subfolders.
- **Modules** (`addons/mkit/modules/`): reusable gameplay domains — `entity/`,
  `stats/`, `health/`, `combat/`, `abilities/`, `status_effects/`, `inventory/`,
  `loot/`, `room/`, `progression/`, `ai/`, `interaction/`, `ui/`.
- **Game** (`game/demo/`): concrete content and per-phase demo scenes
  (`phaseN_*.tscn`, `bootstrap_phaseN.tscn`). This — not the addon — is where a
  specific entity, item, room, or economy belongs.

**Decision rule:** if the thing you're building is generic and could serve a
different RPG, it goes in the addon. If it names or prices a specific piece of
game content, it goes in `game/`.

## The one runtime pipeline

Nearly all gameplay flows through this chain. Hook into it rather than wiring
systems together directly — that is what keeps domains decoupled and unit-testable.

```
Input / AI / Script
  -> GameCommand            (intent, created by input reader / AI brain / script)
  -> CommandRouter / CommandReceiver
  -> HFSM (StateMachine / State)        (decides what the entity does now)
  -> GameAction (ActionRunner)          (time-extended behavior: windup/active/recovery)
  -> GameEffect (EffectExecutor)        (atomic state changes)
  -> Domain System                      (CombatResolver, InventoryController, ...)
  -> EventRouter                        (broadcasts domain events)
  -> UI / Audio / VFX / Analytics       (react to events)
```

Where to add behavior:
- A new *intent* the player/AI can express → a `GameCommand` + a state that
  handles it.
- A *time-extended behavior* (an attack with startup/active/recovery, a dash) →
  a `GameAction` (see `kernel/actions/builtin/` for `timed_attack_action.gd`,
  `dash_action.gd`, `cast_action.gd`).
- An *atomic state change* (deal damage, heal, grant item, apply status) → a
  `GameEffect` (see `kernel/effects/builtin/`).
- A *gate* on whether something may happen (cooldown ready, target in range) → a
  `Condition` (see `kernel/conditions/builtin/`).
- A *new domain rule* (a damage formula, a loot roll) → a System/Resolver in
  the relevant module.

Read `docs/pipeline.md` for every concrete pipeline already wired, with class
links.

## Resource / Instance / Node data model

```
Resource        = static definition, reusable, serializable   (*Definition)
Runtime Instance = mutable runtime state                       (*Instance / *Runtime / *Result)
Node            = scene-tree behavior, lifecycle, signals, physics  (*Controller / *Component / *System)
```

Canonical pairings:

```
AbilityDefinition -> AbilityInstance -> AbilityController
ItemDefinition    -> ItemInstance    -> InventoryController / EquipmentController
RoomDefinition    -> RoomRuntime     -> RoomController / RunDirector
DamageRequest     -> DamageResult    -> CombatResolver / HealthComponent
EntityDefinition  -> EntityRoot / EntitySpawner
UpgradeDefinition -> ProgressionState -> ProgressionSystem
```

Why the split matters: Resources are shared and saved to disk, so putting mutable
per-instance state on them causes cross-contamination and save corruption. Keep
mutation on instances, scene behavior on nodes.

## Folder map

```
addons/mkit/
  plugin.gd, plugin.cfg        # registers the ServiceRegistry autoload
  kernel/
    services/                  # service_registry, random, time, scene_router,
                               #   object_pool, + platform services (analytics/ads/iap/cloud_save)
    bootstrap/game_bootstrap.gd  # builds + registers every service at startup
    events/ commands/ context/ registry/ state_machine/
    actions/ (+ builtin/)  conditions/ (+ builtin/)  effects/ (+ builtin/)
    save/ debug/
  modules/
    entity/ stats/ health/ combat/ abilities/ status_effects/
    inventory/ loot/ room/ progression/ ai/ interaction/ ui/
game/demo/                     # demo content + phaseN slices (concrete content lives here)
test/unit/{kernel,modules}/    # GUT tests
docs/                          # source of truth: class ref + layer/pipeline overviews
tools/                         # strip_comments.py / clean_comments.py
```

## Services and the registry

`ServiceRegistry` is the **only autoload** (added by `plugin.gd`). Everything
else is constructed at startup by `GameBootstrap` and registered under a short
string id. Gameplay code looks services up by id and never news-up kernel
singletons itself.

Registered ids and their types:

| id | type |
|----|------|
| `events` | `EventRouter` |
| `content` | `ContentRegistry` |
| `random` | `RandomService` |
| `time` | `TimeService` |
| `actions` | `ActionRunner` |
| `effects` | `EffectExecutor` |
| `commands` | `CommandRouter` |
| `scenes` | `SceneRouter` |
| `pool` | `ObjectPool` |
| `save` | `SaveManager` |
| `progression` | `ProgressionSystem` |
| `analytics` | `AnalyticsService` (mock) |
| `ads` | `AdService` (mock) |
| `iap` | `IAPService` (mock) |
| `cloud_save` | `CloudSaveService` (mock) |

The four platform services are **mock implementations** (`*_service_mock.gd`)
behind real interfaces. To wire a real SDK, swap the implementation passed to the
registry in `game_bootstrap.gd` — do not change the interface or callers.

## Entity node layout

Entities are scene trees with a fixed child layout. Modules find their siblings
via hardcoded relative paths from `owner`, so preserving this layout is what lets
generic modules operate on any entity:

```
EntityRoot
  EntityIdentity            # owner.get_node("EntityIdentity")
  Components/               # StatsComponent, HealthComponent, ResourcePoolComponent, ...
  Controllers/              # AbilityController, StatusEffectController, InventoryController, ...
  Presentation/             # AnimationPlayer, sprites, ...
```

Example sibling lookup you'll see throughout the modules:
`target.get_node("Components/HealthComponent") as HealthComponent`. When you add
a component or controller, place it under the matching folder and reference it by
this relative path so other systems can find it.

## Bootstrap flow

A `GameBootstrap` node placed in the entry scene drives startup
(`game_bootstrap.gd`):

```
_ready -> boot():
  _register_kernel_services()   # build each service, name it, add_child, register_service(id, svc)
  _load_content()               # ContentRegistry.load_database() for each ResourceDatabase
  _validate_content()           # ContentValidationResult errors/warnings
  _initialize_runtime_systems()
  _load_profile()
  _enter_initial_scene()        # routes to initial_scene_path (deferred)
```

`resource_databases` and `initial_scene_path` are `@export` fields set per scene.
Adding a kernel service means: construct it in `_register_kernel_services()`,
`add_child` it if it's a Node, and `register_service("<id>", svc)`.
