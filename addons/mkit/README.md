# Mkit

Reusable Godot 4.7-dev 2D RPG / roguelike runtime kernel and gameplay modules.

Mkit ships as a self-contained addon under `res://addons/mkit/`. Everything
reusable lives inside this folder; game-specific content lives outside under
`res://game/` and depends on Mkit only through public APIs. Dependencies always
point inward (`game/ -> addons/mkit/`), never the reverse.

## Enabling

1. Enable the plugin in **Project > Project Settings > Plugins**. This registers
   the single `ServiceRegistry` autoload.
2. Add a `GameBootstrap` node to your bootstrap scene and configure
   `resource_databases` / `initial_scene_path` in the Inspector.
3. Put concrete scenes, content databases, entities, UI, prices, quests, shops,
   and demo rules under `res://game/` or another game-owned tree.

## Current runtime shape

`ServiceRegistry` is the only autoload. `GameBootstrap.boot()` registers all
built-in services into it, loads `ResourceDatabase` assets into
`ContentService`, validates content ids, restores a save if
`SaveService.save_path` exists, then enters `initial_scene_path`.

The current implementation has landed the large architecture cleanup around:

- typed service access via `ServiceRegistry.get_port(...)`
- `EntityContract` as the semantic entry point for entity components/controllers
- combat as `DamageRequest -> DamageIntent -> DamageResolution -> DamageApplication -> DamageResult`
- reusable mutable models such as `ResourceSet` and `Wallet`
- `SaveService` scope data and explicit scope provider registration

Each module directory carries a `module.cfg` manifest declaring its `id`,
cross-module `deps`, registered service ids, and event catalog class.
`tools/check_module_deps.py` (`make module-deps`) enforces that actual
cross-module references match the declarations and that the graph stays
acyclic.

Not yet implemented: runtime topological module loading from the manifests
(`ModuleBootstrap` still lists the built-in services explicitly). Keep docs and
game code aligned with the implemented shape above.

## Layout

```text
addons/mkit/
  plugin.cfg / plugin.gd          # addon manifest + autoload registration
  kernel/
    bootstrap/                    # GameBootstrap
    services/                     # ServiceRegistry, time/random/scene/pool/audio/platform services
    events/                       # DomainEvent, EventService
    commands/                     # GameCommand, CommandService, CommandReceiver
    context/                      # GameplayContext, Blackboard, ActionContext
    registry/                     # ContentDefinition, ContentService, ResourceDatabase
    state_machine/                # State, StateMachine
    actions/                      # GameAction, ActionService
    conditions/                   # Condition, ConditionEvaluator
    effects/                      # GameEffect, EffectService, EffectResult
    save/                         # Saveable, SaveableComponent, SaveService
    debug/                        # DebugOverlay
  modules/
    ai/ combat/ dialogue/ entity/ interaction/ inventory/
    loot/ progression/ quest/ shop/ ui/ world/
```

## Core pipeline

```text
Input / AI / Script
  -> GameCommand / CommandService / CommandReceiver
  -> StateMachine / State
  -> GameAction / ActionService
  -> GameEffect / EffectService
  -> Domain service or component
  -> EventService / DomainEvent
  -> UI / Audio / VFX / Analytics
```

For current user-facing docs, start at `res://docs/readme.md`.
