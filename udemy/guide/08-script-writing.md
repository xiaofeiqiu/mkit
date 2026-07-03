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

Rules:

- Write generated scripts in English.
- Use simple, direct language first.
- Use conversational tone.
- If a technical term is necessary, define it immediately.
- Explain the term with a concrete example from the section.
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
- plain English;
- natural transitions between ideas;
- concrete examples before abstract explanation;
- direct references to what students can see in the snippet;
- "we" language when walking through code together.

Avoid:

- API-reference prose;
- phrases like "this method is responsible for facilitating";
- dense architecture words without examples;
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

## Transition Rules

Required transition points:

- `01-high-level-class-design.md` must end with `Transition To First Class
  Video`.
- Each class `design.md` must include `Transition To Implementation`.
- Each `implementation.md` must start with `Opening transition`.
- Each implementation step script should end with a short transition to the
  next step unless it is the final check step.
- Each class `implementation.md` must end with `Next video transition`.

Good step-to-step transitions:

```text
Now that we have the storage, let's add the function that writes into it.
```

```text
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
