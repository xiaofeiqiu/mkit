# Section Detailed Design Guide

This document is a **guide for generating section detailed designs** from
`udemy/README.md`. It also contains source-derived section scope seeds that
future generated designs must respect.

It is not a section detailed design. It must not contain the concrete design for
any specific section folder, read-aloud lesson, demo walkthrough, or full class
implementation plan.

## Progress Tracker

- [x] Define the source-of-truth workflow.
- [x] Define the guide-only boundary.
- [x] Define the required section detailed design output structure.
- [x] Define the high-level class design requirements.
- [x] Define the one-class-per-video rule.
- [x] Define section-goal scoping for generated class videos.
- [x] Define incremental class introduction rules.
- [x] Define FSM-first state machine teaching rules.
- [x] Define source-derived section scope seeds from `udemy/README.md`.
- [x] Define section-folder and class-folder hierarchy.
- [x] Define optional coverage boundaries.
- [x] Define script writing rules.
- [x] Define generated content organization rules.
- [ ] Generate concrete section detailed designs only when explicitly requested.

## Guide-Only Boundary

This document must stay generic.

Allowed content:

- rules for generating section detailed designs;
- source-derived section scope seeds that constrain future generated designs;
- templates with placeholders;
- checklists;
- workflow steps;
- quality bars;
- examples of wording style using placeholders.

Not allowed in this guide:

- concrete section plans;
- full production class contracts with implementation steps for real classes;
- real per-video implementation plans;
- full read-aloud scripts for real classes;
- project-specific class relationship diagrams;
- full generated source-check reports for a specific section.

If a future task needs the concrete design for a section, create a separate
section design document for that section. The source-derived scope seeds in this
guide are allowed because they define boundaries for future generation. They are
not a substitute for full section folders, scripts, demos, or tests.

## Source Of Truth Rule

Use this priority order when generating a concrete section detailed design:

1. Current source code and scenes.
2. Current runtime docs and generated API docs.
3. `udemy/README.md`.
4. Older planning notes or chat context.

`udemy/README.md` defines section intent. The live repository defines
implementation truth.

When generating a concrete section design:

1. Read the target section in `udemy/README.md`.
2. Inspect the current source files for each class or artifact that will appear
   in that section.
3. Use live class names, paths, `extends`, exported fields, public state,
   signals, and public functions.
4. If README wording disagrees with live source, use live source and record the
   mismatch in that generated section design.
5. If a class is planned but not implemented, mark it as `planned`.
6. Keep reusable addon/framework code separate from game-specific examples.

## Generation Workflow

When asked to generate a concrete section detailed design:

1. Identify the requested section.
2. Read only the relevant section from `udemy/README.md`.
3. Extract the section goal, visible result, and named classes or artifacts.
4. Inspect current source files for those classes or artifacts.
5. Use the section goal and visible result to shrink the scope for every class
   video.
6. Decide which classes are required and which are optional.
7. Create a separate section design folder.
8. Keep the generated section design focused on that section only.
9. Run a markdown sanity check for every generated file.

Do not generate all section designs unless the user explicitly asks for all of
them.

## Section Goal Scope Rule

The current source shows the full implementation truth. The target section goal
decides how much of that implementation should be introduced in this section.

When generating a concrete class video:

1. Restate the target section goal and student-visible result before choosing
   the class scope.
2. Identify the smallest useful version of the class that helps produce that
   section result.
3. Include only the fields, signals, functions, and helpers needed for that
   section's goal.
4. If the live class already contains behavior for later sections, record that
   behavior as `Later section` or `Out of scope for this video`.
5. Do not implement the full current production class just because the source
   file already has it.

The generated design may still mention the full current source path and class
name. It must separate:

- current source truth;
- what this section introduces;
- what later sections will add.

Good scope statement:

```text
This video introduces only the boot-time service registration path needed for
Section 2. Save loading and audio definition registration exist in the current
source, but they are later increments unless the Section 2 visible result needs
them.
```

Bad scope statement:

```text
Implement every method from the current class now.
```

## Incremental Class Introduction Rule

A generated class video should teach the class as an incremental build, not as
one large final implementation dump.

For each required class video, the implementation plan must split the class into
small teaching increments:

1. Class shell and responsibility.
2. Minimal fields needed for the section goal.
3. The first public function or callback that makes the class useful.
4. The smallest integration point needed for the visible result.
5. A verification step that proves this increment works.
6. Optional or later behavior clearly deferred out of the current video.

Each increment should answer:

- What are students adding now?
- Why does this step belong in this section?
- What visible behavior, log line, test assertion, or scene change proves it?
- What part of the full class is intentionally not introduced yet?

Do not compress a long class into one video by listing every final method in
order. If the real class is large, generate a smaller section-scope version and
defer advanced methods to later sections or optional coverage.

## State Machine Teaching Default Rule

Use flat FSM as the default teaching path for state behavior.

When generating a section design or class video that needs a state machine:

1. Use `Fsm` as the required/mainline state machine unless the requested section
   explicitly teaches hierarchical state behavior.
2. Use `FsmState` as the required/mainline base for player, enemy, idle, move,
   attack, cast, and other section states.
3. Treat `Hfsm` and `HfsmState` as optional/advanced coverage only.
4. Put HFSM material in `Optional Coverage`, or in an optional video only if the
   user explicitly approves it.
5. If a current demo source file still extends `HfsmState`, record that as a
   source correction and keep the generated course implementation scoped to
   `FsmState` unless the lesson goal is specifically HFSM.
6. Do not introduce parent/child state paths, active leaf state, or
   lowest-common-ancestor transitions in required class videos.

## Generated Content Organization Rule

Create one folder per generated section detailed design.

Generated section designs should live under this root:

```text
udemy/generated/section-detail-designs/
```

The required folder hierarchy is:

```text
section folder -> class folders -> class files
```

One course section must be one folder. Each required class video in that
section must be one direct child folder inside the section folder. A class
folder owns all design files for that class. Do not place class design files
directly in the generated root, and do not group multiple required classes into
one folder.

Use this section folder pattern:

```text
udemy/generated/section-detail-designs/section-<nn>-<section-slug>/
```

Folder naming rules:

- `<nn>` is the two-digit section number from `udemy/README.md`.
- `<section-slug>` is a short lower-kebab-case version of the section title.
- Use only lowercase letters, numbers, and hyphens in folder names.
- Keep the section folder name stable after generation, even if individual
  class files are revised later.
- Do not put a concrete class name in the section folder name.

Each generated section folder must use this shape. The `video-<vv>-<class-slug>/`
entries are repeated sibling folders, one per required class:

```text
section-<nn>-<section-slug>/
  README.md
  01-source-check.md
  02-high-level-class-design.md
  03-video-plan.md
  04-optional-coverage.md
  05-demo-integration.md
  06-tests-or-verification.md
  video-02-<class-a-slug>/
    README.md
    public-api.md
    implementation-plan.md
    read-aloud-script.md
    verification.md
  video-03-<class-b-slug>/
    README.md
    public-api.md
    implementation-plan.md
    read-aloud-script.md
    verification.md
```

