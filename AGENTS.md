# AGENTS.md

This file provides guidance to Codex when working with code in this repository.

## What this is

Mkit is a reusable Godot 4.7 (GDScript 2.0) runtime kernel plus gameplay modules for 2D RPG / roguelike games. It is not a game. The framework is shipped as a self-contained addon under `res://addons/mkit/`; concrete game content lives outside the addon under `res://game/`.

Never hardcode a specific boss, item, room, economy, shop price, or other concrete game content into `addons/mkit/`. The addon should expose generic, data-driven mechanisms only.

For deeper task-specific guidance, read the existing Claude skill at `.claude/skills/mkit-dev/SKILL.md`. That file and its references are the single source of truth for the mkit development playbook.

Use these references directly instead of maintaining a Codex copy:

| Task | Read |
|------|------|
| Understand layers, pipeline, data model, folder map, entity layout | `.claude/skills/mkit-dev/references/architecture.md` |
| Add or extend a gameplay system the mkit way | `.claude/skills/mkit-dev/references/adding-a-system.md` |
| Write or run tests, debug a failing GUT test | `.claude/skills/mkit-dev/references/testing.md` |
| Match code style, handle `.uid` files, update docs | `.claude/skills/mkit-dev/references/conventions.md` |

## Commands

The engine binary is configurable through the `GODOT` env var. The Makefile defaults to the macOS app path, but this is a Godot 4.7-dev project, so point `GODOT` at a matching build when needed.

```bash
make ut            # run all unit tests headless via GUT
make ut-kernel     # kernel tests only
make ut-modules    # module tests only
make docs-server   # serve docs/ at http://localhost:8060
```

Single test examples:

```bash
$GODOT --headless -s addons/gut/gut_cmdln.gd -gtest=res://test/unit/modules/test_combat_resolver.gd -gexit
$GODOT --headless -s addons/gut/gut_cmdln.gd -gtest=res://test/unit/modules/test_combat_resolver.gd -gunit_test_name=test_tc_combat_05 -gexit
```

There is no separate build step. Godot compiles GDScript at load. Tests use GUT; test files `extends GutTest`, are named `test_*.gd`, and methods are named `test_tc_<area>_<nn>_<description>`. Each test spec has a matching design doc in `spec/test-spec/`.

## Architecture

Dependencies only point inward/downward:

```text
Game Content (res://game/) -> Module Layer -> Kernel Layer -> Platform Adapter Layer
```

- `addons/mkit/kernel/`: runtime foundation, including services, events, commands, context, content registry, HFSM, actions, conditions, effects, save, bootstrap, and debug.
- `addons/mkit/modules/`: reusable gameplay domains, including entity, stats, health, combat, abilities, status effects, inventory, loot, room, progression, AI, interaction, and UI.
- `game/demo/`: example content and per-phase demo scenes. Concrete content belongs here, not in the addon.

Nearly all gameplay should flow through the standard pipeline:

```text
Input / AI / Script
  -> GameCommand -> CommandRouter / CommandReceiver
  -> HFSM (StateMachine / State)
  -> GameAction (ActionRunner)
  -> GameEffect (EffectExecutor)
  -> Domain System
  -> EventRouter
  -> UI / Audio / VFX / Analytics
```

Static config is a `Resource`, mutable runtime state is a plain object instance, and scene-tree behavior is a `Node`. Preserve the recurring shape:

```text
Definition -> Instance -> Controller/Component -> System/Resolver
```

`ServiceRegistry` is the only autoload. `GameBootstrap` constructs and registers services under short ids such as `events`, `content`, `random`, `time`, `actions`, `effects`, `commands`, `scenes`, `pool`, `save`, `progression`, `analytics`, `ads`, `iap`, and `cloud_save`.

Entities use this fixed node layout:

```text
EntityRoot
  EntityIdentity
  Components/
  Controllers/
  Presentation/
```

Modules locate siblings through hardcoded relative paths from `owner`, so preserve this layout when editing scenes or entity code.

## Conventions

- Use GDScript 2.0 with strong typing. Type vars, params, and returns.
- Core files use `class_name Xxx` and `extends XxxBase`.
- Avoid bare `Dictionary` payloads through core APIs; wrap public payloads in typed objects.
- The addon source is deliberately comment-free. Do not add explanatory comments to `.gd` files under `addons/mkit/`.
- Keep the addon reusable. Concrete game content belongs in `game/`.
- When adding a new `.gd`, let Godot generate the sibling `.gd.uid` by importing the project or running tests; never hand-author UIDs.
- When public interfaces change, update the matching `docs/ref/<ClassName>.md` and affected layer or pipeline docs.
- Docs and specs are bilingual: keep Chinese conceptual prose Chinese, and keep code, identifiers, and file paths English.

## Definition Of Done

Before reporting a code change as complete:

1. Run the relevant GUT suite, or explain exactly why it could not be run.
2. Add or update focused tests for changed addon behavior.
3. Keep `spec/test-spec/` in sync with new or changed test files.
4. Confirm no upward dependency was introduced.
5. Confirm no concrete game content was added inside `addons/mkit/`.
