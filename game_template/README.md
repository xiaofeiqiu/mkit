# Mkit Starter Template

This is the smallest game-side slice meant for copying into a new project. It is separate from `game/`, which is a full showcase demo.

## Files

| File | Purpose |
|------|---------|
| `bootstrap.tscn` | Boots through `ModuleBootstrap` and enters the starter scene |
| `starter_scene.tscn` | Minimal playable scene |
| `starter_scene.gd` | Player movement, command-routed attack, one enemy, and one quest |

## Run

Set `game_template/bootstrap.tscn` as the main scene and press F5.

Controls:

- Move: WASD or arrow keys
- Attack: Space or J

The attack dispatches a `GameCommand` through `CommandService`; the enemy emits a domain event through `EventService`; `QuestService` advances a one-objective quest from that event.
