---
name: mkit-dev
description: >-
  Engineering playbook for developing and maintaining the mkit Godot 4.7 /
  GDScript 2.0 game framework (a layered kernel + reusable gameplay modules for
  2D RPG / roguelike games). Use this whenever working inside the mkit repo:
  adding or changing a gameplay system, module, action, effect, command,
  condition, entity, or service; writing or running GUT unit tests; updating
  docs/ref or specs; or reviewing a change for architecture / layering
  violations. Trigger even when the request never says "mkit" but it touches
  addons/mkit/, game/, GDScript (.gd / .tscn) files, the
  command -> action -> effect pipeline, ServiceRegistry, the
  Definition -> Instance -> Controller data model, or the "no hardcoded game
  content in the addon" rule. When in doubt while editing this repo, consult
  this skill rather than guessing the conventions.
---

# Developing and maintaining mkit

Mkit is **not a game** — it is a reusable Godot 4.7 (GDScript 2.0) runtime kernel
plus gameplay modules, shipped as a self-contained addon under
`res://addons/mkit/`. Concrete games are built *on top of* it. Almost everything
that feels like a "rule" here exists to protect one property: **the addon stays
reusable across many different RPG/roguelike games.** Keep that goal in mind and
most of the conventions explain themselves.

This skill is the map. The detail lives in four reference files — read the one
that matches your task instead of loading everything:

| Your task | Read |
|-----------|------|
| Understand layers, pipeline, data model, folder map, entity layout | `references/architecture.md` |
| Add or extend a gameplay system the mkit way | `references/adding-a-system.md` |
| Write or run tests, debug a failing test | `references/testing.md` |
| Match code style, handle `.uid` files, update docs | `references/conventions.md` |

You usually don't need all four. But before you write code, skim the relevant
`spec/combined/NN_*.md` design doc — the spec is the source of truth the
implementation follows, and it explains intent the code alone won't.

## Orient yourself before editing

A few minutes of orientation prevents the most common mistakes (wrong layer,
duplicated mechanism, broken convention):

1. **Find the layer you're in.** `addons/mkit/kernel/` (runtime foundation) →
   `addons/mkit/modules/` (gameplay domains) → `game/` (concrete content).
   Dependencies only point downward/inward. See `references/architecture.md`.
2. **Search for the existing mechanism first.** Mkit already has commands,
   actions, effects, conditions, a content registry, an HFSM, services, save,
   pooling. New behavior is usually a *new data definition or a new
   action/effect/condition*, not a new bespoke system. Grep `addons/mkit/`
   before inventing anything.
3. **Read the matching spec.** `spec/implementation_spec.md` maps phases to
   slices; `spec/combined/00..12_*.md` carry the design (bilingual — Chinese
   concept prose, English identifiers). `spec/test-spec/` documents each test.

## The invariants that matter most

These are the things most likely to be silently violated. Internalize the *why*
so you can apply judgment, not just follow rules.

- **Never hardcode concrete game content in the addon.** A specific boss, item,
  room, drop table, ad-revive economy, or shop price must never appear in
  `addons/mkit/`. The addon exposes generic, data-driven *mechanisms*
  (`AbilityDefinition`, `ItemDefinition`, `LootTableDefinition`, `RewardOption`,
  …); the concrete values live in `game/` as Resources. If you catch yourself
  typing a proper noun like `Goblin` or `Fireball` inside the addon, it belongs
  in `game/` instead. This is the single rule that keeps mkit reusable.

- **Dependencies flow one way: `game/ → modules → kernel → platform interfaces`.**
  Never add a reverse edge — the addon importing from `game/`, or the kernel
  reaching up into a module. If the kernel needs a capability, it depends on an
  *abstract interface* (e.g. `AnalyticsService`) and the concrete
  implementation is injected at bootstrap.

- **Resource / Instance / Node split.** Static config is a `Resource`
  (`*Definition`), mutable runtime state is a plain object instance, scene-tree
  behavior is a `Node`. The recurring shape is
  `Definition -> Instance -> Controller/Component -> System/Resolver`. Don't
  collapse these (e.g. don't put mutable run state on a Resource — Resources are
  shared and serialized).

- **Route gameplay through the one pipeline** rather than wiring systems
  directly: `Input/AI/Script -> GameCommand -> CommandRouter/CommandReceiver ->
  HFSM -> GameAction -> GameEffect -> Domain System -> EventRouter -> UI/Audio/
  VFX/Analytics`. Following the chain is what keeps systems decoupled and
  testable. See `references/architecture.md` for where to hook in.

- **Reach shared services through `ServiceRegistry`,** the only autoload, by
  string id — never construct kernel singletons ad hoc in gameplay code:
  ```gdscript
  var router := ServiceRegistry.get_service("commands") as CommandRouter
  ```
  Ids: `events`, `content`, `random`, `time`, `actions`, `effects`, `commands`,
  `scenes`, `pool`, `save`, `progression`, `analytics`, `ads`, `iap`,
  `cloud_save`. They're built and registered in
  `addons/mkit/kernel/bootstrap/game_bootstrap.gd` — a *new* kernel service is
  added there.

- **Strongly-typed, comment-free GDScript 2.0.** Core files use
  `class_name Xxx` / `extends XxxBase` and type every var, param, and return.
  All 108 addon `.gd` files contain **zero comments** by design — names and
  types carry the meaning, and `tools/strip_comments.py` enforces it. Match that
  style; do not add explanatory comments to addon code. Details in
  `references/conventions.md`.

## Definition of done

A change isn't finished until it's verified the way the repo expects. Don't
report success on unverified work.

- **Tests pass.** Run the relevant suite and paste the real result:
  ```bash
  make ut            # full suite (kernel + modules)
  make ut-kernel     # kernel only
  make ut-modules    # modules only
  ```
  New or changed behavior in the addon should ship with a GUT test under
  `test/unit/` and, ideally, a matching `spec/test-spec/` doc. The engine binary
  is set via the `GODOT` env var (this is a Godot **4.7-dev** project — point
  `GODOT` at a matching build). See `references/testing.md` for single-test
  commands and the `test_tc_<area>_<nn>_<desc>` naming convention.

- **`.uid` files exist for new scripts.** Godot generates a `<file>.gd.uid` on
  import; these are committed alongside the script and scenes reference scripts
  by UID. After creating a `.gd`, run `make ut` (or load the project headless)
  so Godot writes the `.uid`, then commit both. Never hand-author a UID. More in
  `references/conventions.md`.

- **Docs stay in sync** when you change a public interface. Update the relevant
  `docs/ref/<ClassName>.md` and any affected layer/pipeline doc, matching the
  language already in that file (Chinese concept sections stay Chinese; code and
  identifiers stay English). See `references/conventions.md`.

- **Layering held.** Before finishing, sanity-check that you added no upward
  dependency and no concrete game content inside `addons/mkit/`.