Section-level file rules:

- `README.md` is the index for the section. It links to the high-level design,
  video plan, optional coverage, verification file, and every class subfolder.
- `01-source-check.md` records the README section, source files checked, naming
  corrections, and runtime assumptions.
- `02-high-level-class-design.md` contains Video 1: High-Level Class Design.
- `03-video-plan.md` lists all required class videos and support videos.
- `04-optional-coverage.md` keeps optional classes and optional artifacts out of
  required class videos.
- `05-demo-integration.md` describes the demo or visible result for the section.
- `06-tests-or-verification.md` lists the verification steps for the generated
  design.

Class subfolder rules:

- Create one direct class subfolder for each required class video.
- Name class subfolders as `video-<vv>-<class-slug>/`.
- `<vv>` is the two-digit video number for that class video.
- `<class-slug>` is the current class name converted to lower-kebab-case.
- Keep every class subfolder directly under the section folder.
- Put all files for that class inside its class subfolder.
- Do not nest class subfolders inside other class subfolders.
- Do not combine multiple required classes in one class subfolder.
- Do not put optional classes in required class subfolders.

Class file rules:

- `README.md` explains the class responsibility and links to the other class
  files.
- `public-api.md` defines public fields, signals, and public functions.
- `implementation-plan.md` explains what the class video will implement.
- `read-aloud-script.md` contains the simple script for that class video.
- `verification.md` explains how to verify this class design.

Optional content should stay at section level by default. Use
`04-optional-coverage.md` for optional classes, optional artifacts, and optional
discussion topics. Create optional subfolders only if the user explicitly asks
for optional videos to become generated artifacts.

This guide should not create generated section folders by itself.

## Section Detailed Design Template

Use this structure for the generated section folder `README.md`:

```text
# Section NN - <Section Title> Detailed Design

## Folder Index

- Source check:
- High-level class design:
- Video plan:
- Optional coverage:
- Demo integration:
- Tests or verification:
- Required class folders:

## Source Check

- README section:
- Source files checked:
- Naming corrections:
- Runtime assumptions:

## Section Goal

## Student-Visible Result

## What You Will Build

## High-Level Class Design

### Mermaid Diagram

### Class Responsibilities

### Concrete Example

## Video Plan

## Required Class Folder Index

## Optional Coverage

## Demo Integration

## Tests Or Verification

## Suggested Commit
```

## High-Level Class Design Rule

Every generated section design must begin with a high-level class design talk.

This is a concept/support video. It explains the shape of the section before
class-by-class implementation begins.

It must include:

1. `What You Will Build`
2. `High-Level Design`
3. A Mermaid diagram.
4. A class responsibility table.
5. One concrete example from the target section.

The high-level talk must not implement any class.

## Mermaid Diagram Rules

Every generated section design needs one Mermaid diagram in the high-level
design section.

Allowed diagram types:

- `flowchart`
- `sequenceDiagram`
- `classDiagram`

The diagram should show one of these:

- class relationships;
- ownership boundaries;
- runtime flow;
- data flow;
- command/event chain.

Diagram rules:

- Use current source class names.
- Keep the diagram small enough to explain in one video.
- Do not invent classes just to make the diagram look complete.
- Do not include optional classes in the main diagram unless the section
  explicitly includes them.

## Class Responsibility Table Rule

Every generated section design must include a class responsibility table.

Use this shape:

```text
| Class | Responsibility | Main capability | Does not own |
| --- | --- | --- | --- |
```

The table should explain class roles in plain teaching language.

Do not copy source comments into the table.

Do not turn the table into an API reference.

## Concrete Example Rule

Every generated section design must include one concrete example.

The example must come from the target section's intended demo or runtime flow.

Good example shape:

```text
When <user/runtime action> happens, <Class A> creates/updates <data>, then
<Class B> uses that data, then <Class C> produces the visible result.
```

Avoid abstract-only explanations such as:

```text
This section improves decoupling and domain boundaries.
```

If a technical term is necessary, define it immediately and attach it to the
example.

## Video Plan Rule

Every generated section design must include a video plan.

The first video is always:

```text
Video 1: High-Level Class Design
Type: support
```

After Video 1:

```text
One required class = one class video.
```

Class video rules:

- Each class video focuses on exactly one required class.
- A class video may mention other classes only as short context.
- A class video must not implement or explain optional classes.
- A class video must not combine multiple required classes into one
  implementation video.

Support videos are allowed for:

- scene setup;
- resource setup;
- input map setup;
- demo integration;
- tests;
- debugging;
- commits.

Support videos should not hide class implementation work.

## Required Class Contract Template

Use this template for each required class subfolder in a generated section
design.

The generated class subfolder is:

```text
video-<vv>-<class-slug>/
```

Split the class details across the class files:

- `README.md` gets status, source path, extends, purpose, section-scope
  responsibility, and links.
- `public-api.md` gets public fields, signals, and public functions, separated
  into current source truth and this-video introduction scope when needed.
- `implementation-plan.md` gets the incremental implementation order for the
  class video.
- `read-aloud-script.md` gets the script.
- `verification.md` gets checks for this class.

Use this content shape across those files:

```text
### <ClassName>

Status:
current / planned / course-only

Source path:
<path>

Extends:
<exact live source extends>

Purpose:
<one-sentence responsibility>

Section goal:
<target section goal that narrows this class video>

Introduced in this video:
- <field/function/behavior needed for the section goal>

Later or out of scope:
- <current source behavior that should not be taught in this video yet>

Public fields/signals:
- <field_or_signal>: <type> - <why students need it>

Public functions:
- <function_name(args) -> ReturnType> - <what it must do>

Private helpers:
- <helper_name> - <why it helps explain this class>

Does not own:
- <responsibility that belongs elsewhere>

Incremental implementation:
1. <small first increment>
2. <small next increment>
3. <verification increment>

Read-aloud script:
<simple script that explains only this section-scope increment>
```

Only fill this template in a generated class subfolder, not in this guide.

## Optional Coverage Rule

Optional content must stay separate from required class videos.

In generated section designs:

- Put optional classes or artifacts under `Optional Coverage`.
- Explain why they are optional.
- Explain when they should be included.
- Do not include optional content in required class contracts.
- Do not include optional content in required class videos.

Use this shape:

```text
| Optional class/artifact | Why optional | When to include |
| --- | --- | --- |
```

## Read-Aloud Script Rules

Scripts in generated section designs must be simple enough to read while
recording.

Rules:

