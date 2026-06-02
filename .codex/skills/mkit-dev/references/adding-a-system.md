# Adding or extending a system the mkit way

A recipe for building new behavior without breaking the grain. The golden rule:
**most "new features" are not new systems** — they are a new data definition, or
a new action / effect / condition that composes the mechanisms mkit already has.
Reach for a bespoke system only when no existing seam fits.

## Contents
- [Step 0: decide what you're actually adding](#step-0-decide-what-youre-actually-adding)
- [Add a new effect](#add-a-new-effect)
- [Add a new action](#add-a-new-action)
- [Add a new condition](#add-a-new-condition)
- [Add a new command + state handling](#add-a-new-command--state-handling)
- [Add a new domain system (Definition -> Instance -> Controller)](#add-a-new-domain-system)
- [Add a new kernel service](#add-a-new-kernel-service)
- [Add game content (no addon edits)](#add-game-content)

## Step 0: decide what you're actually adding

Walk down this list and stop at the first match — it tells you the smallest
correct change:

1. **A concrete piece of content** (a specific enemy, item, room, drop table,
   price)? → It's a Resource in `game/`, not addon code. Jump to
   [Add game content](#add-game-content).
2. **An atomic state change** (deal damage, heal, grant X, apply status, spawn)?
   → [a GameEffect](#add-a-new-effect).
3. **A gate** ("only if cooldown ready / in range / has resource")? →
   [a Condition](#add-a-new-condition).
4. **A time-extended behavior** (windup → active → recovery, channel, dash)? →
   [a GameAction](#add-a-new-action).
5. **A new intent** the player/AI/script can issue? →
   [a Command + state handling](#add-a-new-command--state-handling).
6. **A genuinely new domain rule with its own data + runtime state** (a new
   resource type, a crafting system)? → [a domain system](#add-a-new-domain-system).
7. **A new shared, app-wide capability** (a new service every system can reach)?
   → [a kernel service](#add-a-new-kernel-service).

Before writing anything, grep `addons/mkit/` and read the closest existing
sibling — the fastest way to stay consistent is to copy the shape of the nearest
neighbor. Then read the matching `spec/combined/NN_*.md` section.

## Add a new effect

Effects are atomic state changes executed by `EffectExecutor`. Built-ins live in
`addons/mkit/kernel/effects/builtin/` (`deal_damage_effect.gd`, `heal_effect.gd`,
`grant_item_effect.gd`, `apply_status_effect.gd`, `spawn_scene_effect.gd`, …) —
read one as a template.

1. Create `addons/mkit/kernel/effects/builtin/<name>_effect.gd`:
   ```gdscript
   class_name <Name>Effect
   extends GameEffect


   func execute(context: ActionContext) -> EffectResult:
       var result := EffectResult.new()
       # read typed inputs off the effect's own fields / the context
       # perform the atomic change via the relevant domain system
       return result
   ```
2. Keep it generic: an effect names a *mechanism* (deal damage), never a piece of
   content (deal 30 fire damage to the Goblin King). Parameters come from data.
3. Add a GUT test under `test/unit/kernel/` (see `references/testing.md`).
4. Generate the `.uid` (`make ut` once) and add a `docs/ref/<Name>Effect.md` if
   it has a public interface worth documenting.

## Add a new action

Actions are time-extended behaviors driven by `ActionRunner.update`. Built-ins:
`addons/mkit/kernel/actions/builtin/` (`timed_attack_action.gd`,
`dash_action.gd`, `cast_action.gd`). They typically progress through phases and
emit a completion signal, applying effects at the right moment.

1. Create `addons/mkit/kernel/actions/builtin/<name>_action.gd`:
   ```gdscript
   class_name <Name>Action
   extends GameAction


   func start(context: ActionContext) -> void:
       ...

   func update(delta: float, context: ActionContext) -> void:
       # advance phase; when done, mark complete so ActionRunner releases it
       ...
   ```
2. Apply state changes by emitting effects through `EffectExecutor`, not by
   poking domain systems directly — that's what keeps the action reusable.
3. Test + `.uid` + doc as above.

## Add a new condition

Conditions are pure predicates evaluated by `ConditionEvaluator`. Built-ins:
`addons/mkit/kernel/conditions/builtin/` (`cooldown_ready_condition.gd`,
`target_in_range_condition.gd`).

```gdscript
class_name <Name>Condition
extends Condition


func evaluate(context: GameplayContext) -> bool:
    return ...   # no side effects — just read state and answer
```

Conditions must be side-effect free; they gate behavior, they don't cause it.

## Add a new command + state handling

A command expresses an intent; the HFSM decides what to do with it.

1. If a new command *type* is needed, follow `kernel/commands/` and
   `builtin_commands.gd`. Commands are created with explicit typed payload
   wrappers — avoid passing bare `Dictionary` through core APIs.
2. Dispatch: `var router := ServiceRegistry.get_service("commands") as CommandRouter`
   then `router.dispatch(cmd)`.
3. Handle it in the relevant `State.handle_command`, transitioning to the state
   that owns the behavior (see `game/demo/entities/*/states/` for examples of
   states that start actions on enter).

## Add a new domain system

Use the full `Definition -> Instance -> Controller/Component -> System` shape only
when the feature has its own static config *and* its own mutable runtime state.
Model it on an existing module (e.g. `modules/abilities/` or `modules/inventory/`):

1. `<feature>_definition.gd` — `class_name <Feature>Definition extends Resource`,
   the static, serializable config. Lives in the addon; concrete instances live
   in `game/`.
2. `<feature>_instance.gd` — mutable per-entity runtime state.
3. `<feature>_controller.gd` (a Node under the entity's `Controllers/`) or a
   `<feature>_system.gd` / `<feature>_resolver.gd` — orchestration / rules.
4. Wire it into the pipeline (command/action/effect/event) instead of calling it
   from unrelated systems. Emit domain events through `EventRouter` so UI/audio/
   analytics can react without coupling.
5. Place files under a new `addons/mkit/modules/<feature>/` folder, keep the
   layer's dependency direction, add tests + a `spec/test-spec/` doc + docs/ref.

## Add a new kernel service

A service is a shared capability reachable app-wide via the registry.

1. If it abstracts a platform/SDK, define the **interface** in
   `kernel/services/<name>_service.gd` and a **mock**
   `<name>_service_mock.gd` (follow the analytics/ads/iap/cloud_save pair).
2. Register it in `kernel/bootstrap/game_bootstrap.gd._register_kernel_services()`:
   construct it, `add_child` if it's a Node, name it, then
   `ServiceRegistry.register_service("<id>", svc)`.
3. Callers fetch it by id; never construct it themselves. Real SDKs are wired by
   swapping the implementation at bootstrap, leaving the interface and callers
   untouched.

## Add game content

Concrete content is **data**, authored as Resources under `game/`, loaded by
`ContentRegistry` via a `ResourceDatabase` listed on the `GameBootstrap` node. No
addon code changes — that's the whole point. A new boss is an `EntityDefinition`
(+ scene) in `game/`; a new item is an `ItemDefinition`; a new drop is a
`LootTableDefinition`. If authoring the content seems to *require* editing the
addon, that's a signal the addon is missing a generic mechanism — add the
mechanism generically, then author the content in `game/`.
