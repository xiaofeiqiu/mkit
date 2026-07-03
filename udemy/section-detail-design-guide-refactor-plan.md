# Section Detail Design Guide Refactor Implementation Plan

This plan describes how `udemy/section-detail-design-guide.md` was turned into
a high-level index while moving detailed instructions into focused child
markdown files.

## Progress Tracker

- [x] Confirm the target folder and child file names.
- [x] Create the child instruction folder.
- [x] Move detailed rules from the current guide into child markdown files.
- [x] Rewrite `udemy/section-detail-design-guide.md` as the index.
- [x] Check links, headings, stale references, and whitespace.
- [x] Update this tracker after the refactor is implemented.

## Final Decisions

- Use `udemy/guide/` as the child instruction folder.
- Keep section coverage seeds in one file:
  `udemy/guide/10-section-coverage-seeds.md`.
- Keep a compact generated-output tree in the main index so readers can see the
  target shape before opening detailed instructions.

## Current Problem

`udemy/section-detail-design-guide.md` previously mixed three jobs in one file:

1. It explained the high-level workflow for generating section detailed designs.
2. It defined detailed instructions for output folders, class design files,
   implementation files, script tone, MVP scoping, optional coverage, and
   verification.
3. It stored source-derived section coverage seeds for the course outline.

That made the guide hard to scan. Future users need an index first, then a clear
path into the detailed instruction that applies to the current task.

## Target Shape

Keep this file as the main entrypoint:

```text
udemy/section-detail-design-guide.md
```

Add a sibling instruction folder:

```text
udemy/guide/
```

The main guide is now an index. It contains only:

- purpose and guide-only boundary;
- source-of-truth priority;
- high-level generation workflow;
- "which instruction should I read?" index table;
- expected output tree summary;
- short verification checklist;
- links to child instruction files.

The child files own the detailed rules.

## File Map

```text
udemy/
  section-detail-design-guide.md
  guide/
    01-source-of-truth-and-boundary.md
    02-generation-workflow.md
    03-output-organization.md
    04-section-scope-and-mvp.md
    05-high-level-class-design.md
    06-class-design-md.md
    07-implementation-md.md
    08-script-writing.md
    09-optional-support-and-fsm.md
    10-section-coverage-seeds.md
    11-verification.md
```

## Validation Plan

Use lightweight markdown validation only:

```bash
find udemy/guide -type f -name '*.md' -print
grep -RIn "\\[.*\\](.*)" udemy/section-detail-design-guide.md udemy/guide
rg -n "TO""DO|TB""D|game[/]demo" udemy/section-detail-design-guide.md udemy/guide
grep -RIn '[[:blank:]]$' udemy/section-detail-design-guide.md udemy/guide
git diff --check -- udemy/section-detail-design-guide.md udemy/guide
```

No Godot runtime tests are required because this is a course-documentation
structure change only.
