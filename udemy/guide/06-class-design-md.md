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

<spoken explanation of this class: what problem it solves, the concept behind
it, why the class exists, its responsibility, and how it relates to nearby
classes.>

## Public API Script

<spoken explanation of each public accessible MVP field, signal, and function.
Explain what the API means, why it is public, how students will use it, and why
future-section MVP and non-MVP public APIs are deferred. Keep this
conversational. Do not repeat the table mechanically.>

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
- the simple concept behind the class;
- why this class exists in the section;
- what the class owns;
- what the class deliberately does not own;
- how it connects to classes before and after it;
- which source behavior is deferred to later sections.

`Public API Script` explains every MVP public accessible field, signal, and
function in conversational teaching language. For each API, explain:

- what the field, signal, or function means;
- why it is public;
- who reads, writes, emits, or calls it;
- how it supports the current section goal;
- one concrete example using current source names when useful.

For future-section MVP and non-MVP public APIs, keep the explanation short.
State that the API exists in source and why it is deferred. Do not teach the
deferred API step by step in the current class video.
