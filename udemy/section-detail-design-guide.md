# Section Detailed Design Guide

This document is a **guide for generating section detailed designs** from
`udemy/README.md`.

It is not a section detailed design. It must not contain the concrete design for
any specific section.

## Progress Tracker

- [x] Define the source-of-truth workflow.
- [x] Define the guide-only boundary.
- [x] Define the required section detailed design output structure.
- [x] Define the high-level class design requirements.
- [x] Define the one-class-per-video rule.
- [x] Define optional coverage boundaries.
- [x] Define script writing rules.
- [ ] Generate concrete section detailed designs only when explicitly requested.

## Guide-Only Boundary

This document must stay generic.

Allowed content:

- rules for generating section detailed designs;
- templates with placeholders;
- checklists;
- workflow steps;
- quality bars;
- examples of wording style using placeholders.

Not allowed in this guide:

- concrete section plans;
- filled class lists for a real section;
- full class contracts for real classes;
- real per-video implementation plans;
- full read-aloud scripts for real classes;
- project-specific class relationship diagrams;
- project-specific naming correction tables.

If a future task needs the concrete design for a section, create a separate
section design document for that section. Do not expand this guide into that
design.

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
5. Decide which classes are required and which are optional.
6. Create a separate section design file.
7. Keep the generated section design focused on that section only.
8. Run a markdown sanity check.

Do not generate all section designs unless the user explicitly asks for all of
them.

## Output File Rule

Create one file per generated section design.

Recommended path pattern:

```text
udemy/section-<nn>-<short-title>-design.md
```

Example shape only:

```text
udemy/section-02-runtime-kernel-foundation-design.md
```

This guide should not create that file by itself.

## Section Detailed Design Template

Use this structure for each generated section design:

```text
# Section NN - <Section Title> Detailed Design

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

## Required Class Contracts

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

Use this template for each required class in a generated section design:

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

Public fields/signals:
- <field_or_signal>: <type> - <why students need it>

Public functions:
- <function_name(args) -> ReturnType> - <what it must do>

Private helpers:
- <helper_name> - <why it helps explain this class>

Does not own:
- <responsibility that belongs elsewhere>

Read-aloud script:
<simple script that explains the implementation in order>
```

Only fill this template in a generated section design, not in this guide.

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
- Explain how the class connects to the visible result.
- State what the class deliberately does not own.
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

This guide does not list concrete section coverage.

When generating a section design, derive coverage from the requested section:

1. Read the target section's "Students will build" list.
2. Inspect current source files for the named classes.
3. Mark each class as required, optional, planned, or support-only.
4. Keep only required classes in the required class video list.
5. Move optional items to `Optional Coverage`.
6. Do not pull in classes from later sections unless the current section needs
   them to produce its visible result.

## Verification For This Guide

Before reporting this guide as complete:

1. Confirm it is still a pure guide.
2. Confirm it contains no filled concrete section design.
3. Confirm it contains no real section-by-section class list.
4. Confirm it contains no real project-specific Mermaid diagram.
5. Confirm it contains no full class contract for a real class.
6. Confirm source-of-truth rules are explicit.
7. Confirm high-level class design rules are explicit.
8. Confirm optional coverage is excluded from required class videos.
9. Confirm script rules require simple language, term definitions, and concrete
   examples.
10. Run a markdown whitespace sanity check.

## Verification For Generated Section Designs

When a concrete section design is generated later:

1. Re-open the relevant README section.
2. Re-open current source files for every required class.
3. Confirm class names and paths exist or are marked planned.
4. Confirm public APIs match live source.
5. Confirm optional content is separate.
6. Confirm the high-level Mermaid diagram uses current names.
7. Confirm scripts are concrete and easy to read aloud.
