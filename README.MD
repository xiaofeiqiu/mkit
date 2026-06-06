# Mkit

Mkit is a reusable Godot 4.7 / GDScript 2.0 runtime kernel and gameplay module
framework for 2D RPG and roguelike projects.

This repository is not a complete game. It contains the reusable addon under
`res://addons/mkit/`, demo content under `res://game/demo/`, project
documentation, and GUT test coverage. Concrete game content should live outside
the addon and depend on Mkit through its public APIs.

## What It Provides

- A runtime kernel for services, commands, events, content registration, HFSM,
  actions, conditions, effects, save, pooling, time, scene routing, and debug.
- Reusable gameplay modules for entity composition, stats, health, combat,
  abilities, status effects, inventory, loot, rewards, quests, rooms,
  progression, AI, interaction, and UI feedback.
- Platform-facing service interfaces and mocks for analytics, ads, IAP, and
  cloud save.
- The phase8 demo in `game/demo/` showing how concrete content can use the
  addon.
- Unit and integration tests using GUT.
- Class reference docs under `docs/ref/` plus layer and pipeline docs.

## Architecture

Dependencies point inward and downward:

```text
Game Content (res://game/)
  -> Module Layer (res://addons/mkit/modules/)
  -> Kernel Layer (res://addons/mkit/kernel/)
  -> Platform Adapter Interfaces
```

The addon should stay generic and data-driven. Do not hardcode a specific boss,
item, room, shop price, economy rule, or other concrete game content inside
`addons/mkit/`.

Most gameplay follows the same runtime pipeline:

```text
Input / AI / Script
  -> GameCommand
  -> CommandRouter / CommandReceiver
  -> HFSM
  -> GameAction
  -> GameEffect
  -> Domain System
  -> EventRouter
  -> UI / Audio / VFX / Analytics
```

Static configuration is represented by `Resource` definitions, mutable runtime
state by plain instances, scene-tree behavior by nodes, and gameplay rules by
systems or resolvers:

```text
Definition -> Instance -> Controller / Component -> System / Resolver
```

## Repository Layout

```text
addons/
  mkit/               Reusable addon source
  gut/                GUT test framework
docs/                 Architecture, pipeline, layer, and class reference docs
game/demo/            Demo scenes and concrete sample content
spec/                 Implementation notes and planning specs
test/unit/            Kernel and module unit tests
test/integration/     Integration tests
tools/                Maintenance scripts
project.godot         Godot project configuration
Makefile              Test and docs helper commands
```

## Getting Started

1. Install or build a Godot 4.7-dev compatible editor/runtime.
2. Open `project.godot` in Godot.
3. Confirm the `Mkit` and `GUT` plugins are enabled in
   **Project > Project Settings > Plugins**.
4. Use the phase8 demo in `game/demo/` to inspect example content.
5. Add a `GameBootstrap` node to a game entry scene when building on top of the
   addon. `GameBootstrap` registers runtime services into the single
   `ServiceRegistry` autoload, loads resource databases, validates content, and
   enters the configured initial scene.

For command-line work, set `GODOT` if the default macOS app path is not correct:

```bash
export GODOT=/path/to/Godot
```

## Commands

```bash
make ut            # run all unit tests
make ut-kernel     # run kernel unit tests
make ut-modules    # run module unit tests
make int           # run integration tests
make phase8-test   # run the Phase 8 RPG loop auto-run smoke test
make docs-server   # serve docs/ at http://localhost:8060
```

Single-test examples:

```bash
$GODOT --headless -s addons/gut/gut_cmdln.gd -gtest=res://test/unit/modules/test_combat_resolver.gd -gexit
$GODOT --headless -s addons/gut/gut_cmdln.gd -gtest=res://test/unit/modules/test_combat_resolver.gd -gunit_test_name=test_tc_combat_05 -gexit
```

## Documentation

- `docs/readme.md` is the docs entry point.
- `docs/kernel_layer.md` documents kernel responsibilities.
- `docs/module_layer.md` documents reusable gameplay module responsibilities.
- `docs/platform_adapter_layer.md` documents platform-facing service contracts.
- `docs/pipeline.md` documents runtime pipelines.
- `docs/ref/` contains class-level reference pages.
- `addons/mkit/README.md` documents the addon package itself.

When changing public behavior or interfaces, update the matching docs page in
the same change.

## Development Rules

- Keep `addons/mkit/` reusable and content-agnostic.
- Keep dependencies pointing inward: `game/ -> modules -> kernel -> platform`.
- Use strongly typed GDScript 2.0.
- Keep core addon `.gd` files comment-free.
- Use `ServiceRegistry` as the only autoload.
- Preserve the entity node layout:

```text
EntityRoot
  EntityIdentity
  Components/
  Controllers/
  Presentation/
```

- Let Godot generate `.gd.uid` files for new scripts by importing or running
  tests. Do not hand-author UID files.
- Add focused GUT tests for changed addon behavior.

## Status

The project currently includes the kernel, implemented gameplay modules, the
phase8 demo, unit tests, integration tests, and reference docs. Treat `docs/` as
the source of truth for current architecture and public interfaces.
