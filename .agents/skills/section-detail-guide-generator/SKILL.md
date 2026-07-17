---
name: section-detail-guide-generator
description: Generate reusable section detailed design guide documents from course READMEs, curriculum outlines, technical plans, or project chapter lists. Use this skill when the user asks to create a guide for generating section detailed designs, lesson/section design guides, class-per-video course planning rules, or reusable course-design workflows from a source outline.
---

# Section Detail Guide Generator

Use this skill to create a **guide for generating section detailed designs**.
The output guide is not the detailed design itself. It tells future Codex runs
how to produce detailed designs section by section.

## Guide-Only Boundary

Focus on writing the guide. Do not generate concrete section detailed designs,
specific class implementation plans, full class contracts, lesson scripts, or
per-video implementation content while using this skill.

The guide may include templates, rules, coverage seeds, and a small mini example
that demonstrates the output shape. The mini example must stay small and must
not become a real section plan.

Only generate a concrete section detailed design if the user explicitly asks
for a specific section design in a separate request.

## Workflow

1. Locate the source outline. Prefer the path the user named, such as
   `README.md`, `udemy/README.md`, a curriculum roadmap, or a chapter list.
2. Read any local agent/project instructions before writing the guide.
3. Extract the section list, goals, visible results, and named classes or
   artifacts from the source outline.
4. Inspect live source files when the guide will mention current implemented
   classes. Treat source code as the implementation truth.
5. Create or update one durable guide file at the user-requested path.
6. Keep the guide generic. Do not expand every class into a full detailed
   design, implementation plan, or full script.
7. Run a markdown sanity check: no stale paths, no unresolved placeholders, no
   trailing whitespace.

## Output Shape

When generating a guide, include these sections:

- Progress Tracker
- Source Of Truth Rule
- Core Generation Rule
- Detailed Design Output Template
- Class Contract Template
- High-Level Class Talk Rules
- Read-Aloud Script Rules
- Section Coverage Seeds
- Mini Example
- Verification For The Guide Itself

Read `references/guide-template.md` when you need the exact reusable template.

## Required Rules To Encode

Every generated guide must encode these constraints:

- Every section detailed design starts with `Video 1: High-Level Class Design`.
- The high-level class design must include:
  - `What You Will Build`
  - `High-Level Design`
  - a Mermaid diagram showing class relationships, ownership, or runtime flow
  - a class responsibility table
  - one concrete example from the project
- Implementation lessons follow `one class = one video`.
- Each required class video focuses on exactly one required class.
- Optional coverage must not be folded into required class videos.
- Optional classes or artifacts go only in `Optional Coverage`, or in their own
  optional/support video if later approved.
- Scripts must be simple and concrete. If a technical term is used, define it
  immediately and explain it with a real example.
- Avoid abstract-only explanations such as "this improves decoupling" unless
  the guide also shows what no longer calls what.

## Source-Of-Truth Rules

Write the guide so future section designs verify against live project truth:

- The outline defines the course or project sections.
- Source files define current class names, paths, `extends`, fields, signals,
  and public functions.
- If the outline disagrees with source code, use source code and record the
  naming correction.
- If a class is planned but not implemented, mark it as planned.
- Keep reusable framework/library code separate from project-specific examples.

## Style Rules

Use plain instructional English for durable guide files unless the user asks for
another language. Chat with the user may be in their language.

For scripts inside the guide:

- Use short sentences.
- Explain terminology in the same paragraph.
- Prefer examples like "when the player presses Q..." or "when the app boots..."
  over abstract architecture descriptions.
- State what a class does not own when that prevents confusing boundaries.

## Section Coverage Seeds

When the source outline names classes per section, preserve that list as
coverage seeds rather than expanding every class contract. For each section,
include:

- required class videos;
- optional coverage;
- minimum detailed design expectation.

If the source outline does not list classes, derive conservative coverage seeds
from the described workflow and mark inferred classes clearly.

## Mini Example Pattern

Include a small example for one section only. The example should demonstrate the
guide format without becoming a full section design.

Example:

```text
Video 1: High-Level Class Design
Type: support
What You Will Build:
Students will build the runtime boot path that registers services and lets game
code access them through typed helpers.

Mermaid direction:
Show bootstrap registering services into a registry, and typed helpers reading
services from that registry.

Concrete example:
The app boots, registers combat, then a game script calls the typed helper
instead of searching the scene tree.
```

## Verification

Before finishing:

- Confirm the guide is not a full section detailed design.
- Confirm the guide does not contain concrete section plans or expanded class
  designs.
- Confirm every source-outline section has a coverage seed.
- Confirm the high-level class talk rule is present.
- Confirm optional coverage is excluded from required class videos.
- Confirm script style rules require simple language, term definitions, and
  concrete examples.
- Run `grep -n '[[:blank:]]$' <guide-path>` or an equivalent whitespace check.
