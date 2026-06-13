# AGENTS.md

This file is the operating guide for agents working inside `udemy/`.
It applies to course-planning, lesson-design, script, outline, and course-support
materials under this directory.

The repository root `AGENTS.md` still governs the MKit runtime source tree. When
course material describes actual runtime behavior, verify it against the current
implementation first.

## Course Purpose

`udemy/` is the preparation workspace for a Udemy course about building a
reusable Godot 4 RPG / roguelike framework with MKit, then using that framework
in a playable demo.

The current entry document is `udemy/README.md`. Treat it as the course brief
and initial curriculum seed, not as a replacement for the live implementation.
If it disagrees with current MKit code, scenes, commands, or docs, prefer the
live repo and update the stale course material in the same change.

## Scope Boundary

Keep course-production artifacts in `udemy/` unless the user explicitly asks to
change the runtime, docs, tests, or game content outside this directory.

For `udemy/` work:

```text
udemy/       = course planning, curriculum, lesson scripts, checklists, prompts
addons/mkit/ = reusable framework implementation
game/        = concrete demo game content
docs/        = product/runtime documentation for the live repo
test/        = GUT verification for runtime behavior
```

Do not hardcode course-only examples, fake APIs, or speculative scene paths into
`addons/mkit/`. Do not present course plans as implemented runtime facts.

## Language

Conversation with the user may be in Chinese.

Durable course artifacts under `udemy/` should be written in English unless the
user explicitly asks otherwise. Keep code identifiers, commands, Godot paths, and
class names in English exactly as they appear in the repo.

## Source Of Truth

Use this priority order when writing or revising course material:

1. Current implementation and scenes in the repo.
2. Current runtime docs and generated API docs.
3. `udemy/README.md` and other course material.
4. Older plans, memory, or chat context.

For implementation facts, inspect the current files. Do not rely on stale paths
such as `game/demo/`; the current demo paths are defined by the live project.

## Course Design Rules

Keep the course practical and visible:

- Teach one necessary abstraction at a time.
- Show playable progress after each major system.
- Introduce reusable modules after the concrete gameplay need is clear.
- Explain framework boundaries with real files and scenes, not imaginary APIs.
- Keep the first course smaller than the full MKit framework.
- Save advanced systems for follow-up courses unless the current lesson needs
  them.

The teaching rhythm should stay close to:

```text
1. What You Will Build
2. High-Level Design
3. Core Concept
4. Implementation
5. Use It in the Demo Scene
6. Test, Debug, and Commit
```

## Architecture Claims

When course material describes the project architecture, preserve the core
separation:

```text
Game Content
  -> MKit Modules
  -> Kernel Runtime
```

The key gameplay pipeline is:

```text
Input / AI / Script
  -> GameCommand / CommandReceiver
  -> StateMachine / State
  -> GameAction / ActionService
  -> GameEffect / EffectService
  -> Domain service or component
  -> EventService
  -> UI / audio / VFX
```

If the live repo has added or refined a step, reflect the live repo rather than
copying an older outline.

## Course Artifacts

Prefer concrete, maintainable markdown artifacts over chat-only summaries.

Good course artifacts include:

```text
course brief
curriculum roadmap
lesson plan
recording script
teacher checklist
student assignment
chapter acceptance criteria
technical contract
demo-readiness review
production checklist
```

When creating a review, proposal, or planning document that contains follow-up
items, include a `## Progress Tracker` section and keep it updated as items are
resolved.

## Lesson Quality Bar

Each lesson should state:

- Learning goal.
- Student-visible result.
- Files or concepts introduced.
- Exact implementation boundary.
- Test, debug, or verification step.
- Suggested commit message when relevant.

Avoid long theory-only lessons. If a lesson introduces architecture, tie it to a
small Godot-visible result, a debug print, a scene behavior, or a test.

## Runtime Verification

For docs-only course changes, at minimum check the edited markdown for obvious
link/path/format mistakes.

When course material claims current runtime behavior, verify from source files,
scenes, tests, or existing docs. Use focused commands before broad gates.

Useful repo commands from the root include:

```bash
make demo-test       # headless playable-demo smoke test
make docs-check      # docs, generated API freshness, links, nav, cookbook checks
make layering        # dependency boundary check
make contract-check  # service ids, entity scene contracts, save ids/scopes
make ut              # addon unit tests
make int             # integration tests
```

Prefer explicit `--log-file /tmp/...` for direct headless Godot runs.

## Editing Rules

Keep edits scoped to the requested course artifact. Do not restructure
`udemy/README.md` or introduce a full course-doc hierarchy unless the user asks
for that work.

When adding new course files:

- Use clear filenames such as `lesson-01-overview.md` or
  `course-production-checklist.md`.
- Keep headings stable and skimmable.
- Use fenced code blocks for commands, Godot paths, and diagrams.
- Prefer specific file paths and acceptance criteria over vague guidance.
- Do not duplicate large sections of root docs when a short source-of-truth
  pointer is enough.

## Definition Of Done

Before reporting `udemy/` work as complete:

1. Confirm the change stayed inside the intended scope.
2. Confirm durable course artifacts are in English unless requested otherwise.
3. Confirm runtime claims were checked against the current repo when applicable.
4. Confirm no course-only content was added to `addons/mkit/`.
5. State which verification was run, or why no runtime verification was needed.
