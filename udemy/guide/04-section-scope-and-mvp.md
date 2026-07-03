# Section Scope And MVP

Use this instruction to keep generated class videos section-sized instead of
copying full production classes.

## Section Goal Scope Rule

The current source shows implementation truth. The target section goal decides
how much of that implementation should be introduced in this section.

When generating a concrete class video:

1. Restate the target section goal and student-visible result before choosing
   the class scope.
2. Identify the smallest useful version of the class that helps produce that
   section result.
3. Classify each candidate field, signal, function, helper, callback, and
   override hook as current-video MVP, future-section MVP, or non-MVP.
4. Classify each collaborator or service dependency before adding code that
   creates, registers, calls, or configures it.
5. Include only the fields, signals, functions, helpers, and dependencies
   needed for that section goal.
6. If the live class already contains behavior for later sections, record that
   behavior as `Future-section MVP`, `Non-MVP`, or `Later or out of scope`.
7. Do not implement the full current production class just because source code
   already contains it.

Good scope statement:

```text
This video introduces only the boot-time service registration path needed for
Section 2. Save loading and audio definition registration exist in the current
source, but they are later increments unless the Section 2 visible result needs
them.
```

Bad scope statements:

```text
Implement every method from the current class now.
```

```text
Register the full production service map now because the live source does it.
```

## MVP API Selection Rule

Generated class videos must teach the minimum useful API for the section result,
not every public function that exists in source.

MVP is section-local. A field, function, or behavior can be non-MVP for the
current class video and still become MVP in a later section. Do not mark an API
as "never teach" just because it is not needed now. Record the likely future
section when the source and course outline make that clear.

Use these categories:

- `MVP`: required for the current section goal or visible result.
- `Future-section MVP`: not needed now, but likely required by a later
  section's goal, visible result, or integration step.
- `Non-MVP`: real source behavior that is not needed for the current result or
  a known later section.

Ask these questions before classifying an API:

1. Does the section result fail without this API?
2. Will students call this API in the class video or next immediate integration
   step?
3. Does this API introduce a concept the section intentionally teaches now?
4. Does a later section in `udemy/README.md` clearly need this API?
5. Is this API mostly for reset, cleanup, tests, editor convenience, debugging,
   advanced extension, or future modules?

If the answer is yes to question 4 and no to questions 1 through 3, classify it
as `Future-section MVP`. If the answer is yes to question 5 and no to questions
1 through 4, classify it as `Non-MVP`.

The generated `design.md` must contain MVP, future-section MVP, and non-MVP
sections when those categories exist. The generated `implementation.md` must
implement only the current-video MVP scope.

## Dependency Readiness And Staged Service Rule

Generated implementation plans must not instantiate, register, configure, or
call collaborators just because the live production source does so.

For every dependency that appears in a code snippet, classify it as:

- `Already introduced`: students built it in an earlier video.
- `Introduced now`: the current class video teaches it directly.
- `Ready support`: it can be used as a small support object because its behavior
  is not the lesson focus and is already understandable.
- `Future-section MVP`: real source behavior, but a later section teaches the
  class or feature that makes it meaningful.
- `Non-MVP`: source behavior not needed for the course mainline.

Only `Already introduced`, `Introduced now`, and narrowly scoped
`Ready support` dependencies may appear in `implementation.md` code snippets.

If a production class builds a large service map, component list, resource list,
or module list, scope it down to dependencies ready for the current section
result. The full production list belongs in `Future-Section MVP`,
`Non-MVP Source Behavior`, or `Later or out of scope`.

Good staged-service rule:

```text
In an early bootstrap lesson, register only the services that students have
already built or that are required for the visible boot check. Do not register
action, effect, command, save, audio, combat, quest, loot, or world services
before those systems are taught or needed.
```

When a deferred dependency appears in live source, explain it briefly in
`design.md`:

```text
The production source also registers later services here. The course version
does not instantiate them yet because students have not built those systems and
the Section 2 result does not need them.
```

## Incremental Class Introduction Rule

A generated class video should teach the class as an incremental build, not as
one large final implementation dump.

For each required class video, split implementation into small teaching
increments:

1. Class shell and responsibility.
2. Minimal fields needed for the section goal.
3. First public function or callback that makes the class useful.
4. Smallest integration point needed for the visible result.
5. Check step that proves the increment works.
6. Optional or later behavior clearly deferred out of the current video.

Each increment should answer:

- What are students adding now?
- Why does this step belong in this section?
- What visible behavior, log line, test assertion, or scene change proves it?
- What part of the full class is intentionally not introduced yet?
- If a deferred API is likely a future-section MVP, which later section should
  own it?
