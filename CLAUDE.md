# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Mkit is a **reusable Godot 4.7 (GDScript 2.0) runtime kernel + gameplay modules** for 2D RPG / roguelike games. It is not a game; it is a framework shipped as a self-contained addon under `res://addons/mkit/`. Concrete game content (a specific boss, item, room, ad economy, shop price) must never be hardcoded into the addon — only generic, data-driven mechanisms belong there. Game-specific content lives outside the addon under `res://game/`.

## Commands

The engine binary is configurable via the `GODOT` env var (Makefile defaults to the macOS app path; this is a Godot 4.7-dev project, so point `GODOT` at a matching build).

```bash
make ut            # run all unit tests (kernel + modules) headless via GUT
make ut-kernel     # kernel tests only  (test/unit/kernel)
make ut-modules    # module tests only  (test/unit/modules)
make docs-server   # serve docs/ at http://localhost:8060

# Run a single test script or single test, calling GUT directly:
$GODOT --headless -s addons/gut/gut_cmdln.gd -gtest=res://test/unit/modules/test_combat_resolver.gd -gexit
$GODOT --headless -s addons/gut/gut_cmdln.gd -gtest=res://test/unit/modules/test_combat_resolver.gd -gunit_test_name=test_tc_combat_05 -gexit
```

There is no separate build step (Godot compiles GDScript at load). Tests use the GUT addon; test files `extends GutTest`, are named `test_*.gd`, and methods are named `test_tc_<area>_<nn>_<description>`. Project design, public interfaces, layers, and pipelines are documented under `docs/`.

## Architecture

### Layered, one-way dependency

```
Game Content (res://game/)  ->  Module Layer  ->  Kernel Layer  ->  Platform Adapter Layer
```

Dependencies only ever point **inward/downward**: `game/` may use modules + kernel; modules may use the kernel; the kernel depends only on abstract platform interfaces. Never add a reverse dependency (e.g. the addon importing anything from `game/`).

- `addons/mkit/kernel/` — runtime foundation: `services/` (service_registry, random, time, scene_router, object_pool, + platform services), `events/`, `commands/`, `context/`, `registry/` (content), `state_machine/` (HFSM), `actions/`, `conditions/`, `effects/`, `save/`, `bootstrap/`, `debug/`. Built-in actions/conditions/effects live in `builtin/` subfolders.
- `addons/mkit/modules/` — reusable gameplay domains: `entity/`, `stats/`, `health/`, `combat/`, `abilities/`, `status_effects/`, `inventory/`, `loot/`, `room/`, `progression/`, `ai/`, `interaction/`, `ui/`.
- `game/demo/` — example content and per-phase demo scenes (`phaseN_*.tscn`, `bootstrap_phaseN.tscn`) that exercise the kernel/modules. This is the place for concrete content, NOT the addon.

### The one runtime pipeline

Nearly all gameplay flows through this chain — follow it rather than wiring systems directly:

```
Input / AI / Script
  -> GameCommand -> CommandRouter / CommandReceiver
  -> HFSM (StateMachine / State)
  -> GameAction (ActionRunner)
  -> GameEffect (EffectExecutor)
  -> Domain System
  -> EventRouter
  -> UI / Audio / VFX / Analytics
```

### Resource / Instance / Node split

Static config is a `Resource`, mutable runtime state is a plain object instance, scene-tree behavior is a `Node`. Definitions are paired as `Definition -> Instance -> Controller/Component -> System/Resolver`, e.g.:

```
AbilityDefinition -> AbilityInstance -> AbilityController
ItemDefinition    -> ItemInstance    -> InventoryController / EquipmentController
RoomDefinition    -> RoomRuntime     -> RoomController / RunDirector
DamageRequest     -> DamageResult    -> CombatResolver / HealthComponent
```

### Bootstrap and service access

`ServiceRegistry` is the **only autoload** (registered by `plugin.gd`). Everything else is constructed at startup by a `GameBootstrap` node placed in the entry scene — it builds every kernel/platform service, registers each under a short string id, loads + validates content databases, then routes to `initial_scene_path`. Code reaches services through the registry by id, e.g.:

```gdscript
var router := ServiceRegistry.get_service("commands") as CommandRouter
```

Service ids include: `events`, `content`, `random`, `time`, `actions`, `effects`, `commands`, `combat`, `scenes`, `pool`, `save`, `progression`, `analytics`, `ads`, `iap`, `cloud_save`. The platform services (`analytics`, `ads`, `iap`, `cloud_save`) are currently **mock implementations** (`*_service_mock.gd`) behind real interfaces — wire real SDKs by swapping the implementation, not the interface.

Services come in two deliberate flavors — pick by behavior, not by habit:

- **Node services** are `extends Node`, added to the `ServiceRegistry` tree with `add_child` in `game_bootstrap.gd`, and registered. Use this when the service needs scene-tree lifecycle — `_process`/`_physics_process`, signals, or timers (e.g. `EventRouter`, `ActionRunner`, `CommandRouter`, `SceneRouter`, `SaveManager`).
- **RefCounted services** are `extends RefCounted`, registered but *not* added to the tree. Use this for lightweight, lifecycle-free state or pure logic with no per-frame tick — `RandomService` (RNG state), `TimeService` (time scale/pause), `EffectExecutor` (stateless executor + a bounded trace buffer), `CombatResolver` (stateless damage-resolution logic). These may be freely `new()`'d as an on-demand fallback or a test fixture without a tree (e.g. `AbilityController` / `RewardSystem` fall back to `EffectExecutor.new()` when no `effects` service is registered; `HitboxComponent` / `DealDamageEffect` fall back to `CombatResolver.new()` when no `combat` service is registered) — do **not** convert them to `Node`, as that would orphan those call sites. Any retained buffer must stay bounded and offer a reset (e.g. `EffectExecutor.clear_recent_results()`).

### Entity node-layout convention

Entities are scene trees with a fixed child layout, and modules locate their siblings via hardcoded relative paths from `owner`. When building or modifying an entity, preserve this layout:

```
EntityRoot
  EntityIdentity            # owner.get_node("EntityIdentity")
  Components/               # StatsComponent, HealthComponent, ResourcePoolComponent, ...
  Controllers/              # AbilityController, StatusEffectController, InventoryController, ...
  Presentation/             # AnimationPlayer, sprites, ...
```

## Conventions

- **GDScript 2.0, strongly typed.** Core files use `class_name Xxx` / `extends XxxBase` and type every var/param/return. Avoid passing bare `Dictionary` payloads through core APIs without an object wrapper.
- **The source is deliberately comment-free.** All 108 addon `.gd` files contain zero comments; `tools/strip_comments.py` and `tools/clean_comments.py` enforce this. Match that style — do not add explanatory comments to addon code; let names and types carry meaning.
- Keep the addon reusable: if you find yourself naming a concrete game entity/item/room/economy inside `addons/mkit/`, it belongs in `game/` instead.

## Reference

- `docs/` — source of truth for project guidance: generated class reference (`docs/ref/<ClassName>.md`), layer overviews (`kernel_layer.md`, `module_layer.md`, `platform_adapter_layer.md`), and runtime pipeline docs (`pipeline.md`). Note: several docs are written in Chinese.
