# Mkit

Reusable Godot 4.x 2D RPG / roguelike runtime kernel and gameplay modules.

Mkit ships as a self-contained addon under `res://addons/mkit/`. Everything
reusable lives inside this folder; game-specific content lives outside under
`res://game/` and depends on Mkit only through its public APIs. Dependencies
always point inward (`game/ -> addons/mkit/`), never the reverse.

## Enabling

1. Enable the plugin in **Project > Project Settings > Plugins** (this registers
   the single `ServiceRegistry` autoload).
2. Add a `GameBootstrap` node to your main scene and configure its
   `resource_databases` / `initial_scene_path` in the Inspector. Bootstrap
   constructs every other kernel service and registers it into `ServiceRegistry`.

## Layout (implemented so far — Phase 0: Kernel Prototype)

```text
addons/mkit/
  plugin.cfg / plugin.gd          # addon manifest + autoload registration
  kernel/
    bootstrap/game_bootstrap.gd   # startup orchestrator
    services/                     # service_registry, random, time, scene_router, object_pool
    events/                       # domain_event, event_router
    commands/                     # game_command, builtin_commands, command_receiver, command_router
    context/                      # gameplay_context, blackboard, action_context
    registry/                     # resource_database, content_registry, content_validation_result
    state_machine/                # state, state_machine (HFSM with LCA transitions)
    actions/                      # game_action, action_runner, builtin/{dash,cast}
    conditions/                   # condition, condition_evaluator, builtin/target_in_range
    effects/                      # game_effect, effect_executor, effect_result, builtin/log_effect
    debug/                        # debug_overlay
```

Later phases add the `modules/` (entity, stats, health, combat, abilities,
inventory, rooms, run, ...) and `platform/` layers. See
`spec/implementation_spec.md` and `PROGRESS.md` at the project root for the plan
and current status.

## Core pipeline

```text
Input / AI / Script
  -> GameCommand
  -> CommandRouter / CommandReceiver
  -> HFSM (StateMachine / State)
  -> GameAction (ActionRunner)
  -> GameEffect (EffectExecutor)
  -> Domain System
  -> EventRouter
  -> UI / Audio / VFX / Analytics
```
