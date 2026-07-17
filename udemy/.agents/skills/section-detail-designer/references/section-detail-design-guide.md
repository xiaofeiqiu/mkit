# Section Detailed Design Guide

This file is the index for generating section detailed designs from
`udemy/README.md`. It gives the high-level flow and points to the detailed
instruction files under `references/guide/` in this skill folder.

It is not a concrete section detailed design. Do not use this file to generate
full section folders, full class contracts, lesson scripts, or implementation
plans unless the user explicitly asks for a specific section design.

## Standard Generation Path

When asked to generate a concrete section detailed design, follow this path:

1. Read [Source Of Truth And Boundary](guide/01-source-of-truth-and-boundary.md).
2. Follow [Generation Workflow](guide/02-generation-workflow.md).
3. Apply [Output Organization](guide/03-output-organization.md).
4. Scope every class and dependency with
   [Section Scope And MVP](guide/04-section-scope-and-mvp.md).
5. Generate Video 1 with
   [High-Level Class Design](guide/05-high-level-class-design.md).
6. Generate one class folder per required class using
   [Class Design.md](guide/06-class-design-md.md) and
   [Implementation.md](guide/07-implementation-md.md).
7. Apply [Script Writing](guide/08-script-writing.md).
8. Keep optional material and state machine choices aligned with
   [Optional Support And FSM](guide/09-optional-support-and-fsm.md).
9. Use [Section Coverage Seeds](guide/10-section-coverage-seeds.md) as course
   boundaries.
10. Run [Verification](guide/11-verification.md).

Do not generate all section designs unless the user explicitly asks for all of
them.

## Instruction Index

| Need | Read this file | Why |
| --- | --- | --- |
| Know what counts as source truth | [01-source-of-truth-and-boundary.md](guide/01-source-of-truth-and-boundary.md) | Defines live source priority, guide-only scope, and addon/game boundaries. |
| Generate one concrete section | [02-generation-workflow.md](guide/02-generation-workflow.md) | Defines the end-to-end section-design workflow. |
| Create folders and files | [03-output-organization.md](guide/03-output-organization.md) | Defines `udemy/course/sections/`, section folders, class folders, and forbidden files. |
| Decide MVP scope | [04-section-scope-and-mvp.md](guide/04-section-scope-and-mvp.md) | Defines section-local MVP, future-section MVP, non-MVP, dependencies, and staged services. |
| Write Video 1 | [05-high-level-class-design.md](guide/05-high-level-class-design.md) | Defines the high-level concept video and section-level entrypoint. |
| Write class `design.md` | [06-class-design-md.md](guide/06-class-design-md.md) | Defines class identity, public API tables, design scripts, and public API scripts. |
| Write class `implementation.md` | [07-implementation-md.md](guide/07-implementation-md.md) | Defines incremental implementation steps and MVP-only snippets. |
| Write spoken scripts | [08-script-writing.md](guide/08-script-writing.md) | Defines embedded scripts, conversational tone, transitions, and snippet granularity. |
| Place optional/support content | [09-optional-support-and-fsm.md](guide/09-optional-support-and-fsm.md) | Defines optional coverage, support videos, and flat FSM as the default teaching path. |
| Keep course coverage bounded | [10-section-coverage-seeds.md](guide/10-section-coverage-seeds.md) | Lists source corrections and section-by-section scope seeds. |
| Check the result | [11-verification.md](guide/11-verification.md) | Defines checks for this guide and generated section designs. |

## Expected Generated Output

Concrete generated section detailed designs live under:

```text
udemy/course/sections/
```

Each requested section uses this shape:

```text
section-<nn>-<section-slug>/
  01-high-level-class-design.md
  video-02-<class-a-slug>/
    design.md
    implementation.md
  video-03-<class-b-slug>/
    design.md
    implementation.md
```

The section-level file is the entrypoint for Video 1. Each required class video
gets one direct `video-<vv>-<class-slug>/` folder. Class folders contain only
`design.md` and `implementation.md` unless the user explicitly asks for optional
or support videos as generated artifacts.

## High-Level Rules

- Use the current implementation and scenes as truth before course notes.
- Keep this guide generic; do not turn it into a real section design.
- Start every generated section with `Video 1: High-Level Class Design`.
- After Video 1, follow `one required class = one class video`.
- Keep optional classes out of required class videos.
- Class `design.md` files must front-load class identity and public accessible
  fields, signals, and functions.
- Class `implementation.md` files must cover only the current video's MVP.
- Treat MVP as section-local; defer later APIs as `future-section MVP` or
  `non-MVP`.
- Write scripts for students who know Godot and programming basics, but are not
  comfortable with professional architecture language yet.
- Explain one core design idea first, define the key domain noun, and use
  concrete source examples before adding analogies or formal architecture terms.
- Public API scripts must explain what each public interface is used for before
  explaining parameters, returns, or implementation details.
- Put spoken explanations next to the design point or code snippet they
  explain. Do not create standalone read-aloud script files.
- Put an explicit transition script between implementation steps.
- Use flat FSM as the default teaching path unless the requested section
  explicitly teaches hierarchical state behavior.

## Quick Verification

For this index and the child guide files:

```bash
grep -RIn '[[:blank:]]$' udemy/.agents/skills/section-detail-designer/SKILL.md udemy/.agents/skills/section-detail-designer/references
rg -n "TO""DO|TB""D|game[/]demo" udemy/.agents/skills/section-detail-designer/SKILL.md udemy/.agents/skills/section-detail-designer/references
git diff --check -- udemy/.agents/skills/section-detail-designer
```

For generated section designs, use
[Verification](guide/11-verification.md). Runtime Godot tests are not required
for guide-only edits unless the user asks for executable behavior or the course
material changes runtime claims.
