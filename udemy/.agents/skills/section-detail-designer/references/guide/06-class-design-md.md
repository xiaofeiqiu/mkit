# Class Design.md

Use this instruction for each required class folder's `design.md`.

## Purpose

`design.md` is the class-level entrypoint. It must clearly list the class name,
status, source path, exact `extends`, section goal, public accessible fields,
public accessible signals, and public accessible functions before any teaching
script.

The tables show the factual API surface. The scripts explain meaning in spoken
teaching language.

## Required Structure

Use this template:

```text
# <ClassName> Design

## Class Identity

| Item | Value |
| --- | --- |
| Class name | `<ClassName>` |
| Status | current / planned / course-only |
| Source path | `<path>` |
| Extends | `<exact live source extends>` |
| Section goal | `<target section goal that narrows this class video>` |
| Purpose | `<one-sentence responsibility>` |

## MVP Decision

<one or two sentences explaining the smallest useful version of this class for
the section result. State that this is a section-local MVP decision, not a full
source API judgment.>

## Class Design

- Responsibility: <what this class owns>
- Collaborators: <classes/services it talks to>
- Runtime flow: <how it participates in the section result>
- Does not own: <responsibility that belongs elsewhere>

## MVP Scope Introduced In This Video

- <field/function/behavior needed for the section goal>

## Dependency Readiness

| Dependency | Status | Current-video decision |
| --- | --- | --- |
| `<dependency_or_service>` | already introduced / introduced now / ready support / future-section MVP / non-MVP | use now / defer |

## Public Accessible Fields

| Field | Type | Source visibility | MVP status |
| --- | --- | --- | --- |
| `<field_name>` | `<type>` | public / exported / signal payload owner | MVP / future-section MVP / non-MVP |

## Public Accessible Signals

| Signal | Parameters | MVP status |
| --- | --- | --- |
| `<signal_name>` | `<args>` | MVP / future-section MVP / non-MVP |

## Public Accessible Functions

| Function | Returns | MVP status |
| --- | --- | --- |
| `<function_name(args)>` | `<ReturnType>` | MVP / future-section MVP / non-MVP |

## Future-Section MVP

- <current source field/function/behavior that is not needed now but likely
  becomes MVP in section N>
- Likely section: <section number/title and why>

## Non-MVP Source Behavior

- <current source field/function/behavior that exists but is not needed for the
  section result or a known later section>
- Reason deferred: <why it is not MVP now>

## Design Script

<spoken explanation of this class for students who are past beginner basics but
not yet intermediate. Start with the core design idea this class teaches.
Define the key domain noun students need for this class, such as service,
command, effect, state, definition, instance, facade, or controller. Then give
one or two concrete examples from the current section before connecting the
idea to the real class name, source path, responsibility, collaborators, and
deferred behavior. Use an analogy only after the real design point is clear.>

## Public API Script

<spoken explanation of each public accessible MVP field, signal, and function.
For each public interface, first say what it is used for in plain language. For
example: "`register_service()` is used for registering one service object in
the registry." Then explain why it is public, how students will use it, the key
arguments or return value, and why future-section MVP and non-MVP public APIs
are deferred. Keep this conversational. Do not repeat the table mechanically.>

## Transition To Implementation

<one or two spoken sentences that move from design explanation into the first
implementation step>
```

## Public API Rules

Public accessible API means the API students or nearby classes can reasonably
touch from outside the class:

- exported fields;
- public variables that are not internal implementation details;
- signals;
- public functions that do not start with `_`;
- Godot callbacks and override hooks only when students implement or override
  them for the lesson result.

Do not list private helpers as public API. Mention private helpers only in
`implementation.md` when a step needs them.

Public API tables should stay factual. Use columns such as `Field`, `Type`,
`Source visibility`, `MVP status`, `Signal`, `Parameters`, `Function`, and
`Returns`. Do not put long descriptions, teaching explanations, or design
rationale inside API tables.

Every MVP public accessible field, signal, and function listed in the tables
must be explained in `Public API Script`.

