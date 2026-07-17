# GameBootstrap Design

## Class Identity

| Item | Value |
| --- | --- |
| Class name | `GameBootstrap` |
| Status | current |
| Source path | `res://addons/mkit/kernel/bootstrap/game_bootstrap.gd` |
| Extends | `Node` |
| Section goal | Coordinate the minimum boot flow that registers ready services, loads configured content, validates it, and enters the initial scene. |
| Purpose | Act as the kernel startup coordinator for a game project. |

## MVP Decision

This video teaches `GameBootstrap` as the boot sequence owner. The course MVP
registers only services needed for the Section 2 result and defers later
services even though the live source already contains a larger production map.

## Class Design

- Responsibility: own the order of the startup steps.
- Collaborators: `ServiceRegistry`, `EventService`, `ContentService`,
  `RandomService`, `TimeService`, `SceneService`, `ResourceDatabase`, and the
  configured initial scene path.
- Runtime flow: `_ready()` calls `boot()`, `boot()` registers services, loads
  content, validates it, and enters the initial scene.
- Does not own: gameplay module service selection, concrete content resources,
  save data, audio setup, combat, quests, loot, or UI.

## MVP Scope Introduced In This Video

- Exported `resource_databases`.
- Exported `initial_scene_path`.
- `_ready()` as the Godot entry point.
- `boot()` as the readable startup sequence.
- `_build_services()` as the subclass hook that returns a staged service map.
- Private helper behavior for registering service entries, loading content,
  validating content, and entering the initial scene.

## Dependency Readiness

| Dependency | Status | Current-video decision |
| --- | --- | --- |
| `ServiceRegistry` | already introduced | use now |
| `EventService` | ready support | register now as a simple shared service example |
| `ContentService` | ready support | register now because content loading is part of the boot result |
| `RandomService` | ready support | register now as a simple shared runtime tool |
| `TimeService` | ready support | register now as a simple shared runtime tool |
| `SceneService` | ready support | register now for initial scene entry |
| `ResourceDatabase` | ready support | use now as boot configuration |
| `SaveService`, `AudioService`, `ActionService`, `EffectService`, `CommandService`, `PoolService` | future-section MVP | defer from implementation snippets |

## Public Accessible Fields

| Field | Type | Source visibility | MVP status |
| --- | --- | --- | --- |
| `resource_databases` | `Array[ResourceDatabase]` | exported | MVP |
| `initial_scene_path` | `String` | exported | MVP |
| `save_path` | `String` | exported | future-section MVP |

## Public Accessible Signals

| Signal | Parameters | MVP status |
| --- | --- | --- |
| None | N/A | N/A |

## Public Accessible Functions

| Function | Returns | MVP status |
| --- | --- | --- |
| `_ready()` | `void` | MVP |
| `boot()` | `void` | MVP |
| `_build_services()` | `Dictionary` | MVP |

## Future-Section MVP

- `save_path` and `_load_profile()` become useful when save/load is taught.
- Likely section: Section 11 - Save, Load, And Testing.
- `AudioService` registration and audio-definition configuration become useful
  when feedback is connected to presentation.
- Likely section: Section 7 - Events, UI, Audio, And VFX.
- `ActionService`, `EffectService`, and `CommandService` become useful when the
  action/effect and command pipelines are introduced.
- Likely sections: Section 3 and Section 4.
- `PoolService` becomes useful when VFX, projectiles, or spawned scenes need
  reuse.
- Likely sections: Section 7 or later performance/polish work.

## Non-MVP Source Behavior

- `_notify_services_ready()` and `_service_node_name()` exist to support the
  production registration lifecycle.
- Reason deferred: the first course version can register the ready services
  without teaching service-ready callbacks or child node naming.
- `_is_same_scene_as_self()` and `_normalize_scene_path()` protect the
  production bootstrap from scene reload loops and `uid://` paths.
- Reason deferred: useful safety behavior, but not the core concept for the
  first boot-coordinator lesson.

## Design Script

The core idea in `GameBootstrap` is ordered startup. A project should not enter
the playable scene before the shared services and content registry are ready.
The key noun here is boot step: a small startup action that must happen in a
known order.

In this course MVP, the important boot steps are: register ready services, load
configured `ResourceDatabase` assets into `ContentService`, validate the loaded
content, and enter `initial_scene_path`. For example, `ContentService` must
exist before content can load, and `SceneService` must exist before the bootstrap
can ask the runtime to change scenes.

`GameBootstrap` is the class that owns that order. The live source is
`res://addons/mkit/kernel/bootstrap/game_bootstrap.gd`, and it extends `Node`
because it sits on the bootstrap scene. It talks to `ServiceRegistry`, but it is
not the registry itself. It creates or configures services, then asks the
registry to store them.

This class deliberately does not own gameplay module choices. That belongs to
`ModuleBootstrap`, which extends this class. It also does not own concrete game
content; the scene config points it at `ResourceDatabase` assets under `game/`.

The live source already contains save loading, audio definition registration,
and a larger service list. In the course implementation, we stage those later
because the Section 2 result only needs the boot sequence and the currently
taught services.

## Public API Script

`resource_databases` is used for telling bootstrap which content databases to
load. It is exported because the boot scene configures it in the inspector. In
the live demo, `res://game/bootstrap.tscn` points at
`res://game/resources/village_rpg_content.tres`.

`initial_scene_path` is used for telling bootstrap where gameplay starts after
the runtime is ready. It is exported because a project should be able to change
the first playable scene without changing the bootstrap code.

`_ready()` is used by Godot to start the boot flow when the bootstrap node
enters the scene tree. We keep it small: it simply calls `boot()`.

`boot()` is used for reading the startup sequence from top to bottom. It should
feel like a checklist: register services, load content, validate content, enter
the first scene.

`_build_services()` is used as the service-map hook. `GameBootstrap` returns the
kernel services it knows how to create, and `ModuleBootstrap` can override the
same hook to add module services later.

`save_path` exists in the live source, but it is future-section MVP. We defer it
because persistence should be taught when students can see save/load behavior.

## Transition To Implementation

Now we will build the boot checklist in small steps: exported scene config,
the `boot()` sequence, a staged service map, and the first scene handoff.
