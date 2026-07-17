# Lesson Template Reference

Use this template for each lesson in a project-based Udemy course.

## Lesson Title

Use a title that describes the student-visible result, not only the internal concept.

Good:

```text
Move the Player with Commands and State Machines
Build the First Login Flow
Create a Data-Driven Fireball Ability
```

Weak:

```text
CommandService Part 1
Architecture Overview 3
Refactor Files
```

## Required Lesson Structure

```text
1. What You Will Build
2. High-Level Design
3. Core Concept
4. Implementation
5. Use It in the Demo
6. Test, Debug, and Commit
```

## Lesson Design Checklist

A lesson is strong if it has:

- one clear outcome,
- one main concept,
- one visible result,
- a clear connection to the final project,
- a small assignment,
- and a checkpoint commit.

## Coding Lesson Flow

```markdown
### What You Will Build

By the end of this lesson, the student will have:

- ...
- ...

### High-Level Design

Show the flow before writing code.

```text
A → B → C → D
```

### Core Concept

Explain the mental model.

### Implementation

Write or modify the smallest useful set of files.

### Use It in the Demo

Run the app/game and show visible progress.

### Test, Debug, and Commit

Run tests or perform a manual smoke test.

```bash
git add .
git commit -m "course: add <feature>"
```
```

## Avoid

- Multiple unrelated features in one lesson.
- More than 15–20 minutes without visible progress.
- Teaching implementation details before students understand why the feature exists.
- Ending a lesson without a runnable result.
