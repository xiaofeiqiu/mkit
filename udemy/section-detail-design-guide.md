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
- [x] Define generated content organization rules.
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
6. Create a separate section design folder.
7. Keep the generated section design focused on that section only.
8. Run a markdown sanity check for every generated file.

Do not generate all section designs unless the user explicitly asks for all of
them.

## Generated Content Organization Rule

Create one folder per generated section detailed design.

Generated section designs should live under this root:

```text
udemy/generated/section-detail-designs/
```

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

Each generated section folder must use this shape:

```text
section-<nn>-<section-slug>/
  README.md
  01-source-check.md
  02-high-level-class-design.md
  03-video-plan.md
  04-optional-coverage.md
  05-demo-integration.md
  06-tests-or-verification.md
  video-<vv>-<class-slug>/
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

- `README.md` gets status, source path, extends, purpose, and links.
- `public-api.md` gets public fields, signals, and public functions.
- `implementation-plan.md` gets the implementation order for the class video.
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
10. Confirm generated content organization rules define section folders, class
    subfolders, folder names, and file names.
11. Run a markdown whitespace sanity check.

## Verification For Generated Section Designs

When a concrete section design is generated later:

1. Re-open the relevant README section.
2. Re-open current source files for every required class.
3. Confirm class names and paths exist or are marked planned.
4. Confirm public APIs match live source.
5. Confirm optional content is separate.
6. Confirm the high-level Mermaid diagram uses current names.
7. Confirm scripts are concrete and easy to read aloud.
8. Confirm the generated section uses one section folder.
9. Confirm each required class video has one class subfolder.
10. Confirm class subfolders and files follow the required naming format.
