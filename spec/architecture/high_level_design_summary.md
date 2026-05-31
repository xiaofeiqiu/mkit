# High-Level Design Summary

This Mkit is a reusable Godot 4.x foundation for 2D RPG, roguelike, roguelite, action RPG, dungeon crawler, and survivor-like games.

The central idea is to keep game-specific content replaceable while keeping runtime behavior reusable. Static definitions live in Resources, mutable runtime state lives in instances, and scene-tree behavior lives in Nodes.

## Architecture Layers

```text
Game Layer
  -> Gameplay Modules Layer
  -> Runtime Kernel Layer
  -> Platform / Infrastructure Layer
```

Dependencies flow downward. The Mkit can expose generic concepts such as commands, effects, conditions, ability definitions, item definitions, room definitions, run state, and reward options. It must not hardcode concrete game content such as a specific boss, item, room, story beat, ad economy, or shop pricing rule.

## Core Runtime Pipeline

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

## Core Data Model

```text
Definition Resource
  -> Runtime Instance
  -> Controller / Component
  -> System / Resolver
```

## Implementation Strategy

Build vertical slices instead of finishing every system in isolation. The first production-quality milestone should prove player movement, attack, enemy damage/death, loot or reward, run advancement, and visible debug state.
