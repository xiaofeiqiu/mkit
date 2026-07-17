# Mkit

Reusable Godot 4.6.3 stable 2D RPG / roguelike runtime kernel and gameplay modules.

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
- combat as `DamageRequest -> DamageResult` resolved in one step by `CombatService`
- reusable mutable models such as `ResourceSet` and `Wallet`
- `SaveService` scope data and explicit scope provider registration

`ModuleBootstrap` still lists the built-in gameplay services explicitly. There
is no runtime module graph loader or module manifest layer in the current
implementation.

Mkit intentionally keeps the current runtime boundary small. The addon does not
provide a second service-port container, an event DSL/catalog compiler, a
generic save migration framework, or an ECS/component registry that replaces the
`EntityRoot` / `EntityContract` scene contract.

## Layout

```text
addons/mkit/
  plugin.cfg / plugin.gd          # addon manifest + autoload registration
  kernel/
    bootstrap/                    # GameBootstrap
    services/                     # ServiceRegistry, time/random/scene/pool/audio services
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
  -> GameCommand / CommandReceiver
  -> optional CommandService routing when the caller only knows target_id
  -> StateMachine / State
  -> GameAction / ActionService
  -> GameEffect / EffectService
  -> Domain service or component
  -> EventService / DomainEvent
  -> UI / Audio / VFX
```

For current user-facing docs, start at `res://docs/readme.md`.
