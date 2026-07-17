# Video 1 - High-Level Class Design

## Section Goal

Build the minimum runtime foundation: a clean boot scene, a shared service
lookup point, a bootstrap class that fills it, a module boundary, and typed
helpers for reading the services back.

## What You Will Build

- `ServiceRegistry`: the autoload table that stores shared service objects by
  stable service id.
- `GameBootstrap`: the kernel startup coordinator that registers the first
  services, loads configured content, validates content, and enters the initial
  scene.
- `ModuleBootstrap`: the course boundary where built-in gameplay module services
  are added after the kernel is ready.
- `Mkit`: the typed facade that gives game and module code clearer access to
  registered services.

## Concepts Students Need First

- Concept name: Shared service
- Simple explanation: A service is a reusable runtime object that owns one job
  for the project.
- Everyday example: One classroom clock serves the whole room; each student does
  not bring a separate clock.
- How it appears in this section: `RandomService` owns shared randomness,
  `SceneService` owns scene changes, `ContentService` owns loaded definitions,
  and `EventService` owns event publishing.

- Concept name: Centralized read/write access
- Simple explanation: The project needs one place to write services during boot
  and one place to read them later.
- Everyday example: Tools go into one labeled cabinet, then anyone who needs a
  tool knows where to look.
- How it appears in this section: `ServiceRegistry` stores services by ids such
  as `"content"`, `"events"`, and `"scenes"`.

- Concept name: Startup coordinator
- Simple explanation: A startup coordinator performs the boot steps in a known
  order before gameplay begins.
- Everyday example: Before opening a shop, someone unlocks the door, turns on
  the lights, checks the register, and then lets customers in.
- How it appears in this section: `GameBootstrap` registers services, loads
  content, validates it, and enters `res://game/village_rpg_demo.tscn`.

- Concept name: Typed facade
- Simple explanation: A facade gives a simpler front door to a lower-level
  system.
- Everyday example: Instead of knowing every shelf in a warehouse, you ask the
  counter for the item by name.
- How it appears in this section: `Mkit.content()` wraps
  `ServiceRegistry.get_port(ContentService.SERVICE_ID)` and returns a
  `ContentService`.

## Class Responsibilities

| Class | Responsibility | Main capability | Does not own |
| --- | --- | --- | --- |
| `ServiceRegistry` | Keep the shared service lookup table. | Register, check, retrieve, and list service ids. | It does not create services or decide boot order. |
| `GameBootstrap` | Run the kernel startup sequence. | Register ready kernel services, load content, validate content, and enter the first scene. | It does not choose gameplay module services or store concrete game content. |
| `ModuleBootstrap` | Mark where gameplay module services extend the kernel startup. | Override `_build_services()` and append module services when those systems are introduced. | It does not teach combat, quest, shop, dialogue, world, or loot details now. |
| `Mkit` | Provide typed static accessors for registered services. | Turn low-level registry reads into readable calls such as `Mkit.content()`. | It does not create, replace, or own service instances. |

## How The Classes Work Together

`project.godot` sets `ServiceRegistry` as the only autoload and starts at
`res://game/bootstrap.tscn`. That scene uses
`res://addons/mkit/modules/module_bootstrap.gd` as its root script, so the live
project boots through `ModuleBootstrap`.

`ModuleBootstrap` inherits from `GameBootstrap`. `GameBootstrap` creates a
service map, registers each ready service through `ServiceRegistry`, loads the
configured `ResourceDatabase`, validates content, and changes to
`res://game/village_rpg_demo.tscn`. After that, gameplay code can read services
through `Mkit` typed helpers instead of touching the registry directly.

Source correction for this section: the current project does not use a separate
game-side bootstrap script file. The live boot path is `project.godot` ->
`res://game/bootstrap.tscn` ->
`res://addons/mkit/modules/module_bootstrap.gd`.

## Concrete Example

When the project starts, `ModuleBootstrap` runs inherited boot logic from
`GameBootstrap`. `GameBootstrap` registers `ContentService` under `"content"`
and `SceneService` under `"scenes"`. Later, `Mkit.content()` can retrieve the
loaded content service, and the bootstrap can use `SceneService` to enter
`res://game/village_rpg_demo.tscn`.

## High-Level Design Script

In this section, the main idea is not combat or movement yet. The main idea is
startup. Before the game can do anything interesting, it needs shared runtime
tools and a predictable way to find them.

We will build that in four small layers. First, `ServiceRegistry` gives us one
central table for writing and reading services. Then `GameBootstrap` fills that
table during startup. After that, `ModuleBootstrap` gives the project a clear
place to add gameplay module services later, and `Mkit` gives normal code typed
helper functions so it does not have to use raw string lookups everywhere.

The visible result is simple but important: the project starts from a clean boot
scene, registers the currently taught services, loads configured content, and
enters the demo scene through runtime code instead of scattered setup.

## Transition To First Class Video

We start with `ServiceRegistry`, because every later boot step depends on one
known place where services can be written and read.

## Progress Tracker

- [x] Video 1 high-level class design generated.
- [x] Video 2 `ServiceRegistry` generated.
- [x] Video 3 `GameBootstrap` generated.
- [x] Video 4 `ModuleBootstrap` generated.
- [x] Video 5 `Mkit` generated.