- Use simple, direct language first.
- If a technical term is necessary, define it immediately.
- Explain the term with a concrete example from the section.
- Prefer concrete runtime actions over abstract architecture language.
- Start with the class responsibility.
- Name the source path.
- State the `extends`.
- Add fields before functions.
- Explain public fields and functions in implementation order.
- Explain only the fields and functions introduced in the current class video.
- Explain how the class connects to the visible result.
- State what the class deliberately does not own.
- State what existing source behavior is deferred to later sections.
- Use current source names and paths.

Good script shape:

```text
Create <ClassName> at <path> and extend <BaseClass>. This class has one job:
<plain-language responsibility>. First add <field> because <specific reason>.
Then add <function>. This function does <specific behavior>. In this section,
that matters because <concrete example>.
```

Bad script shape:

```text
Implement the service layer and decouple the domain logic.
```

## Section Coverage Seed Rule

This guide includes source-derived section scope seeds. They are not full
section detailed designs. They define the minimum class/API scope that future
generated section designs should use.

When generating a section design, derive coverage from the requested section:

1. Read the target section's "Students will build" list.
2. Inspect current source files for the named classes.
3. Mark each class as required, optional, planned, or support-only.
4. Apply the FSM-first teaching rule before deciding whether state-machine
   classes are required or optional.
5. For each required class, identify the smallest section-scope increment that
   supports the section goal.
6. Keep only required classes in the required class video list.
7. Move optional items and later-source behavior to `Optional Coverage` or
   `Later section`.
8. Do not pull in classes from later sections unless the current section needs
   them to produce its visible result.

## Source-Derived Section Scope Seeds

These seeds are derived from `udemy/README.md` and checked against the current
source tree. They define the expected scope for each section when generating
detailed designs.

Use them as course-scope boundaries:

- Fields and APIs listed here are the minimum section-scope surface to teach.
- If the current source has extra behavior, defer it to `Later section` unless
  the current section's visible result needs it.
- If the README name differs from current source, use the source correction.
- Methods beginning with `_` are listed only when they are Godot callbacks or
  required override hooks for the class video.

### Source Corrections From Current Code

| README name | Current source truth | Scope note |
| --- | --- | --- |
| `StateMachine` | `StateMachineBase` + `Fsm` in `addons/mkit/kernel/state_machine/` | Course mainline should teach flat `Fsm` first; `Hfsm` is optional/advanced coverage. |
| `State` | `FsmState` | Course mainline states should use `FsmState`; `HfsmState` is optional/advanced coverage. If a live demo state still extends `HfsmState`, record that source correction instead of making HFSM the teaching default. |
| `PlayerInputController` | `game/entities/player_input_reader.gd` | Current script has no `class_name`; scope it as a game-specific input sender. |
| `DamageEffect` | `DealDamageEffect` | Use the current class name. |
| `Health` / `Stats` | `HealthComponent` / `StatsComponent` | Use component names from source. |
| `EnemyBrain` | `Brain` + `SimpleAIEnemyBrain` | Teach base brain first, then simple chase/attack brain. |
| `LootTable` | `LootTableDefinition` + `LootEntry` | Use data-resource names from source. |
| `RewardChoice` | `RewardOption`, `RewardDefinition`, and section UI/support code | Use `RewardOption` as runtime choice data. |

### Section 1 - Course Setup And Final Demo Preview

Goal: understand the course target and repo boundaries.

Student-visible result: the student can run the project and identify framework
code versus game content.

Required class videos: none. This is a support/setup section.

Required artifacts:

| Artifact | Section scope | Fields | Public API |
| --- | --- | --- | --- |
| `project.godot` | Show main scene and autoload setup. | `run/main_scene`, `ServiceRegistry` autoload | Godot project configuration only. |
| `game/bootstrap.tscn` | Show the boot scene used by the demo. | `resource_databases`, `initial_scene_path` | Scene configuration only. |
| `addons/mkit/` vs `game/` | Teach reusable framework versus concrete content. | None | None |

Later section: do not teach implementation details for services, commands,
states, actions, effects, combat, quests, loot, or save yet.

### Section 2 - Runtime Kernel Foundation

Goal: build the minimum runtime foundation.

Student-visible result: the game boots through a clean bootstrap scene, and
core services are registered and accessible.

| Class / artifact | Source path | Section-scope implementation | Fields to introduce | Public API / override hooks to introduce | Later or out of scope |
| --- | --- | --- | --- | --- | --- |
| `ServiceRegistry` | `addons/mkit/kernel/services/service_registry.gd` | Autoload registry for service id to service object lookup. | `_services: Dictionary` as internal storage. | `register_service(service_id, service)`, `has_service(service_id)`, `get_port(service_id)`, `get_registered_service_ids()`, `unregister_service(service_id)`, `clear()` | Typed helper methods belong to `Mkit`; service behavior belongs to each service. |
| `GameBootstrap` | `addons/mkit/kernel/bootstrap/game_bootstrap.gd` | Boot coordinator for kernel services, content loading, validation, optional save load, and initial scene entry. | `resource_databases`, `initial_scene_path`, `save_path` | `_ready()`, `boot()`, `_build_services()` as subclass hook | Advanced save behavior and audio-content registration can be introduced only if the Section 2 visible result needs them. |
| `ModuleBootstrap` | `addons/mkit/modules/module_bootstrap.gd` | Extend `GameBootstrap` and append built-in module services. | No new fields. | `_build_services()` | Details of combat, quest, shop, dialogue, world, loot, and death loot are later module sections. |
| `Mkit` typed facade | `addons/mkit/modules/mkit.gd` | Give game/module code typed access to registered services. | No fields. | Section 2: `events()`, `content()`, `random()`, `time()`, `actions()`, `effects()`, `commands()`, `scenes()`, `pool()`, `save()`, `audio()` | Module accessors like `combat()`, `quest()`, `dialogue()`, `world()`, `loot()`, and `ui()` should be introduced when those systems become visible. |
| `ContentService` | `addons/mkit/kernel/registry/content_service.gd` | Minimum content registry used by bootstrap. | `_by_id`, `_by_type`, `_resource_path_by_id` | `load_database(database)`, `register_resource(res)`, `get_resource(content_id)`, `get_all_by_type(type_name)`, `has(content_id)`, `validate_all()` | Typed resource lookup details can wait until data-driven ability/content sections. |
| `ResourceDatabase` | `addons/mkit/kernel/registry/resource_database.gd` | Data file that lists resources for bootstrap loading. | `database_id`, `resources`, `resource_paths` | `get_all_resources()` | Large content organization and DLC-style loading are out of first-course scope. |

### Section 3 - Entity, Command, And State Machine

Goal: create the player entity and make movement command-driven.

Student-visible result: the player moves with WASD, and movement goes through a
command receiver and state machine.

