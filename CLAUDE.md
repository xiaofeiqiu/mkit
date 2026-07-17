# CLAUDE.md

This file is the repo-local operating guide for Claude Code.

Read `AGENTS.md` as the full canonical guide for this repository. This file is a
Claude Code entrypoint that repeats the highest-risk rules so Claude can act
correctly without inventing a parallel workflow. If `CLAUDE.md`, `AGENTS.md`,
`docs/`, or old planning notes disagree with the current implementation, use the
implementation first and update the stale artifact in the same change when it
affects public behavior.

## Project Rules

Mkit is a reusable Godot 4.6.3 stable runtime kernel plus gameplay modules under
`res://addons/mkit/`. Concrete sample game content lives under `res://game/`.

Never hardcode a specific boss, item, room, quest, shop price, economy rule, or
other concrete game content into `addons/mkit/`. The addon must expose reusable,
data-driven mechanisms. Concrete content belongs under `game/` or another
game-owned tree.

Preserve dependency direction:

```text
addons/mkit/kernel -> shared foundation
addons/mkit/modules -> reusable gameplay modules
game -> concrete sample game content
```

`addons/mkit/` must not depend on `game/`. Game scripts and scenes may depend on
addon classes.

## Runtime Shape

`project.godot` has one autoload:

```text
ServiceRegistry="*res://addons/mkit/kernel/services/service_registry.gd"
```

The main scene is `res://game/bootstrap.tscn`. It hosts `GameBootstrap`, loads
`game/resources/village_rpg_content.tres`, and enters
`res://game/village_rpg_demo.tscn`.

Prefer the established gameplay pipeline instead of adding parallel control
paths:

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
should go through typed `EventService` methods where they exist.

## Entity Scenes

Preserve the established `EntityRoot` scene shape and child names:

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

Do not rename or move these paths unless the related module code and tests are
updated in the same change.

## Commands

Use the Makefile targets instead of ad hoc Godot invocations when possible:

```bash
make check           # full local gate: layering, docs-check, and every test gate
make test            # unit, integration, and demo auto-run gates
make ut              # unit tests: kernel then modules
make ut-kernel       # GUT tests under test/unit/kernel
make ut-modules      # GUT tests under test/unit/modules
make int             # integration tests under test/integration
make demo-test       # run game/bootstrap.tscn headlessly with --demo-auto-run
make docs-check      # validate docs comments, generated API freshness, links, nav, cookbook sections, stale demo paths
make docs-api        # regenerate doctool XML and static API HTML
make layering        # enforce kernel/modules/game dependency boundaries
```

For focused headless Godot runs, prefer an explicit log file:

```bash
$GODOT --headless --log-file /tmp/mkit_focus.log -s addons/gut/gut_cmdln.gd -gtest=res://test/unit/modules/test_combat_service.gd -gexit
```

## Reviews And Docs

When creating any document under `reviews/`, include a `## Progress Tracker`
section for the proposals, issues, fixes, or follow-up items described by that
review document. This tracker is not for the agent's current writing task; it is
for later implementation/resolution status. When a documented item is addressed,
return to the same review document and mark that item checked.

For review or audit requests, write the requested artifact first and keep
findings focused on bugs, risks, behavioral regressions, and missing tests. Do
not mix in unrequested fixes unless the user asks to address the findings.

Do not hand-edit generated API pages under `docs/generated/html/`. Update the
source `.gd` declaration or Godot `##` doc comment and run `make docs-api`.

Run `make docs-check` after changing public docs or public addon APIs.

Keep conceptual docs in Chinese when the surrounding file is Chinese. Keep code,
identifiers, resource paths, commands, and class names in English.

## Code Style

Use GDScript 2.0 with explicit types for variables, parameters, and returns
where the surrounding code does.

Public addon scripts generally use `class_name`; `ServiceRegistry` is the known
autoload exception.

Avoid explanatory inline comments in `.gd` files under `addons/mkit/`; prefer
clear names and focused tests. Public Godot `##` doc comments are allowed for
classes and API members because generated API docs are built from them.

Avoid untyped public `Dictionary` payloads for core APIs when a typed object
already exists or should exist.

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
