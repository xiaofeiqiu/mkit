# Implementation.md

Use this instruction for each required class folder's `implementation.md`.

## Purpose

`implementation.md` explains the step-by-step implementation for the current
class video. It must implement only the current-video MVP scope from
`design.md`.

Do not include code snippets, step-by-step coverage, or detailed scripts for
future-section MVP or non-MVP APIs. A short sentence can mention deferred APIs
only when that prevents confusion.

## Required Structure

Use this template:

````text
# <ClassName> Implementation

Opening transition:
<one or two spoken sentences that connect from the previous video or high-level
talk into this class video>

Step 1. Add <small first increment>.

Code:
```gdscript
<code students add in this step>
```

Script:
<spoken explanation of the snippet above: purpose, key data or boundary, one
important guard or decision, and result.>

Transition to Step 2:
<one or two spoken sentences that explain why the next step naturally follows
from this one.>

Step 2. Add <small next increment>.

Code:
```gdscript
<code students add in this step>
```

Script:
<spoken explanation of the snippet above: purpose, key data or boundary, one
important guard or decision, and result.>

Transition to Step 3:
<one or two spoken sentences that connect the code just written to the next
implementation or check step.>

Step 3. Check <visible result or test assertion>.

Script:
<short spoken explanation of what this check proves>

Next video transition:
<one or two spoken sentences that name the next class video and explain how it
builds on this class. If this is the last class in the section, transition to
the section result or the next section.>
````

## Increment Rules

Each implementation step should be small enough to teach directly:

- class shell and responsibility;
- minimal fields needed for the section goal;
- first public function or callback that makes the class useful;
- smallest integration point needed for the visible result;
- check step that proves the increment works.

Do not compress a long class into one video by listing every final method in
source order. If the real class is large, generate a smaller section-scope
version and defer advanced methods to later sections or optional coverage.

## Transition Script Rules

Every implementation file must include explicit transition script blocks between
steps:

```text
Transition to Step 2:
<spoken transition>
```

Use transitions to explain why the next step is needed. Do not rely on the last
sentence of the previous script only. A good transition names the result of the
current step and the missing piece that the next step adds.

Good transition:

```text
Now we have a place to store services. The next step is to add the function
that writes one service into that table.
```

Bad transition:

```text
Next, we continue.
```

## Snippet Rules

Every code snippet must use dependencies that are:

- already introduced;
- introduced in the current video; or
- narrowly scoped ready support.

Do not instantiate, register, configure, or call future-section MVP or non-MVP
dependencies in implementation snippets.

The final step should include a small check or visible result that proves the
class video worked. The check can be a log line, scene behavior, focused test
assertion, or observable gameplay result.