| Class / artifact | Source path | Section-scope implementation | Fields to introduce | Public API / override hooks to introduce | Later or out of scope |
| --- | --- | --- | --- | --- | --- |
| `EntityRoot` | `addons/mkit/kernel/entity/entity_root.gd` | CharacterBody2D entity root with stable child lookup paths. | `identity`, `state_machine`, `command_receiver` | `get_entity_identity()`, `get_state_machine_node()`, `get_command_receiver_node()`, `get_entity_id()`, `get_component()`, `get_controller()`, `has_contract_node()` | Save agent, equipment, inventory, ability, and advanced controllers are later sections. |
| `EntityIdentity` | `addons/mkit/kernel/entity/entity_identity.gd` | Store the entity id and metadata needed by commands and events. | `entity_id`, `definition_id`, `display_name`, `faction`, `tags` | `has_tag(tag)`, `has_any_tag(input_tags)`, `is_faction(value)` | Content-driven `EntityDefinition` initialization is later. |
| `EntityContract` | `addons/mkit/kernel/entity/entity_contract.gd` | Static helper for stable entity child lookup. | None | `resolve_entity_root(node)`, `get_component(node, id_or_type)`, `get_controller(node, id_or_type)`, `get_contract_node(node, container, id_or_type)`, `get_identity(node)`, `get_entity_id(node)`, `get_state_machine(node)`, `get_command_receiver(node)`, `has_contract_node(node, container, id_or_type)` | Do not add game-specific child paths beyond the established entity contract. |
| `GameCommand` | `addons/mkit/kernel/commands/game_command.gd` | Value object describing intent from input, AI, or script. | `command_id`, `command_type`, `source_id`, `target_id`, `timestamp`, `payload`, `consumed` | `create(command_type, source_id, target_id, payload)`, `mark_consumed()`, `get_vector2()`, `get_string()`, `get_float()` | Network command queues and replay systems are out of scope. |
| `CommandReceiver` | `addons/mkit/kernel/commands/command_receiver.gd` | Node that receives commands and forwards them to the entity state machine. | `receiver_id`, `auto_register`, `owner_entity`, `state_machine`, `command_history`, `max_history` | `configure_receiver_id(id)`, `receive_command(command)`, `handle_unhandled_command(command)` | `CommandService` routing is support context unless the lesson sends commands by `target_id`. |
| `CommandService` | `addons/mkit/kernel/commands/command_service.gd` | Optional router when the caller knows only `target_id`. | `_receivers` | `register_receiver(receiver_id, receiver)`, `unregister_receiver(receiver_id)`, `dispatch(command)` | Keep it short in this section; do not make it the main movement abstraction. |
| `StateMachineBase` | `addons/mkit/kernel/state_machine/state_machine_base.gd` | Shared contract for command-capable state machines. | `owner_entity`, `blackboard` | `handle_command(command)` | Keep this as a short base-contract note; do not make inheritance theory the lesson. |
| `Fsm` | `addons/mkit/kernel/state_machine/fsm.gd` | Preferred course state machine: one active flat state, simple id-based transitions. | `initial_state_id`, `auto_start`, `current_state`, `previous_id`, `last_transition_reason`, `last_failed_transition_reason` | `_ready()`, `_process(delta)`, `_physics_process(delta)`, `handle_command(command)`, `transition_to(target_id, context)`, `get_current_id()`, `find_state(target_id)` | HFSM nesting and lowest-common-ancestor transitions are optional/advanced coverage. |
| `FsmState` | `addons/mkit/kernel/state_machine/fsm_state.gd` | Preferred course state base for idle, move, attack, cast, and enemy states. | `state_id`, `fsm`, `owner_entity`, `blackboard` | `setup(machine, entity)`, `enter(context)`, `exit(context)`, `update(delta)`, `physics_update(delta)`, `handle_command(command)`, `can_enter(context)`, `can_exit(context)`, `request_transition(target_id, context)` | `HfsmState` parent/child state paths are optional/advanced coverage. |
| `Hfsm` / `HfsmState` | `addons/mkit/kernel/state_machine/hfsm.gd`, `addons/mkit/kernel/state_machine/hfsm_state.gd` | Optional coverage only: hierarchical states for projects that need nested state paths. | `Hfsm.initial_state_path`, `Hfsm.current_leaf_state`, `HfsmState.initial_child_state_id`, `HfsmState.parent_state`, `HfsmState.active_child` | `Hfsm.transition_to(target_path, context)`, `Hfsm.get_current_path()`, `HfsmState.request_transition(target_path, context)`, `HfsmState.get_full_path()` | Do not include in required class videos unless the user explicitly approves an optional/advanced HFSM video. |
| `PlayerIdleState` | `game/entities/states/player_idle_state.gd` | Idle state accepts movement commands and transitions to move. | No fields. | `enter(context)`, `handle_command(command)` | Attack/cast/dash command handling is later. |
| `PlayerMoveState` | `game/entities/states/player_move_state.gd` | Applies velocity from command payload and returns to idle on stop. | No new exported fields. | `physics_update(delta)`, `handle_command(command)` | Combat movement locks and hit stun are later. |
| `PlayerInputReader` | `game/entities/player_input_reader.gd` | Game-specific input adapter that sends movement commands. | `target_id`; keep `cast_ability_id` deferred | `_ready()`, `_physics_process(delta)` as required Godot callbacks | `_unhandled_input()` attack/cast/interact input is later. |

### Section 4 - Action And Effect Pipeline

Goal: build the action/effect pipeline and use it for the first attack.

Student-visible result: the player performs a melee attack, and the attack
triggers an effect instead of directly modifying the enemy.

| Class / artifact | Source path | Section-scope implementation | Fields to introduce | Public API / override hooks to introduce | Later or out of scope |
| --- | --- | --- | --- | --- | --- |
| `GameAction` | `addons/mkit/kernel/actions/game_action.gd` | Base timed operation with lifecycle, completion, cancellation, and effect hooks. | `action_id`, `context`, `elapsed`, `finished`, `cancelled_flag`, `cancel_tags`, `on_start_effects`, `on_complete_effects`, `on_cancel_effects` | signals `completed`, `cancelled`; `start(ctx)`, `update(delta)`, `cancel(reason)`, `complete()`, `is_finished()`, `can_cancel_with(tag)` | Complex effect resolution can wait until effects need multiple payloads. |
| `ActionService` | `addons/mkit/kernel/actions/action_service.gd` | Runtime service that starts and ticks active actions. | `active_actions` | signals `action_started`, `action_completed`, `action_cancelled`; `start_action(action, context)`, `cancel_actions_for_source(source, reason)` | Global action priority and queues are out of first-course scope. |
| `GameEffect` | `addons/mkit/kernel/effects/game_effect.gd` | Base resource for world changes. | `effect_id`, `conditions`, `tags` | `apply(context)`; `_apply_impl(context)` as subclass hook | Complex condition libraries are later. |
| `EffectService` | `addons/mkit/kernel/effects/effect_service.gd` | Central executor for one or more effects. | `trace_enabled`, `recent_results`, `max_recent_results` | `execute(effect, context)`, `execute_many(effects, context)`, `clear_recent_results()` | Full debugging UI for effect traces is later. |
| `TimedAttackAction` | `addons/mkit/modules/combat/actions/timed_attack_action.gd` | Attack timing that enables a hitbox during the active window. | `startup_duration`, `active_duration`, `recovery_duration`, `hitbox_component_name`, `hitbox_path` | `_on_start()`, `_on_update(delta)`, `_on_cancel(reason)`, `_on_complete()` override hooks | Animation polish and audio feedback can wait for feedback section. |
| `DealDamageEffect` | `addons/mkit/modules/combat/damage/deal_damage_effect.gd` | Current source class for README `DamageEffect`; creates `DamageRequest` and asks combat to resolve. | Section 4: `base_amount`, `damage_type`; optional now: `element_type`, `can_crit`; defer `hit_tags`, `on_hit_statuses` | `_apply_impl(context)` override hook | Status applications and elemental rules are later combat/ability refinements. |
| `PlayerAttackState` | `game/entities/states/player_attack_state.gd` | Game state that starts `TimedAttackAction` from the attack command. | `current_action` | `enter(context)`, `exit(context)` | SFX and hitbox indicator polish can be introduced in Section 7. |

