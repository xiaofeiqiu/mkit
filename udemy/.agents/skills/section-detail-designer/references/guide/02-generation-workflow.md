# Generation Workflow

Use this workflow only after the user asks for a concrete section detailed
design. Do not generate all section designs unless the user explicitly asks for
all of them.

## Workflow

1. Identify the requested section or class slice.
2. Read only the relevant section from `udemy/README.md`.
3. Extract the section goal, student-visible result, named classes, artifacts,
   and support work.
4. Inspect current source files for every class or artifact that will appear in
   the generated section.
5. Use the section goal and visible result to shrink the scope for every class
   video.
6. Classify every candidate field, signal, function, callback, and override hook
   as current-video MVP, future-section MVP, or non-MVP.
7. Classify every collaborator, service, resource, helper, scene, or support
   artifact used by implementation snippets as already introduced, introduced
   now, ready support, future-section MVP, or non-MVP.
8. Decide which classes are required, optional, planned, or support-only.
9. Create one section design folder under `udemy/course/sections/`.
10. Keep the generated section design focused on that section only.
11. Run the markdown checks from `11-verification.md`.

## Required Inputs

Before writing generated files, collect:

- section number and title;
- section goal;
- student-visible result;
- required class list;
- optional or support artifacts;
- current source paths;
- source corrections where README names differ from live code;
- likely later sections for deferred APIs.

## Output Discipline

Generated designs should be durable markdown artifacts, not chat-only plans.

Keep generated content in English unless the user explicitly asks otherwise.
Use exact code identifiers, paths, commands, and class names from the repo.

Do not create runtime code, tests, scenes, or docs outside `udemy/` unless the
user explicitly asks for implementation work.
