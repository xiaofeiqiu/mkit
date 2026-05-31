# Godot 2D RPG / Roguelike Mkit — Implementation Spec

This folder reorganizes the high-level architecture and detailed interface prompt into a phase-friendly implementation package for AI-assisted development.

## Start Here

- [High-Level Design Summary](architecture/high_level_design_summary.md)
- [Full High-Level Design](architecture/high_level_design.md)
- [Combined Implementation Docs](combined/README.md)

## High-Level Concept

The Mkit should be a reusable runtime framework, not a rigid game template. Game-specific content stays replaceable; reusable gameplay behavior lives in the Mkit.

```text
Mkit provides reusable mechanisms.
Game-specific code provides concrete content and rules.
```

Use the same gameplay pipeline wherever possible:

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

## Phase Implementation Plan

### Phase 0 — Kernel Prototype

Read:

- [Foundation and Folder Structure](combined/00_foundation_and_folder_structure.md)
- [Runtime Kernel](combined/01_runtime_kernel.md)
- [Content Registry](combined/02_content_registry.md)
- [HFSM and Actions](combined/03_hfsm_and_actions.md)
- [Conditions and Effects](combined/04_conditions_and_effects.md)

Validation:

```text
Create a dummy entity.
Send a command.
State changes.
Action runs.
Effect logs a result.
Debug trace shows state path and recent events.
```

### Phase 1 — Combat Vertical Slice

Read:

- [Entity, Stats, Health, and Combat](combined/05_entity_stats_health_combat.md)
- [Core Flows, MVP Plan, Debug, and Agent Instructions](combined/12_core_flows_mvp_debug_and_agent_instructions.md)

Validation:

```text
Player moves.
Player attacks.
Enemy takes damage.
Enemy dies.
Damage and death events are emitted.
```

### Phase 2 — Ability and Status Slice

Read:

- [Ability and Status Effects](combined/06_ability_and_status_effects.md)
- [Conditions and Effects](combined/04_conditions_and_effects.md)

Validation:

```text
Player casts a basic ability.
Cooldown is tracked.
Projectile or effect damages enemy.
Burn or poison ticks over time.
```

### Phase 3 — Inventory, Equipment, Loot, Reward

Read:

- [Inventory, Equipment, Loot, and Rewards](combined/07_inventory_equipment_loot_rewards.md)

Validation:

```text
Enemy or chest produces loot.
Player collects and equips an item.
Stats change through modifiers.
Reward options can be generated and applied.
```

### Phase 4 — Room, Run, Procedural Generation

Read:

- [Room, Run, and Procedural Generation](combined/08_room_run_and_generation.md)

Validation:

```text
Start a run.
Enter a generated room.
Detect room clear.
Choose reward.
Advance to the next room.
```

### Phase 5 — Save and Meta Progression

Read:

- [Save, Progression, and Platform Services](combined/11_save_and_platform_services.md)

Validation:

```text
Complete a run.
Gain currency or unlocks.
Restart game.
Persistent state restores correctly.
```

### Phase 6 — Platform Services

Read:

- [Save, Progression, and Platform Services](combined/11_save_and_platform_services.md)

Validation:

```text
Analytics, rewarded ads, purchases, and cloud-save paths use mock services first.
```

## Cross-Cutting Docs

- [AI and Interaction](combined/09_ai_and_interaction.md)
- [UI and Feedback](combined/10_ui_feedback.md)
- [Core Flows, MVP Plan, Debug, and Agent Instructions](combined/12_core_flows_mvp_debug_and_agent_instructions.md)

## Recommended AI Working Pattern

For each phase, give the implementing AI:

```text
1. This implementation_spec.md file.
2. The phase-specific combined Markdown file.
3. The current Godot project folder tree.
4. A clear validation target for the phase.
```
