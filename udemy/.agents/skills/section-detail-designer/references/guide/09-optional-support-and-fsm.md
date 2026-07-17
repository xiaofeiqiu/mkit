# Optional Support And FSM

Use this instruction for optional coverage, support videos, class ordering, and
state machine teaching choices.

## Class Video Ordering Rule

Every generated section design starts with:

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

## Optional Coverage Rule

Optional content must stay separate from required class videos.

In generated section designs:

- Put optional classes or artifacts under `Later or out of scope` in the
  relevant section or class file.
- Explain why they are optional.
- Explain when they should be included.
- Do not include optional content in required class contracts.
- Do not include optional content in required class videos.
- Do not generate a standalone `04-optional-coverage.md` file.

Use this shape when optional material needs a compact table:

```text
| Optional class/artifact | Why optional | When to include later |
| --- | --- | --- |
```

## State Machine Teaching Default Rule

Use flat FSM as the default teaching path for state behavior.

When generating a section design or class video that needs a state machine:

1. Use `Fsm` as the required/mainline state machine unless the requested section
   explicitly teaches hierarchical state behavior.
2. Use `FsmState` as the required/mainline base for player, enemy, idle, move,
   attack, cast, and other section states.
3. Treat `Hfsm` and `HfsmState` as optional/advanced coverage only.
4. Put HFSM material in `Later or out of scope`, or in an optional video only if
   the user explicitly approves it.
5. If a current demo source file still extends `HfsmState`, record that as a
   source correction and keep the generated course implementation scoped to
   `FsmState` unless the lesson goal is specifically HFSM.
6. Do not introduce parent/child state paths, active leaf state, or
   lowest-common-ancestor transitions in required class videos.
