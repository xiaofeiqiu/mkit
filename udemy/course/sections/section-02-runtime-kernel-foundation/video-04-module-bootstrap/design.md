# ModuleBootstrap Design

## Class Identity

| Item | Value |
| --- | --- |
| Class name | `ModuleBootstrap` |
| Status | current |
| Source path | `res://addons/mkit/modules/module_bootstrap.gd` |
| Extends | `GameBootstrap` |
| Section goal | Create the extension point where built-in gameplay module services can be added after the kernel services. |
| Purpose | Separate kernel startup from gameplay module startup. |

## MVP Decision

This video teaches the module boundary and override shape, not the details of
combat, quests, shops, dialogue, world, or loot. The live source appends all
module services, but the course implementation keeps those additions deferred
until their systems become current lessons.

## Class Design

- Responsibility: extend `GameBootstrap`'s service map from the modules layer.
- Collaborators: `GameBootstrap`, `ServiceRegistry`, and later module services
  such as `CombatService`, `QuestService`, and `LootService`.
- Runtime flow: `game/bootstrap.tscn` uses `ModuleBootstrap`; inherited `boot()`
  calls the overridden `_build_services()`.
- Does not own: kernel service registration internals, content databases,
  scene entry, or individual gameplay system behavior.

## MVP Scope Introduced In This Video

- `class_name ModuleBootstrap`.
- `extends GameBootstrap`.
- `_build_services()` override that calls `super()` and returns the service map.
- Explanation of where module services are added later.

## Dependency Readiness

| Dependency | Status | Current-video decision |
| --- | --- | --- |
| `GameBootstrap` | already introduced | extend now |
| `ServiceRegistry` | already introduced | inherited boot flow uses it |
| `CombatService`, `ProgressionService`, `QuestService`, `ShopService`, `DialogueService`, `WorldService`, `LootService`, `DeathLootService` | future-section MVP | name as live source behavior, defer implementation snippets |

## Public Accessible Fields

| Field | Type | Source visibility | MVP status |
| --- | --- | --- | --- |
| None | N/A | N/A | N/A |

## Public Accessible Signals

| Signal | Parameters | MVP status |
| --- | --- | --- |
| None | N/A | N/A |

## Public Accessible Functions

| Function | Returns | MVP status |
| --- | --- | --- |
| `_build_services()` | `Dictionary` | MVP |

## Future-Section MVP

- Add `CombatService` when combat resolution becomes visible.
- Likely section: Section 5 - Combat System.
- Add `ProgressionService`, `QuestService`, `ShopService`, and
  `DialogueService` when NPC, quest, shop, and progression behavior become
  visible.
- Likely section: Section 9 - Quest And Dialogue and nearby economy lessons.
- Add `WorldService`, `LootService`, and `DeathLootService` when room, world,
  loot, and reward flow become visible.
- Likely sections: Section 8 and Section 10.

## Non-MVP Source Behavior

- The live source appends every built-in module service immediately.
- Reason deferred: Section 2 should teach the extension point without asking
  students to understand module systems they have not built yet.

## Design Script

The core idea in `ModuleBootstrap` is layer extension. The kernel boot class
should know how to start the runtime foundation, but it should not need to know
every gameplay module forever. The key noun is module: a reusable gameplay
domain such as combat, quest, dialogue, world, or loot.

The current live source uses `ModuleBootstrap` from `res://game/bootstrap.tscn`,
so the demo does boot through this class. Its source path is
`res://addons/mkit/modules/module_bootstrap.gd`, and it extends
`GameBootstrap`. That means it inherits the whole boot sequence, then changes
only the service map hook.

This is a clean boundary for students. `GameBootstrap` says, "here is how boot
works." `ModuleBootstrap` says, "for a project that wants MKit's gameplay
modules, add those services here." It is like adding optional toolboxes after
the workshop itself is open.

For the course MVP, we do not implement the full production module list in this
video. Combat, quests, shop, dialogue, world, loot, and death loot are real
services, but they should become code when students can see what each service
does in gameplay.

## Public API Script

`_build_services()` is used for extending the service map. It is an override
hook: `GameBootstrap` calls it during boot, and `ModuleBootstrap` can add module
entries before the map is registered.

The important line is `var services := super()`. That keeps the kernel services
from `GameBootstrap` and gives the subclass a map it can extend. In this
section's implementation, we return that map unchanged so the boundary exists
without forcing later systems into this lesson.

The live source adds services like `CombatService` and `LootService` here. We
defer those entries because an accessor is not useful until students understand
the system behind it.

## Transition To Implementation

Now we will implement the smallest useful module bootstrap: inherit the kernel
boot flow, override the service-map hook, and confirm the boot scene uses this
class.
