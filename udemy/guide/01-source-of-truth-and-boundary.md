# Source Of Truth And Boundary

Use this instruction before generating or revising any section detailed design.

## Guide-Only Boundary

The section detail guide is generic course-production guidance. It may contain
rules, templates, checklists, and source-derived coverage seeds.

Allowed content:

- workflow steps for generating a section detailed design;
- source-derived section scope seeds that constrain future generated designs;
- reusable templates with placeholders;
- quality bars and verification checklists;
- small wording examples that demonstrate style without becoming a real plan.

Not allowed in the guide:

- concrete section plans;
- full production class contracts for real classes;
- real per-video implementation plans;
- standalone full read-aloud scripts for real classes;
- project-specific class relationship diagrams;
- generated source-check reports for a specific section.

Only generate a concrete section detailed design when the user explicitly asks
for a specific section or class slice.

## Source Of Truth Rule

Use this priority order when generating a concrete section detailed design:

1. Current source code and scenes.
2. Current runtime docs and generated API docs.
3. `udemy/README.md`.
4. Older planning notes, memory, or chat context.

`udemy/README.md` defines section intent. The live repository defines
implementation truth.

When generating a concrete section design:

1. Read the target section in `udemy/README.md`.
2. Inspect current source files for every class or artifact that will appear in
   that section.
3. Use live class names, paths, `extends`, exported fields, public state,
   signals, and public functions.
4. If README wording disagrees with live source, use live source and record the
   mismatch in the generated section design.
5. If a class is planned but not implemented, mark it as `planned`.
6. Keep reusable addon/framework code separate from game-specific examples.

## Runtime Boundary

Course artifacts live under `udemy/`.

Runtime framework code lives under `addons/mkit/`. Concrete demo game content
lives under `game/`. Do not hardcode course-only examples, fake APIs, demo
quests, enemies, rooms, shop prices, or other concrete content into
`addons/mkit/`.

When a course lesson describes runtime behavior, verify it from source files,
scenes, tests, or current docs before presenting it as fact.
