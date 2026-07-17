---
name: section-detail-designer
description: Generate Udemy section detailed design artifacts for mkit. Use this skill whenever the user asks for section detail design, class-per-video course docs, high-level class design, design.md, implementation.md, lesson scripts, or a section/class slice such as "section 2 class 1 and 2" under udemy. This skill must be used for concrete section detailed designs and should keep outputs under udemy/course/sections/.
---

# Section Detail Designer

Use this skill to generate concrete section detailed design artifacts for the
MKit Udemy course workspace.

The skill is backed by the guide index at
`references/section-detail-design-guide.md` and detailed instructions under
`references/guide/`.

## Boundary

Generate section detailed designs only when the user explicitly asks for a
specific section, class slice, or section-design output.

Do not generate all section designs unless the user explicitly asks for all
sections. Do not change runtime code, scenes, tests, or product docs unless the
user explicitly asks for implementation work.

Conversation with the user may be Chinese. Durable course artifacts must be
written in English unless the user asks otherwise.

## Required Reading

Before generating or revising section detailed design artifacts, read:

1. `udemy/AGENTS.md`
2. `references/section-detail-design-guide.md`
3. Relevant files under `references/guide/`
4. The requested section in `udemy/README.md`
5. Current source files for every class or artifact that appears in the
   generated section design

Always treat live source files and scenes as implementation truth. Use
`udemy/README.md` as course intent, not as proof of current runtime behavior.

## Workflow

1. Identify the requested section number, title, and class slice.
2. Read `references/guide/02-generation-workflow.md`.
3. Read `references/guide/10-section-coverage-seeds.md` for source corrections
   and course-scope boundaries.
4. Inspect live source files for the classes and artifacts used by the section.
5. Resolve README/source mismatches by using live source and recording the
   correction in the generated design.
6. Apply `references/guide/03-output-organization.md` for generated folder and
   file names.
7. Apply `references/guide/04-section-scope-and-mvp.md` before writing class
   implementation steps.
8. Write `01-high-level-class-design.md` first.
9. Create one `video-<vv>-<class-slug>/` folder per required class video.
10. Write each class `design.md` using
    `references/guide/06-class-design-md.md`.
11. Write each class `implementation.md` using
    `references/guide/07-implementation-md.md`.
12. Apply `references/guide/08-script-writing.md` to all spoken scripts.
13. Run the checks from `references/guide/11-verification.md`.

## Output Rules

Generated section designs go under:

```text
udemy/course/sections/
```

Each generated section should use this shape:

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

Do not generate section or class `README.md` files. Do not generate
`read-aloud-script.md`, `public-api.md`, or `verification.md` files.

## Quality Bar

- Start each generated section with Video 1: High-Level Class Design.
- Follow one required class = one class video.
- Keep optional classes out of required class videos.
- Write scripts for students who are past beginner basics but not yet
  intermediate. Prefer plain language, concrete examples, and short sentences
  over professional architecture vocabulary.
- Design scripts must identify one core design idea first, define the key
  domain noun, then connect it to the actual class and source path. For example,
  `ServiceRegistry` should be explained as a centralized mechanism for writing
  and reading shared services, and `service` should be defined with concrete
  examples such as random, scene, content, or event services.
- Use analogies only after the core idea is clear; analogies must not replace
  the real design point.
- Class `design.md` files must front-load class identity and public accessible
  fields, signals, and functions.
- Class `implementation.md` files must cover only current-video MVP scope.
- Treat MVP as section-local; defer later APIs as `future-section MVP` or
  `non-MVP`.
- Public API scripts must introduce what the public interface is used for
  before explaining arguments, returns, or implementation details.
- Put spoken explanations next to the design point or code snippet they
  explain.
- Put an explicit transition script between implementation steps, not only at
  the beginning and end of the video.
- Use flat `Fsm` / `FsmState` as the default state-machine teaching path unless
  the requested section explicitly teaches hierarchical state behavior.
