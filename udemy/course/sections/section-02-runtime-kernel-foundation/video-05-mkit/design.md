# Mkit Design

## Class Identity

| Item | Value |
| --- | --- |
| Class name | `Mkit` |
| Status | current |
| Source path | `res://addons/mkit/modules/mkit.gd` |
| Extends | `RefCounted` |
| Section goal | Give game and module code typed access to the services registered in the Section 2 boot flow. |
| Purpose | Wrap low-level registry reads in clear typed static functions. |

## MVP Decision

This video teaches `Mkit` as a typed facade for services already introduced or
registered in the staged course boot flow. The live source has accessors for
many later services; those are classified as future-section MVP.

## Class Design

- Responsibility: provide readable typed static accessors for registered
  services.
- Collaborators: `ServiceRegistry` and the service classes returned by each
  accessor.
- Runtime flow: gameplay code calls `Mkit.content()` or `Mkit.scenes()`, and
  the facade reads the matching object from `ServiceRegistry`.
- Does not own: service creation, registration order, replacement, lifecycle, or
  concrete game content.

## MVP Scope Introduced In This Video

- `class_name Mkit`.
- `extends RefCounted`.
- Static accessors for Section 2 ready services:
  `events()`, `content()`, `random()`, `time()`, and `scenes()`.

## Dependency Readiness

| Dependency | Status | Current-video decision |
| --- | --- | --- |
| `ServiceRegistry` | already introduced | use now |
| `EventService` | ready support | expose now |
| `ContentService` | ready support | expose now |
| `RandomService` | ready support | expose now |
| `TimeService` | ready support | expose now |
| `SceneService` | ready support | expose now |
| Later kernel and module services | future-section MVP | defer accessors until those systems are taught |

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
| `events()` | `EventService` | MVP |
| `content()` | `ContentService` | MVP |
| `random()` | `RandomService` | MVP |
| `time()` | `TimeService` | MVP |
| `scenes()` | `SceneService` | MVP |
| `actions()` | `ActionService` | future-section MVP |
| `effects()` | `EffectService` | future-section MVP |
| `commands()` | `CommandService` | future-section MVP |
| `pool()` | `PoolService` | future-section MVP |
| `save()` | `SaveService` | future-section MVP |
| `audio()` | `AudioService` | future-section MVP |
| `combat()` | `CombatService` | future-section MVP |
| `progression()` | `ProgressionService` | future-section MVP |
| `quest()` | `QuestService` | future-section MVP |
| `shop()` | `ShopService` | future-section MVP |
| `dialogue()` | `DialogueService` | future-section MVP |
| `world()` | `WorldService` | future-section MVP |
| `loot()` | `LootService` | future-section MVP |
| `death_loot()` | `DeathLootService` | future-section MVP |
| `ui()` | `UIManager` | future-section MVP |

## Future-Section MVP

- `commands()` becomes useful when command routing is taught.
- Likely section: Section 3 - Entity, Command, And State Machine.
- `actions()` and `effects()` become useful when the action/effect pipeline is
  taught.
- Likely section: Section 4 - Action And Effect Pipeline.
- `combat()`, `progression()`, `quest()`, `shop()`, `dialogue()`, `world()`,
  `loot()`, and `death_loot()` become useful when those module systems are
  visible in gameplay.
- Likely sections: Section 5 through Section 10.
- `audio()`, `pool()`, and `ui()` become useful when feedback and presentation
  systems are connected.
- Likely section: Section 7 - Events, UI, Audio, And VFX.
- `save()` becomes useful when persistence is taught.
- Likely section: Section 11 - Save, Load, And Testing.

## Non-MVP Source Behavior

- `_get_optional_port(service_id)` exists in source for optional service reads
  such as `ui()`.
- Reason deferred: optional service lookup should be taught when optional UI
  services are introduced.

## Design Script

The core idea in `Mkit` is typed service access. The key noun is facade: a small
front-facing API that hides a lower-level lookup. Here, the lower-level lookup
is `ServiceRegistry.get_port(...)`.

The registry is flexible, but it returns `Object`. That is useful at the kernel
level, but normal game code is easier to read when it can call `Mkit.content()`
and get a `ContentService`, or `Mkit.scenes()` and get a `SceneService`. The
facade keeps the central registry while giving students clearer typed calls.

The live source is `res://addons/mkit/modules/mkit.gd`, and it extends
`RefCounted` because it is just a static helper class, not a scene node. It does
not create services and it does not decide boot order. It only reads services
that `GameBootstrap` and `ModuleBootstrap` registered earlier.

For this section, we expose only the services that are ready in the course boot
flow: events, content, random, time, and scenes. The live source also exposes
actions, effects, commands, save, audio, combat, quest, loot, UI, and more, but
those accessors are better taught when the systems behind them are visible.

## Public API Script

`events()` is used for retrieving the shared `EventService`. In later lessons,
events will connect gameplay to UI, audio, VFX, quests, and tests.

`content()` is used for retrieving the shared `ContentService`. This is the
service bootstrap fills from `ResourceDatabase` assets.

`random()` is used for retrieving the shared `RandomService`. The point is that
gameplay systems can share one random source instead of each system inventing
its own.

`time()` is used for retrieving the shared `TimeService`. It gives systems one
place to read runtime time behavior.

`scenes()` is used for retrieving the shared `SceneService`. Bootstrap uses
scene routing to leave the boot scene and enter the game scene.

The other live accessors are real, but they are future-section MVP. We do not
teach `combat()` before combat exists, or `quest()` before quests exist, because
typed helpers only make sense when students can see the service's job.

## Transition To Implementation

Now we will implement the facade as a small set of static functions. Each
function reads one ready service from `ServiceRegistry` and casts it to the
right type.
