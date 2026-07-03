# High-Level Class Design

Every generated section detailed design starts with:

```text
Video 1: High-Level Class Design
Type: support
```

This is a concept/support video. It explains the shape of the section before
class-by-class implementation begins. It must not implement any class.

## Required File

Create this section-level file:

```text
01-high-level-class-design.md
```

Use this structure:

```text
# Video 1 - High-Level Class Design

## Section Goal

## What You Will Build

## Concepts Students Need First

For each important concept:

- Concept name:
- Simple explanation:
- Everyday example:
- How it appears in this section:

## Class Responsibilities

| Class | Responsibility | Main capability | Does not own |
| --- | --- | --- | --- |

## How The Classes Work Together

## Concrete Example

## High-Level Design Script

<one or two short spoken paragraphs that introduce the section goal, the main
concept, and the visible result in easy language. Do not explain each class in
detail here. Move per-class explanation into that class folder's design.md.>

## Transition To First Class Video

<one or two spoken sentences that name the first class video and explain why it
comes first>
```

## High-Level Requirements

The high-level class design must include:

1. `Section Goal`
2. `What You Will Build`
3. `Concepts Students Need First`
4. `Class Responsibilities`
5. `How The Classes Work Together`
6. `Concrete Example`
7. `High-Level Design Script`
8. `Transition To First Class Video`

The high-level talk must not require a Mermaid diagram. Use a diagram only if
the requested section truly benefits from it and it does not distract from the
class-by-class teaching path.

## Script Boundary

The high-level script is the teacher's opening concept explanation. It should be
one or two short spoken paragraphs.

It should help students understand:

- the section goal;
- the main concept introduced by the section;
- the visible runtime result students should expect.

It may name required classes as a quick preview, but it must not explain each
class in detail. Per-class explanations belong in the relevant
`video-<vv>-<class-slug>/design.md` file.

Good concept explanation pattern:

```text
In this section, we are building the startup layer of the runtime. Before we get
to combat or quests, the game needs a reliable way to create shared services,
register them, and reach the first scene. Think of it like opening a shop in
the morning: we turn on the core systems first, then the rest of the day can
happen.
```

Bad concept explanation pattern:

```text
This architecture improves decoupling and modularity.
```

## Class Responsibility Table Rule

Use this table:

```text
| Class | Responsibility | Main capability | Does not own |
| --- | --- | --- | --- |
```

The table should explain class roles in plain teaching language. Do not copy
source comments into the table. Do not turn the table into an API reference.

## Concrete Example Rule

Every generated section design must include one concrete example from the
target section's intended demo or runtime flow.

Good example shape:

```text
When <user/runtime action> happens, <Class A> creates/updates <data>, then
<Class B> uses that data, then <Class C> produces the visible result.
```

Avoid abstract-only explanations such as:

```text
This section improves decoupling and domain boundaries.
```
