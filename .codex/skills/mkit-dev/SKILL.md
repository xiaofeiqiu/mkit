---
name: mkit-dev
description: >-
  Engineering playbook for developing and maintaining the mkit Godot 4.7 /
  GDScript 2.0 game framework, a layered runtime kernel plus reusable gameplay
  modules for 2D RPG / roguelike games. Use this whenever working inside the
  mkit repo: adding or changing gameplay systems, modules, actions, effects,
  commands, conditions, entities, services, GUT tests, docs/ref, specs, or code
  reviews for architecture and layering. Trigger when a task touches
  addons/mkit/, game/, GDScript (.gd / .tscn), the command -> action -> effect
  pipeline, ServiceRegistry, the Definition -> Instance -> Controller model, or
  the rule that addon code must not hardcode concrete game content.
---

# Developing and maintaining mkit

Mkit is not a game. It is a reusable Godot 4.7 (GDScript 2.0) runtime kernel plus
gameplay modules, shipped as a self-contained addon under `res://addons/mkit/`.
Concrete games are built on top of it, and concrete content belongs under
`res://game/`.

Before editing, read the project instructions in `AGENTS.md`. Then load only the
reference file that matches the task:

| Task | Read |
|------|------|
| Understand layers, pipeline, data model, folder map, entity layout | `references/architecture.md` |
| Add or extend a gameplay system the mkit way | `references/adding-a-system.md` |
| Write or run tests, debug a failing GUT test | `references/testing.md` |
| Match code style, handle `.uid` files, update docs | `references/conventions.md` |

Before writing code, skim the relevant `spec/combined/NN_*.md` design doc. The
spec is the source of truth for intent; the code shows the current implementation.

## Orientation

1. Find the layer: `addons/mkit/kernel/`, `addons/mkit/modules/`, or `game/`.
   Dependencies only point inward/downward.
2. Search for the existing mechanism first. New behavior is usually a new data
   definition, action, effect, or condition, not a bespoke system.
3. Read the closest existing sibling file and mirror its shape.
4. Keep concrete content out of `addons/mkit/`.

## Core invariants

- Addon code exposes generic, data-driven mechanisms only.
- Dependencies flow `game/ -> modules -> kernel -> platform interfaces`.
- Static config is a `Resource`; mutable runtime state is an instance; scene-tree
  behavior is a `Node`.
- Gameplay should follow the command -> state -> action -> effect -> domain
  system -> event pipeline.
- Shared services are reached through `ServiceRegistry`; do not construct kernel
  singletons ad hoc in gameplay code.
- GDScript is strongly typed.
- `.gd` files under `addons/mkit/` are comment-free by design.

## Verification

Do not report a code change as complete until it has been verified the way the
repo expects.

```bash
make ut
make ut-kernel
make ut-modules
```

Run the narrowest relevant test while iterating, then run the appropriate suite
before finishing. If Godot is unavailable or the suite cannot run, report the
exact command attempted and the failure.

For new `.gd` scripts, run Godot or the tests so the sibling `.gd.uid` is
generated. Commit the script and generated UID together. Never hand-author UID
files.

When a public interface changes, update the relevant `docs/ref/<ClassName>.md`
and any affected layer or pipeline overview. Match the language already used in
the file: Chinese conceptual prose, English identifiers and code.