### Section 5 - Combat System

Goal: add reusable combat logic.

Student-visible result: enemies take damage, die, and emit combat result events.

| Class / artifact | Source path | Section-scope implementation | Fields to introduce | Public API / override hooks to introduce | Later or out of scope |
| --- | --- | --- | --- | --- | --- |
| `HealthComponent` | `addons/mkit/modules/combat/health/health_component.gd` | Own current HP, damage application, healing, death, and save payload. | `current_hp`, `destroy_on_death`, `dead`, `stats` | signals `health_changed`, `damaged`, `healed`, `died`; `get_max_hp()`, `apply_damage(result)`, `heal(amount, source)`, `die(killer)`, `revive(percent)`, `to_save_data()`, `from_save_data(data)` | Save methods can be deferred to Section 11 if not needed here. |
| `StatsComponent` | `addons/mkit/modules/combat/stats/stats_component.gd` | Provide reusable numeric stats for max HP, attack, defense, crit, and speed. | `base_stats`, `modifiers_by_stat`, `cached_values`, `dirty_stats` | signal `stat_changed`; `get_stat_value()`, `set_base_stat()`, `add_modifier()`, `remove_modifier()`, `tick_modifiers()`, `mark_dirty()`, `mark_all_dirty()` | Persistent modifiers and stacking-rule depth can be deferred. |
| `DamageRequest` | `addons/mkit/modules/combat/damage_request.gd` | Input carrier for combat resolution. | `source`, `target`, `base_amount`, `damage_type`, `element_type`, `can_crit`, `can_evade`, `can_block`, `tags`, `payload` | No methods. | `on_hit_statuses` is later status-effect scope. |
| `DamageResult` | `addons/mkit/modules/combat/damage_result.gd` | Output carrier for final damage result. | `source`, `target`, `base_amount`, `final_amount`, `damage_type`, `element_type`, `was_critical`, `was_evaded`, `was_blocked`, `was_lethal`, `trace` | `to_debug_dict()` | Status application arrays are later. |
| `CombatService` | `addons/mkit/modules/combat/combat_service.gd` | Resolve `DamageRequest` into `DamageResult`. | No fields. | `resolve(request)` | Rich formulas, status hooks, and advanced mitigation are later. |
| `HitboxComponent` | `addons/mkit/modules/combat/hitbox_component.gd` | Detect hurtboxes and submit damage. | `active`, `base_damage`, `damage_type`, `element_type`, `hit_once_per_activation`, `target_factions`, `source_entity`, `already_hit` | `set_active(value)` | `hit_tags` and `on_hit_statuses` are later. |
| `HurtboxComponent` | `addons/mkit/modules/combat/hurtbox_component.gd` | Damage-receiving area that resolves the owner entity. | `owner_path`, `can_receive_damage`, `damage_multiplier`, `damage_tags` | `get_owner_entity()` | Per-limb hit reactions are out of first-course scope. |
| `CombatEvents` | `addons/mkit/modules/combat/combat_events.gd` | Typed event factory for damage and death. | Constants only. | `damage_applied(result)`, `entity_died(entity_id, entity_ref, killer_ref)`, `entity_id_of(entity)` | Event presentation listeners are Section 7. |

### Section 6 - Data-Driven Abilities

Goal: move ability behavior into reusable definitions.

Student-visible result: the player presses Q to cast Firebolt, and ability
values come from resources instead of hardcoded scripts.

| Class / artifact | Source path | Section-scope implementation | Fields to introduce | Public API / override hooks to introduce | Later or out of scope |
| --- | --- | --- | --- | --- | --- |
| `AbilityDefinition` | `addons/mkit/modules/combat/abilities/ability_definition.gd` | Resource definition for ability data. | `ability_id`, `display_name`, `cooldown`, `charges`, `cost_type`, `cost_amount`, `cast_time`, `effects`; optional `icon`, `tags`, `conditions` | `get_content_id()` | Complex condition sets and icons can be introduced after the core cast works. |
| `AbilityInstance` | `addons/mkit/modules/combat/abilities/ability_instance.gd` | Runtime cooldown/charge state for one ability. | `definition_id`, `owner`, `cooldown_remaining`, `current_charges`, `runtime_level`, `enabled` | `setup(definition, owner_entity)`, `tick(delta)`, `is_cooldown_ready()`, `start_cooldown(definition, cooldown_reduction)`, `restore_charge(definition)` | Temporary modifiers are later. |
| `AbilityController` | `addons/mkit/modules/combat/abilities/ability_controller.gd` | Entity component that owns ability instances and casts by id. | `starting_ability_ids`, `abilities`, `active_cast_actions` | signals `ability_registered`, `ability_cast_started`, `ability_cast_finished`, `ability_failed`, `cooldown_started`; `register_ability()`, `unregister_ability()`, `has_ability()`, `can_cast()`, `get_cast_failure_reason()`, `cast()`, `is_cooldown_ready()`, `get_cooldown_remaining()`, `get_definition()` | Save payload can be deferred to Section 11 unless ability persistence is required here. |
| `ResourcePoolComponent` | `addons/mkit/modules/combat/health/resource_pool_component.gd` | Reusable mana/stamina-style resource pool for ability cost. | `starting_values`, `resources`, `stats` | signals `resource_changed`, `resource_spent`, `resource_restored`; `get_current()`, `get_max_resource()`, `has_resource()`, `spend()`, `restore()`, `set_current()` | Save methods can wait until Section 11. |
| `CooldownReadyCondition` | `addons/mkit/modules/combat/abilities/cooldown_ready_condition.gd` | Optional condition for ability availability. | `ability_id` | `get_failure_reason(context)` plus condition override behavior | Only include if the lesson needs a reusable condition asset. |
| `CastAction` | `addons/mkit/modules/combat/abilities/cast_action.gd` | Timed cast action used by ability controller. | `duration`, `animation_name` | `_on_start()`, `_on_update(delta)`, `_on_cancel(reason)`, `_on_complete()` override hooks | Polished cast VFX is Section 7. |
| `SpawnSceneEffect` | `addons/mkit/kernel/effects/builtin/spawn_scene_effect.gd` | Data-driven way to spawn a firebolt/projectile scene. | `scene_path`, `spawn_at_target`, `use_pool` | `_apply_impl(context)` override hook | Projectile movement/damage script can remain game-specific. |
| `PlayerCastAbilityState` | `game/entities/states/player_cast_ability_state.gd` | Game state that asks `AbilityController` to cast the selected ability. | No fields. | `enter(context)` | Target selection helper is game-specific and can stay minimal. |

