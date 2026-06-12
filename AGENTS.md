# AGENTS.md

This file is the repo-local operating guide for Codex and other coding agents.
Treat the current source tree as the source of truth. If this file, `docs/`, or
old planning notes disagree with implementation, use the implementation first
and update the stale artifact in the same change when it affects public behavior.

## Project Facts

Mkit is a reusable Godot 4.6.3 stable runtime kernel plus gameplay modules for 2D RPG
and roguelike projects. It is packaged as the `Mkit` editor plugin at
`res://addons/mkit/` and the project enables that plugin together with GUT.

This repository also contains concrete sample game content under `res://game/`.
Current game content includes `game/bootstrap.tscn`, `game/village_rpg_demo.tscn`,
`game/entities/`, `game/resources/`, `game/scenes/`, and `game/ui/`. There is no
current `game/demo/` directory.

Never hardcode a specific boss, item, room, quest, shop price, economy rule, or
other concrete game content into `addons/mkit/`. The addon exposes reusable,
data-driven mechanisms; concrete content belongs under `game/` or another
game-owned tree.

## Current Runtime Shape

`project.godot` has one autoload:

```text
ServiceRegistry="*res://addons/mkit/kernel/services/service_registry.gd"
```

The main scene is `res://game/bootstrap.tscn`. That scene hosts `GameBootstrap`,
loads `game/resources/village_rpg_content.tres`, and enters
`res://game/village_rpg_demo.tscn`.

`GameBootstrap` registers the kernel services at boot:

```text
events, content, random, time, actions, effects, commands, scenes, pool, save,
audio
```

`ModuleBootstrap` (used by `game/bootstrap.tscn`) extends it and appends the
built-in module services:

```text
combat, progression, quest, shop, dialogue, world, loot
```

It then loads configured `ResourceDatabase` assets into `ContentService`,
validates content ids, loads a save if `SaveService.save_path` exists, and enters
`initial_scene_path`.

## Source Layout

`addons/mkit/kernel/` contains shared runtime foundation:

```text
actions, bootstrap, commands, conditions, context, debug, effects, events,
registry, save, services, state_machine
```

`addons/mkit/modules/` contains reusable gameplay domains:

```text
ai, combat, dialogue, entity, interaction, inventory, loot, progression, quest,
shop, ui, world
```

Dependencies must point inward toward the addon foundation. `addons/mkit/` must
not depend on `game/`. Game scripts and scenes may depend on addon classes.

## Gameplay Pipeline

Prefer the existing pipeline instead of adding parallel control paths:

```text
Input / AI / Script
  -> GameCommand / CommandReceiver
  -> optional CommandService routing when the caller only knows target_id
  -> StateMachine / State
  -> GameAction / ActionService
  -> GameEffect / EffectService
  -> Domain service or component
  -> EventService
  -> UI / audio / VFX
```

Use `GameplayContext` / `ActionContext` for execution context. Public events
should go through typed `EventService` methods where they exist; `DomainEvent`
is the shared trace payload.

## Data Model

Static configuration is a `Resource`, usually a `ContentDefinition` subclass
that returns a stable content id from `get_content_id()`. `ContentService`
registers resources from `ResourceDatabase`, rejects missing or duplicate ids,
and indexes by id and script type.

Mutable runtime state is usually a plain `RefCounted` object such as an instance,
model, state, result, or option. Scene-tree behavior is a `Node` or `Resource`
controller/component/service depending on Godot lifecycle needs.

Keep the established shape:

```text
Definition -> Instance/State/Result -> Controller/Component -> Service/System
```

## Entity Scenes

`EntityRoot` extends `CharacterBody2D` and expects these child names:

```text
EntityRoot
  EntityIdentity
  StateMachine
  CommandReceiver
  Components/
  Controllers/
  Presentation/
```

Many modules use hardcoded relative lookups from `owner`, including:

```text
Components/StatsComponent
Components/HealthComponent
Components/ResourcePoolComponent
Components/HitboxComponent
Components/HurtboxComponent
Components/InteractionComponent
Controllers/AbilityController
Controllers/StatusEffectController
Controllers/InventoryController
Controllers/EquipmentController
Presentation/AnimationPlayer
```

Preserve these names and paths when editing entity scenes or module code.

## Commands

The Godot binary is controlled by `GODOT`; the Makefile defaults to
`/Applications/Godot.app/Contents/MacOS/Godot`.

