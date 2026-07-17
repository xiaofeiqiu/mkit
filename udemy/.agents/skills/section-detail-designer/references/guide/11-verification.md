# Verification

Use this instruction before reporting guide changes or generated section
designs as complete.

## Verification For This Guide

Before reporting guide or instruction-file edits as complete:

1. Confirm the main guide is still an index, not a generated section design.
2. Confirm child files contain detailed instructions, not full real class
   implementations.
3. Confirm source-derived coverage seeds are boundaries, not generated section
   folders.
4. Confirm source-of-truth rules are explicit.
5. Confirm high-level class design rules are explicit.
6. Confirm `design.md` structure rules require class name, source path, exact
   `extends`, section goal, purpose, and public API sections.
7. Confirm `design.md` public API tables stay factual and move explanation into
   scripts.
8. Confirm MVP API selection rules split current-video MVP, future-section MVP,
   and non-MVP source behavior.
9. Confirm generated `implementation.md` rules cover current-video MVP APIs
   only.
10. Confirm dependency readiness rules prevent code snippets from registering or
    calling services that have not been introduced or needed.
11. Confirm optional coverage is excluded from required class videos.
12. Confirm script rules require simple language, term definitions, concrete
    examples, and embedded script placement.
13. Confirm script rules name the target student level: more than beginner,
    less than intermediate.
14. Confirm design-script rules require the core mechanism and concrete examples
    before analogy or professional architecture terms.
15. Confirm design-script rules require enough detail for the target student
    level, not a one-sentence architecture summary.
16. Confirm design-script rules require one core design idea, a definition of
    the key domain noun, and concrete source or section examples before API
    walkthrough.
17. Confirm public API script rules require purpose-first API explanations.
18. Confirm implementation rules require explicit transition blocks between
    steps.
19. Confirm generated content organization defines section folders, class
    subfolders, folder names, and file names.
20. Confirm class folder rules use only `design.md` and `implementation.md`.
21. Confirm generated section-level rules do not require obsolete extra files.
22. Run markdown sanity checks.

Suggested checks:

```bash
grep -RIn '[[:blank:]]$' udemy/.agents/skills/section-detail-designer/SKILL.md udemy/.agents/skills/section-detail-designer/references
rg -n "TO""DO|TB""D|game[/]demo" udemy/.agents/skills/section-detail-designer/SKILL.md udemy/.agents/skills/section-detail-designer/references
git diff --check -- udemy/.agents/skills/section-detail-designer
```

## Verification For Generated Section Designs

When a concrete section design is generated later:

1. Re-open the relevant README section.
2. Re-open current source files for every required class.
3. Confirm class names and paths exist or are marked planned.
4. Confirm public APIs match live source.
5. Confirm every candidate field, signal, public function, callback, and
   override hook is classified as current-video MVP, future-section MVP, or
   non-MVP for the section result.
6. Confirm each class `design.md` starts with `Class Identity`.
7. Confirm each class `design.md` has separate `Public Accessible Fields`,
   `Public Accessible Signals`, and `Public Accessible Functions` sections.
8. Confirm public API tables are factual and do not contain long teaching
   explanations.
9. Confirm `Public API Script` explains the meaning of every MVP public API in
   conversational language.
10. Confirm every MVP public API explanation starts by saying what that public
    interface is used for.
11. Confirm each class `design.md` contains current-video MVP,
    future-section MVP, and non-MVP sections when those categories exist.
12. Confirm future-section MVP entries name the likely later section when that
    can be inferred.
13. Confirm each class `design.md` includes dependency readiness when the class
    creates, registers, calls, or configures collaborators.
14. Confirm each class `implementation.md` implements only current-video MVP
    scope.
15. Confirm implementation snippets do not instantiate, register, or call
    services or collaborators that are not ready for this section result.
16. Confirm no future-section MVP or non-MVP API has code snippets or detailed
    implementation scripts in the current `implementation.md`.
17. Confirm optional content is separate.
18. Confirm the high-level class design script uses easy language, starts from
    an analogy or concrete runtime situation, and does not explain every class
    in detail.
19. Confirm each class `Design Script` states the core design idea, defines the
    key domain noun, and gives concrete examples before listing API names.
20. Confirm each class `design.md` explains what the class owns, what it does
    not own, and how it relates to nearby classes.
21. Confirm each class video states the target section goal and section-scope
    increment.
22. Confirm large current-source classes defer later behavior instead of
    implementing everything in one video.
23. Confirm scripts are concrete, easy to read aloud, and embedded near the
    design point or code snippet they explain.
24. Confirm scripts include required opening, between-step, and closing
    transitions.
25. Confirm code-related scripts stay concise and focus on purpose, key data or
    boundary, one important guard or decision, and the result.
26. Confirm the generated section uses one section folder.
27. Confirm each required class video has one class subfolder.
28. Confirm each class subfolder contains only `design.md` and
    `implementation.md`.
29. Confirm generated section folders and class subfolders do not contain
    `README.md`.
30. Confirm generated class subfolders do not contain `verification.md`,
    `public-api.md`, or `read-aloud-script.md`.