### Section 7 - Events, UI, Audio, And VFX

Goal: connect gameplay events to presentation feedback.

Student-visible result: combat feels responsive because UI, audio, and VFX react
to events.

| Class / artifact | Source path | Section-scope implementation | Fields to introduce | Public API / override hooks to introduce | Later or out of scope |
| --- | --- | --- | --- | --- | --- |
| `EventService` | `addons/mkit/kernel/events/event_service.gd` | Publish/subscribe service for gameplay events. | `recent_events`, `max_recent_events` | signal `domain_event_emitted`; `emit_domain_event(event)`, `emit_event(event_type, source_id, target_id, payload)`, `subscribe(event_type, callable)`, `unsubscribe(event_type, callable)`, `is_subscribed(event_type, callable)` | Event DSLs and schema compilers are out of scope. |
| `DomainEvent` | `addons/mkit/kernel/events/domain_event.gd` | Shared event payload carrier. | `event_type`, `event_id`, `timestamp`, `source_id`, `target_id`, `payload` | `create(event_type, source_id, target_id, payload)` | Serialization can wait until save/testing needs it. |
| `DamageNumberSystem` | `game/ui/damage_number_system.gd` | Show damage popups when combat events arrive. | `damage_number_scene_path`, `default_offset`, `use_pool`, `auto_release_seconds` | `show_number(position, amount, critical)` | Pooling is optional. |
| `DamageNumber` | `game/ui/damage_number.gd` | Visual node for one floating damage number. | `amount`, `critical` | `setup(value, is_critical)`, `on_pool_acquired()`, `on_pool_released()` | Animation polish can be iterative. |
| `VFXSpawner` | `game/ui/vfx_spawner.gd` | Spawn hit VFX from event-driven feedback. | `vfx_scene_map`, `auto_free_seconds`, `use_pool` | `spawn(vfx_id, position, direction)` | Pooling is optional. |
| `HitVFX` | `game/ui/hit_vfx.gd` | Simple reusable VFX node. | `play_count`, `direction` | `play()`, `set_direction(value)`, `on_pool_acquired()`, `on_pool_released()` | Advanced shaders are out of scope. |
| `AudioDefinition` | `addons/mkit/kernel/services/audio_definition.gd` | Content resource for sound/music ids. | `audio_id`, `stream`, `kind`, `loop` | `get_content_id()` | Music loops can be optional. |
| `AudioService` | `addons/mkit/kernel/services/audio_service.gd` | Play content-driven SFX and music. | `sfx_map`, `music_map`, `sfx_bus`, `music_bus`, `music_player`, `current_music_id`, `bus_volumes` | `register_audio_definition()`, `register_audio_definitions()`, `play_sfx()`, `play_music()`, `stop_music()`, `set_bus_volume()`, `get_bus_volume()` | Save methods are Section 11. |
| `UIManager` | `addons/mkit/modules/ui/ui_manager.gd` | Optional screen stack for HUD/toast/reward UI. | `screen_root_path`, `screen_scene_map`, `screen_stack`, `active_screens`, `modal_screens` | signals `screen_opened`, `screen_closed`; `open_screen()`, `close_screen()`, `close_top_screen()`, `is_screen_open()` | Full UI framework is not required for the first feedback lesson. |
| `FeedbackSystem` | `game/ui/feedback_system.gd` | Game-owned event listener that connects damage/death events to UI, audio, and VFX. | `damage_number_system_path`, `vfx_spawner_path`, `audio_manager_path`, `ui_manager_path`, `toast_screen_id`, `damage_screen_shake_strength`, `death_toast_template` | signals `toast_requested`, `screen_shake_requested`; `show_toast(message)`, `request_screen_shake(strength)` | Keep it game-side; do not move demo feedback into `addons/mkit/`. |

### Section 8 - Enemy AI And Loot

Goal: add basic enemy behavior and reward drops.

Student-visible result: enemies chase the player, attack, die, and drop loot.

| Class / artifact | Source path | Section-scope implementation | Fields to introduce | Public API / override hooks to introduce | Later or out of scope |
| --- | --- | --- | --- | --- | --- |
| `Brain` | `addons/mkit/modules/ai/brain.gd` | Base AI thinker that can issue commands. | `enabled`, `think_interval`, `command_receiver`, `target`, `blackboard` | `think()`, `issue_command(command_type, payload)` | Behavior trees and planners are out of scope. |
| `SimpleAIEnemyBrain` | `addons/mkit/modules/ai/simple_ai_enemy_brain.gd` | Simple chase/attack AI for demo enemies. | `detection_range`, `attack_range`, `target_group` | `think()` | Advanced pathfinding can be deferred. |
| `EnemyIdleState` | `game/entities/states/enemy_idle_state.gd` | Game enemy idle state that accepts AI commands. | No fields. | `handle_command(command)` | No reusable addon API. |
| `EnemyMoveState` | `game/entities/states/enemy_move_state.gd` | Enemy chase movement state. | `_stats` as internal source of speed | `enter(context)`, `physics_update(delta)`, `handle_command(command)` | Keep game-specific movement simple. |
| `EnemyAttackState` | `game/entities/states/enemy_attack_state.gd` | Enemy attack action state. | `current_action` | `enter(context)`, `exit(context)`, `handle_command(command)` | Boss attacks are future-course scope. |
| `LootEntry` | `addons/mkit/modules/loot/loot_entry.gd` | One weighted entry inside a loot table. | `content_id`, `weight`, `min_quantity`, `max_quantity`, `conditions` | No methods. | Complex condition libraries are optional. |
| `LootTableDefinition` | `addons/mkit/modules/loot/loot_table_definition.gd` | Content resource defining weighted drops. | `loot_table_id`, `rolls`, `entries`, `allow_empty`, `empty_weight` | `get_content_id()` | Multi-stage loot rules are later. |
| `LootService` | `addons/mkit/modules/loot/loot_service.gd` | Roll loot tables and create reward options. | No fields. | `roll_table(table_id, context)`, `roll(table, context)`, `generate_options(pool_ids, count, context)`, `apply_selected(option, context)` | Reward-choice loop can wait until Section 10. |
| `DeathLootRuleDefinition` | `addons/mkit/modules/loot/death_loot_rule_definition.gd` | Content rule mapping death events to loot tables. | `rule_id`, `enabled`, `priority`, `entity_definition_ids`, `factions`, `required_tags`, `excluded_tags`, `conditions`, `loot_table_ids`, `stop_after_match` | `get_content_id()`, `matches_death_event(event, context)` | Only include after basic loot table rolling is clear. |
| `DeathLootService` | `addons/mkit/modules/loot/death_loot_service.gd` | Listen for entity death and emit loot drops. | `recent_drops`, `max_recent_drops` | `process_death_event(event)` | Drop persistence is later. |
| `LootEvents` | `addons/mkit/modules/loot/loot_events.gd` | Typed event factory for loot and rewards. | Constants only. | `reward_selected(reward_id, source_id)`, `loot_dropped(drop)` | Presentation handling belongs to Section 7/10 UI. |

