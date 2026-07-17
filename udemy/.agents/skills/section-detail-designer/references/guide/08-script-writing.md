# Script Writing

Use this instruction for spoken scripts embedded in generated section designs.

## Embedded Script Rules

Do not create standalone script files for class videos. Generated class folders
must not include `read-aloud-script.md`.

Scripts must be embedded where the teacher needs them:

- In `design.md`, include `Design Script` after the class design and
  `Public API Script` after the public accessible API tables.
- In `implementation.md`, include a script immediately after each code snippet
  or check step.
- Do not put all script text at the end of the file.

Scripts must be simple enough to read while recording. They should sound like a
teacher explaining code live, not like API documentation.

## Target Student Level

Write scripts for students who are more than absolute beginners, but less than
intermediate.

Assume students can:

- read basic GDScript;
- understand nodes, resources, scenes, exported fields, and signals;
- follow one small class at a time.

Do not assume students already understand:

- service registry;
- facade;
- composition root;
- event bus;
- payload;
- dependency injection;
- lifecycle hook;
- decoupling.

When one of these terms is useful, explain it with a simple analogy or concrete
project action before using it as a formal term.

Rules:

- Write generated scripts in English.
- Use simple, direct language first.
- Use conversational tone.
- In `Design Script`, identify one core design idea before explaining fields,
  functions, or implementation details.
- Define the key domain noun for the class before using it heavily. For example,
  define what a service is before explaining `ServiceRegistry`.
- Use one or two concrete examples from current source or the section goal
  before using abstract architecture language.
- If a technical term is necessary, define it immediately.
- Explain the term with a concrete example from the section.
- Use an analogy only after the core mechanism and concrete example are clear.
- Prefer concrete runtime actions over abstract architecture language.
- Start with the class responsibility.
- Name the source path.
- State the `extends`.
- Add fields before functions.
- Explain only current-video MVP APIs in implementation scripts.
- Do not include code snippets or detailed implementation scripts for
  future-section MVP or non-MVP APIs.
- Explain how the class connects to the visible result.
- State what the class deliberately does not own.
- Use current source names and paths.

## Conversational Tone

Generated scripts should sound like a clear teacher walking through code:

- short spoken paragraphs;
- simple words before professional terms;
- plain English;
- natural transitions between ideas;
- concrete examples before abstract explanation;
- analogies that support the real mechanism instead of replacing it;
- direct references to what students can see in the snippet;
- "we" language when walking through code together.

Avoid:

- API-reference prose;
- phrases like "this method is responsible for facilitating";
- dense architecture words without examples;
- professional summary phrases such as "centralizes dependency access",
  "improves decoupling", or "encapsulates lifecycle orchestration" unless they
  are immediately translated into plain language;
- repeating code line by line without explaining why the line exists;
- summaries so short they skip the key idea or important guard.

Good tone:

```text
Here we register one service by id. The registry is just a lookup table: the id
is the key, and the service object is the value. The important guard is that we
reject empty ids and null services before touching the table.
```

Bad tone:

```text
This method performs service registration and input validation for runtime
dependency management.
```

## Design Script Focus

`Design Script` should explain the main design concept, not merely introduce
the class name. For each class, choose one focus:

- centralized read/write access;
- intent message;
- runtime state owner;
- content definition;
- executor service;
- typed facade;
- scene/component controller;
- event publisher or listener.

After choosing the focus, define the important noun and give concrete examples.
For `ServiceRegistry`, the focus is centralized read/write access to services.
A service is a shared runtime object with one job, such as `RandomService` for
randomness, `SceneService` for changing scenes, `ContentService` for loaded
definitions, or `EventService` for gameplay events. Only after that should the
script talk about the class path, `extends`, collaborators, and API names.

Avoid scripts that only say a class is "a front desk", "a manager", or "a
coordinator". Those analogies can help, but they must be attached to the real
mechanism students need to understand.

## Transition Rules

Required transition points:

- `01-high-level-class-design.md` must end with `Transition To First Class
  Video`.
- Each class `design.md` must include `Transition To Implementation`.
- Each `implementation.md` must start with `Opening transition`.
- Each implementation step must be followed by an explicit transition block
  named `Transition to Step N:` unless the next block is `Next video
  transition`.
- Each class `implementation.md` must end with `Next video transition`.

Transition blocks are part of the read-aloud script. They should not be hidden
inside the previous paragraph. Use them to connect the student's mental model:
"we now have X, so next we add Y."

Good step-to-step transitions:

```text
Transition to Step 2:
Now that we have the storage, let's add the function that writes into it.
```

```text
Transition to Step 3:
Next, let's add the lookup side, so other code can read from this table.
```

Good class-to-class transition:

```text
In the next video, we will start building `GameBootstrap`, because now we need a
class that fills this registry.
```

Avoid generic transitions:

```text
Next, we continue.
```

## Code Snippet Script Granularity

Code-related scripts in `implementation.md` must be concise. They should
explain the key teaching point of the snippet, not narrate every line.

For each meaningful code block, usually explain only:

1. The purpose of this step.
2. The one data shape or boundary students must understand, if any.
3. The most important guard, decision, or ownership rule.
4. The visible result, test assertion, or transition to the next step.

Most implementation scripts should be 3-6 short sentences. A larger snippet may
need two short paragraphs, but it should still avoid line-by-line narration.

Good `implementation.md` script:

```text
This function registers one service in the lookup table. The key is the service
id, and the value is the service object. The important part is the guard before
the write: bad ids, null services, and accidental duplicates should fail early.
```

Bad script:

```text
First this line strips the string. Then this line checks the empty string. Then
this line prints the warning. Then this line returns.
```
