# ServiceRegistry Design

## Class Identity

| Item | Value |
| --- | --- |
| Class name | `ServiceRegistry` autoload script; live source has no `class_name` declaration |
| Status | current |
| Source path | `res://addons/mkit/kernel/services/service_registry.gd` |
| Extends | `Node` |
| Section goal | Build centralized write/read access for the services used during the Section 2 boot flow. |
| Purpose | Store shared runtime service objects behind stable string ids. |

## MVP Decision

This video teaches the smallest useful registry: write a service, check whether
it exists, read it back, and list registered ids for a boot/debug check. This is
a section-local MVP decision, not a full source API judgment.

## Class Design

- Responsibility: own the service id to service object lookup table.
- Collaborators: `GameBootstrap` writes services into it; `Mkit` later reads
  from it through typed helpers.
- Runtime flow: bootstrap registers `"content"` or `"scenes"`, later code asks
  whether that id exists or retrieves the object by id.
- Does not own: service construction, service order, typed accessors, gameplay
  module selection, or concrete game content.

## MVP Scope Introduced In This Video

- Internal `_services: Dictionary` storage.
- `register_service(service_id, service)` for duplicate-safe writes.
- `has_service(service_id)` for quiet existence checks.
- `get_port(service_id)` for low-level reads.
- `get_registered_service_ids()` for stable debug or test output.

## Dependency Readiness

| Dependency | Status | Current-video decision |
| --- | --- | --- |
| `Object` | already introduced | use now as the broad service type |
| `Node` | already introduced | use now because the autoload script extends `Node` |
| `GameBootstrap` | future-section MVP | mention as the main writer, but do not implement here |
| `Mkit` | future-section MVP | mention as the typed read facade, but do not implement here |
| `RandomService`, `SceneService`, `ContentService`, `EventService` | future-section MVP | use as examples of services; do not instantiate in this video |

## Public Accessible Fields

| Field | Type | Source visibility | MVP status |
| --- | --- | --- | --- |
| None | N/A | N/A | N/A |

`_services` exists in source, but it is internal storage and should not be read
or written from outside the class.

## Public Accessible Signals

| Signal | Parameters | MVP status |
| --- | --- | --- |
| None | N/A | N/A |

## Public Accessible Functions

| Function | Returns | MVP status |
| --- | --- | --- |
| `register_service(service_id: String, service: Object)` | `bool` | MVP |
| `has_service(service_id: String)` | `bool` | MVP |
| `get_port(service_id: String)` | `Object` | MVP |
| `get_registered_service_ids()` | `Array[String]` | MVP |
| `unregister_service(service_id: String)` | `void` | future-section MVP |
| `clear()` | `void` | future-section MVP |
| `replace_service(service_id: String, service: Object)` | `bool` | non-MVP |

## Future-Section MVP

- `unregister_service(service_id)` is useful when tests or integration setup
  need to remove a service.
- Likely section: Section 11 - Save, Load, And Testing, because isolated tests
  often need registry cleanup.
- `clear()` is useful for resetting the whole registry between focused tests.
- Likely section: Section 11 - Save, Load, And Testing, because reset behavior
  belongs with test isolation.

## Non-MVP Source Behavior

- `replace_service(service_id, service)` exists for intentional overrides.
- Reason deferred: the first boot result does not need replacement behavior, and
  teaching replacement now would distract from the central write/read mechanism.

## Design Script

The core idea in `ServiceRegistry` is centralized service access. The runtime
needs one place to write services during boot and one place to read those
services later. Without that shared table, each system would either create its
own copy of a service or carry direct references through many unrelated classes.

A service is a shared runtime object with one job. `RandomService` owns shared
randomness, `SceneService` owns scene changes, `ContentService` owns loaded
content definitions, and `EventService` owns gameplay event publishing. These
are reusable runtime tools, not concrete enemies, quests, rooms, or items.

`ServiceRegistry` is the table for those tools. `GameBootstrap` writes services
into the table with stable ids like `"content"` and `"scenes"`. Later, runtime
code reads a service back by the same id, and `Mkit` can wrap that read in a
typed helper like `Mkit.content()`.

The live source is `res://addons/mkit/kernel/services/service_registry.gd`, and
it extends `Node` because Godot loads it as the `ServiceRegistry` autoload. This
class owns only the table and the safety checks around the table. It does not
create services, decide which services belong in the project, or hold concrete
game content.

For this video, we only teach the boot-path API: register, check, retrieve, and
list. The live source also supports unregistering, clearing, and replacing
services, but those are better introduced when tests or intentional overrides
become the current lesson goal.

## Public API Script

`register_service()` is used for writing one service into the registry. The
`service_id` is the lookup name, such as `"content"`, and the `service` is the
object that should be shared. It returns `true` only when the registry accepts
the write, so bootstrap can detect bad ids, null services, or duplicates.

`has_service()` is used for checking whether an id is already registered. It is
public because bootstrap and optional helpers need a quiet way to ask "is this
available?" without triggering a missing-service warning.

`get_port()` is used for reading a service object by id. It is the low-level
lookup that later facades wrap. If students call `get_port("scenes")`, they
expect the `SceneService` object that was registered under `"scenes"`.

`get_registered_service_ids()` is used for debug output and simple checks. It
returns sorted ids, so a log line or test assertion is stable and easy to read.

`unregister_service()`, `clear()`, and `replace_service()` exist in the live
source, but they are not part of this first registry lesson. They are about
resetting or overriding the table, which is mostly a testing and advanced setup
topic.

## Transition To Implementation

Now we can build the registry as a small, concrete table: first the storage,
then the write API, then the read API, and finally a tiny check.