### Section 9 - Quest And Dialogue

Goal: add NPC interaction and quest progress.

Student-visible result: the player talks to an NPC, accepts a quest, and
progresses it through combat.

| Class / artifact | Source path | Section-scope implementation | Fields to introduce | Public API / override hooks to introduce | Later or out of scope |
| --- | --- | --- | --- | --- | --- |
| `DialogueDefinition` | `addons/mkit/modules/dialogue/dialogue_definition.gd` | Content resource for dialogue graph root and nodes. | `dialogue_id`, `start_node_id`, `nodes` | `get_content_id()`, `get_node(node_id)` | Localization is out of scope. |
| `DialogueNode` | `addons/mkit/modules/dialogue/dialogue_node.gd` | One node of dialogue text/effects/choices. | `node_id`, `speaker_id`, `on_enter_effects`, `choices`, `next_node_id` | No methods. | Portrait/UI data can stay game-side. |
| `DialogueChoice` | `addons/mkit/modules/dialogue/dialogue_choice.gd` | Selectable branch with effects and conditions. | `next_node_id`, `conditions`, `effects` | No methods. | Complex branching can be optional. |
| `DialogueService` | `addons/mkit/modules/dialogue/dialogue_service.gd` | Runtime service for starting, advancing, choosing, and ending dialogue. | `runtime` | signals `dialogue_started`, `node_entered`, `choices_presented`, `dialogue_ended`; `is_active()`, `start()`, `get_available_choices()`, `choose()`, `advance()`, `end()`, `get_definition()` | Save dialogue runtime only if needed later. |
| `DialogueInteractable` | `addons/mkit/modules/dialogue/dialogue_interactable.gd` | Interactable that starts a dialogue id. | `dialogue_id`, `npc_id` | `_interact_impl(context)` override hook | Interaction discovery UI can stay separate. |
| `QuestDefinition` | `addons/mkit/modules/quest/quest_definition.gd` | Content resource for quest data. | `quest_id`, `display_name`, `quest_type`, `objectives`, `prerequisite_quest_ids`, `accept_conditions`, `reward_effects`, `auto_complete`, `repeatable`, `tags` | `get_content_id()`, `get_objective(objective_id)` | Multi-quest chains are later. |
| `QuestObjectiveDefinition` | `addons/mkit/modules/quest/quest_objective_definition.gd` | Event-matching objective definition. | `objective_id`, `event_type`, `match_key`, `match_value`, `count_payload_key`, `required_count`, `optional` | No methods. | Optional objectives can be deferred. |
| `QuestService` | `addons/mkit/modules/quest/quest_service.gd` | Accept, advance, complete, turn in, and save quest state. | `log` | signals `quest_offered`, `quest_accepted`, `objective_advanced`, `quest_completed`, `quest_turned_in`; `can_accept()`, `accept_quest()`, `notify_event()`, `advance_objective()`, `is_quest_complete()`, `complete_quest()`, `turn_in_quest()`, `get_definition()`, `get_state()` | Save methods can be taught in Section 11. |
| `QuestState` | `addons/mkit/modules/quest/quest_state.gd` | Runtime state for one quest. | `quest_id`, `status`, `objective_progress` | `create(quest_id)`, `get_progress()`, `set_progress()`, `to_save_data()`, `from_save_data()` | Save methods can be summarized here and expanded in Section 11. |
| `QuestEvents` | `addons/mkit/modules/quest/quest_events.gd` | Typed event factory for quest changes. | Constants only. | `quest_accepted()`, `quest_objective_advanced()`, `quest_completed()`, `quest_turned_in()` | UI reaction is presentation scope. |

### Section 10 - Room Loop And Rewards

Goal: build a small roguelike-style room loop.

Student-visible result: the player clears multiple rooms and chooses rewards
between rooms.

| Class / artifact | Source path | Section-scope implementation | Fields to introduce | Public API / override hooks to introduce | Later or out of scope |
| --- | --- | --- | --- | --- | --- |
| `RoomDefinition` | `addons/mkit/modules/world/dungeon/room_definition.gd` | Content definition for one room. | `room_id`, `scene_path`, `room_type`, `difficulty_rating`, `size`, `tags`, `enemy_spawn_ids`, `reward_pool_ids` | `get_content_id()` | Procedural generation is future-course scope. |
| `RoomRuntime` | `addons/mkit/modules/world/dungeon/room_runtime.gd` | Runtime state for active room progress and reward options. | `room_runtime_id`, `definition_id`, `cleared`, `entered`, `active_enemy_ids`, `reward_options` | `create(definition_id, runtime_id)`, `to_save_data()`, `from_save_data()` | Save methods can be summarized and revisited in Section 11. |
| `RoomController` | `addons/mkit/modules/world/dungeon/room_controller.gd` | Scene controller for entering rooms, spawning enemies, detecting clear, and producing rewards. | `room_definition_id`, `enemy_container_path`, `entity_spawner_path`, `reward_count`, `spawn_positions`, `runtime`, `active_enemies`, `entity_spawner` | signals `room_entered`, `room_cleared`, `reward_ready`; `setup()`, `enter_room()`, `spawn_enemies()`, `check_clear_condition()`, `generate_reward()`, `get_definition()`, `restore_runtime()` | Advanced room objectives are out of first-course scope. |
| `EntitySpawner` | `addons/mkit/modules/entity/entity_spawner.gd` | Spawn entities from `EntityDefinition` ids for room encounters. | `content` | signals `entity_spawned`, `entity_spawn_failed`; `spawn_entity(definition_id, parent, position, runtime_id)` | Full editor spawn tooling is out of scope. |
| `RoomLoader` | `addons/mkit/modules/world/dungeon/room_loader.gd` | Instantiate room scene from `RoomDefinition`. | `last_error` | `load_room(room_definition_id, container)` | Complex streaming is out of scope. |
| `RewardDefinition` | `addons/mkit/modules/loot/reward_definition.gd` | Content resource for selectable room reward. | `reward_id`, `display_name`, `icon`, `rarity`, `weight`, `conditions`, `effects` | `get_content_id()` | Deep upgrade systems are future-course scope. |
| `RewardOption` | `addons/mkit/modules/loot/reward_option.gd` | Runtime choice shown to the player. | `reward_id`, `display_name`, `description`, `icon`, `rarity`, `source`, `effects`, `payload` | No methods. | UI rendering is game-side. |
| `RunState` | `addons/mkit/modules/world/dungeon/run_state.gd` | Runtime state for a room run. | `run_id`, `seed`, `run_length`, `first_floor_room_pool`, `current_floor`, `current_room_index`, `current_room_id`, `elapsed_time`, `temporary_upgrade_ids`, `run_currency`, `enemy_scaling_level`, `room_history`, `reward_history`, `rng_state`, `status` | `create(seed_value)`, `to_save_data()`, `from_save_data()` | Random graph generation can be simplified for first course. |
| `RunDirector` | `addons/mkit/modules/world/dungeon/run_director.gd` | High-level run coordinator for starting, entering rooms, choosing rewards, and finishing. | `first_floor_room_pool`, `room_scene_container_path`, `player_group`, `player_entity_id`, `run_length`, `run_state`, `room_graph`, `current_room_controller` | signals `run_started`, `room_enter_requested`, `choosing_reward`, `run_finished`; `run_graph_is_empty()`, `start_run()`, `enter_next_room()`, `on_room_cleared()`, `select_reward()`, `complete_run()`, `fail_run()` | Save scopes and restore behavior can be emphasized in Section 11. |