```bash
make check           # full local gate: layering, docs-check, and every test gate
make test            # run all test gates: unit tests, integration tests, and demo auto-run
make run             # start the current game from res://game/bootstrap.tscn
make editor          # open this project in the Godot editor
make clean           # remove generated API docs, temp integration scenes, and test logs
make clean-cache     # delete the .godot import cache, then rebuild imports headlessly
make reimport        # remove temp integration scenes, then refresh Godot imports
make ut              # run addon unit tests after the layering check: kernel then modules
make ut-kernel       # run GUT unit tests under test/unit/kernel
make ut-modules      # run GUT unit tests under test/unit/modules
make int             # run integration tests under test/integration after layering and reimport
make demo-test       # run game/bootstrap.tscn headlessly with --demo-auto-run
make docs-server     # serve docs/ locally on DOCS_PORT, default 8060
make docs-xml        # regenerate Godot doctool XML for res://addons/mkit
make docs-html       # rebuild static API HTML from generated doctool XML
make docs-api        # regenerate both doctool XML and static API HTML
make docs-check      # check doc comments, generated API freshness, links, nav, cookbook sections, and stale demo paths
make layering        # enforce kernel/modules/game dependency boundaries
make cookbook-fields # audit cookbook field-documentation coverage
```

Focused GUT examples:

```bash
$GODOT --headless --log-file /tmp/mkit_focus.log -s addons/gut/gut_cmdln.gd -gtest=res://test/unit/modules/test_combat_service.gd -gexit
$GODOT --headless --log-file /tmp/mkit_focus.log -s addons/gut/gut_cmdln.gd -gtest=res://test/unit/modules/test_combat_service.gd -gunit_test_name=test_tc_combat_01_example -gexit
```

Prefer explicit `--log-file /tmp/...` for headless Godot runs.

## Tests

Tests use GUT. Test scripts extend `GutTest`. Unit tests live under
`test/unit/kernel` and `test/unit/modules`; cross-system tests live under
`test/integration`.

Use the existing naming pattern:

```text
test_*.gd
test_tc_<area>_<nn>_<description>()
test_tc_int_<area>_<nn>_<description>()
```

When changing addon behavior, add or update focused tests near the changed
system. Use `make int` when behavior crosses services, content loading, save,
scene routing, entity scenes, or the gameplay pipeline.

## Docs

API reference pages under `docs/generated/html/` are generated from Godot
doctool XML, which comes from `.gd` declarations and adjacent Godot `##` doc
comments. Do not hand-edit generated API pages; update the source doc comment
and run `make docs-api`.

Run `make docs-check` after changing public docs or public addon APIs. The check
first verifies doc comment coverage and generated API freshness, then validates
Markdown links, `docs/index.html` navigation, required cookbook ownership
sections headed `## 你负责 / mkit 负责`, and rejects user-facing docs that expose
old `game/demo` paths.

Keep conceptual docs in Chinese when the surrounding file is Chinese. Keep code,
identifiers, resource paths, commands, and class names in English.

When creating any document under `reviews/`, include a `## Progress Tracker`
section for the proposals, issues, fixes, or follow-up items described by that
review document. This tracker is not for the agent's current writing task; it is
for later implementation/resolution status. When a documented item is addressed,
return to the same review document and mark that item checked.

## Code Style

Use GDScript 2.0 with explicit types for variables, parameters, and returns
where the surrounding code does. Public addon scripts generally use
`class_name`; `ServiceRegistry` is the known autoload exception.

Avoid explanatory inline comments in `.gd` files under `addons/mkit/`; use clear
names and tests instead. Public Godot `##` doc comments are allowed for classes
and API members because generated API docs are built from them.

Avoid untyped public `Dictionary` payloads for core APIs when a typed object
already exists or should exist. Existing typed carriers include commands,
contexts, definitions, events, results, options, instances, and saveable objects.

When adding a new `.gd` script, let Godot generate the sibling `.gd.uid` by
running an import or relevant test. Do not hand-author `.gd.uid` files.

## Definition Of Done

Before reporting a code change as complete:

1. Run the relevant GUT target, or state exactly why it was not run.
2. Add or update focused tests for changed addon behavior.
3. Update public `##` doc comments and run `make docs-api` when generated API
   docs are affected; update higher-level docs when public behavior changes.
4. Run `make docs-check` for public API or docs changes.
5. Confirm no dependency from `addons/mkit/` to `game/` was introduced.
6. Confirm no concrete game content was added inside `addons/mkit/`.