Future-section MVP APIs should be named in the table and summarized in
`Future-Section MVP`, but they should not receive full implementation scripts
until the section where they become current MVP.

## Class Design Script Rules

`Design Script` explains:

- what problem this class solves;
- the one core design idea this class teaches;
- the key domain noun students must understand before the API makes sense;
- one or two concrete examples from current source or the current section;
- a simple analogy or concrete game situation after the real design point is
  clear;
- what the design term means in plain language, if one is needed;
- the simple concept behind the class;
- why this class exists in the section;
- what the class owns;
- what the class deliberately does not own;
- how it connects to classes before and after it;
- which source behavior is deferred to later sections.

Use an explanation depth that matches the target students: more than beginner,
less than intermediate. Assume they can read code and know Godot basics, but do
not assume they already understand architecture vocabulary such as facade,
composition root, service registry, event bus, dependency injection, or payload.
If one of those words is useful, define it immediately with a plain example.

## Core Design Focus Rule

Before writing `Design Script`, identify the one design idea the lesson should
teach. The script should not begin as a tour of fields or methods, and it should
not stop at a generic architecture phrase.

Use this sequence:

1. Name the core mechanism in plain English.
2. Define the key domain noun used by that mechanism.
3. Give one or two concrete examples from current source or the section goal.
4. Explain why the project needs this mechanism now.
5. Connect the mechanism to the class name, source path, `extends`,
   collaborators, and deferred behavior.

Examples of good core design focus:

- `ServiceRegistry`: "This class gives the runtime one centralized place to
  write and read shared services. A service is a reusable runtime object that
  owns one job, such as `RandomService` for shared randomness,
  `SceneService` for scene changes, `ContentService` for loaded content, or
  `EventService` for gameplay events."
- `GameCommand`: "This class turns player input, AI decisions, or script calls
  into one small intent object. A command is not the action itself; it is the
  message that asks an entity to do something."
- `GameEffect`: "This class represents a reusable world change. An effect is
  not the button press or the attack animation; it is the piece that changes
  health, spawns something, or emits feedback."

Bad core design focus:

```text
This class centralizes dependency access and improves decoupling.
```

```text
This class is like a front desk. The next method registers a service.
```

The first bad example hides the lesson behind architecture words. The second
starts with an analogy but skips the real design point: centralized write/read
access for runtime services.

Use this order for most design scripts:

1. Start with the core mechanism in plain English.
2. Define the key domain noun students need before seeing the API.
3. Give concrete examples from current source or the current section.
4. Explain the practical problem students can recognize.
5. Use an analogy only if it makes the already-stated mechanism easier to
   remember.
6. Connect the idea to the exact source path and `extends`.
7. Explain what the class owns and what it does not own.
8. Name the source behavior that is deferred and why it is not needed now.

Most design scripts should be three to five short spoken paragraphs. Do not
collapse the design into one professional summary sentence.

Good design-script opening:

```text
The core idea in `ServiceRegistry` is centralized service access. The runtime
needs one place to write services during boot and one place to read those
services later. A service is a shared runtime object with one job: for example,
`RandomService` owns shared randomness, `SceneService` owns scene changes, and
`ContentService` owns loaded resource definitions.
```

Bad design-script opening:

```text
This class centralizes dependency access and improves decoupling.
```

`Public API Script` explains every MVP public accessible field, signal, and
function in conversational teaching language. For each API, explain:

- what the public interface is used for, as the first sentence of that API's
  explanation;
- what the field, signal, or function means;
- why it is public;
- who reads, writes, emits, or calls it;
- the important argument or return value in simple language;
- how it supports the current section goal;
- one concrete example using current source names when useful.

Good public API explanation:

```text
`register_service()` is used for registering one service object in the
registry. The `service_id` is the name we will use later, like `"content"`, and
the `service` is the object we want to share. It returns `true` only when the
registry accepts the service.
```

Bad public API explanation:

```text
`register_service()` performs service registration and validation.
```

For future-section MVP and non-MVP public APIs, keep the explanation short.
State that the API exists in source and why it is deferred. Do not teach the
deferred API step by step in the current class video.