### Section 11 - Save, Load, And Testing

Goal: make progress persistent and verify core systems with tests.

Student-visible result: the player can save and load progress, and core systems
have basic automated test coverage.

| Class / artifact | Source path | Section-scope implementation | Fields to introduce | Public API / override hooks to introduce | Later or out of scope |
| --- | --- | --- | --- | --- | --- |
| `SaveService` | `addons/mkit/kernel/save/save_service.gd` | Save/load service for root saveables, entity records, and registered scopes. | `save_path`, `save_version`, `schema_version`, `game_version`, `profile_id` | signals `save_completed`, `load_completed`, `save_failed`, `load_failed`; `save_game(root)`, `load_game(root)`, `register_saveable_scope(provider)`, `unregister_saveable_scope(provider)`, `get_registered_scope_snapshot()` | Generic migration framework is explicitly not first-course scope. |
| `Saveable` | `addons/mkit/kernel/save/saveable.gd` | Base node for root-level save data and save scopes. | `save_id`, `save_scope`, `restore_order` | `get_save_scope()`, `get_save_scopes()`, `get_save_payload_for_scope(scope)`, `apply_save_payload_for_scope(scope, data)`, `register_save_scopes()`, `unregister_save_scopes()`, `get_save_id()`, `to_save_data()`, `from_save_data(data)` | Keep examples focused on progression/quest/audio/run state. |
| `SaveableComponent` | `addons/mkit/kernel/save/saveable_component.gd` | Base node for entity component payloads. | No fields. | `get_save_key()`, `to_save_data()`, `from_save_data(data)` | Component discovery details should stay simple. |
| `EntitySaveAgent` | `addons/mkit/kernel/save/entity_save_agent.gd` | Entity-level save record owner. | `entity_id`, `scene_path`, `zone_id`, `root_path`, `restore_order`, `include_duck_participants` | `get_entity_id()`, `to_entity_save_record()`, `apply_entity_save_record(record)`, `has_save_errors()`, `get_save_errors()` | Scene restoration across complex zones can be optional. |
| Existing save participants | `HealthComponent`, `StatsComponent`, `AbilityController`, `QuestService`, `RunDirector`, `AudioService` | Revisit only the save methods already needed by the demo loop. | Use each class's existing runtime fields. | `to_save_data()`, `from_save_data()` or scoped save APIs where present. | Do not add unrelated save migrations. |
| GUT tests | `test/unit/`, `test/integration/` | Add focused tests for save/load and one smoke integration. | Test fixtures only. | GUT `test_tc_*` methods. | Full CI course content is support-only. |

### Section 12 - Packaging The Kit

Goal: prepare the framework for reuse in future games.

Student-visible result: the student finishes with a playable demo and a reusable
kit boundary they can move to another project.

Required class videos: none by default. This is a packaging/documentation
section unless the user later approves optional implementation videos.

| Artifact | Source path | Section-scope implementation | Fields | Public API |
| --- | --- | --- | --- | --- |
| MKit addon plugin | `addons/mkit/plugin.gd`, `addons/mkit/plugin.cfg` | Explain how the addon is packaged and enabled. | No course fields. | `_enter_tree()`, `_exit_tree()` are plugin lifecycle hooks only. |
| Public API reference | `docs/generated/html/`, source `##` comments | Explain how generated docs come from source comments. | N/A | `make docs-api`, `make docs-check` are workflow commands, not runtime APIs. |
| Starter template boundary | `game_template/` when present, or documented export/copy checklist | Show what can move to a new project. | N/A | N/A |
| Reusable content boundary | `addons/mkit/` versus `game/` | Confirm no demo-specific boss, quest, room, price, or item is inside addon code. | N/A | N/A |

Later section: optional advanced packaging can cover editor plugin UI, module
manifests, template export automation, and generated marketplace docs.

## Verification For This Guide

Before reporting this guide as complete:

1. Confirm it is still a guide plus source-derived scope seeds, not a generated
   section folder.
2. Confirm source-derived section scope seeds are boundaries, not full generated
   section folders.
3. Confirm it contains no full per-video implementation plan.
4. Confirm it contains no real project-specific Mermaid diagram.
5. Confirm it contains no full class contract for a real class.
6. Confirm source-of-truth rules are explicit.
7. Confirm high-level class design rules are explicit.
8. Confirm section-goal scoping prevents full-class dumps.
9. Confirm incremental class introduction rules are explicit.
10. Confirm optional coverage is excluded from required class videos.
11. Confirm script rules require simple language, term definitions, and concrete
   examples.
12. Confirm generated content organization rules define section folders, class
    subfolders, folder names, and file names.
13. Run a markdown whitespace sanity check.

## Verification For Generated Section Designs

When a concrete section design is generated later:

1. Re-open the relevant README section.
2. Re-open current source files for every required class.
3. Confirm class names and paths exist or are marked planned.
4. Confirm public APIs match live source.
5. Confirm optional content is separate.
6. Confirm the high-level Mermaid diagram uses current names.
7. Confirm each class video states the target section goal and section-scope
   increment.
8. Confirm large current-source classes defer later behavior instead of
   implementing everything in one video.
9. Confirm scripts are concrete and easy to read aloud.
10. Confirm the generated section uses one section folder.
11. Confirm each required class video has one class subfolder.
12. Confirm class subfolders and files follow the required naming format.
