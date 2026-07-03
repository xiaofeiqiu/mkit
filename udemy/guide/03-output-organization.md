# Output Organization

Use this instruction for generated section detailed design folders and files.

## Generated Content Root

Generated section designs live under:

```text
udemy/course/sections/
```

Use one folder per generated section:

```text
udemy/course/sections/section-<nn>-<section-slug>/
```

Folder naming rules:

- `<nn>` is the two-digit section number from `udemy/README.md`.
- `<section-slug>` is a short lower-kebab-case version of the section title.
- Use only lowercase letters, numbers, and hyphens.
- Keep the section folder name stable after generation.
- Do not put a concrete class name in the section folder name.

## Required Section Shape

Each generated section folder must use this shape:

```text
section-<nn>-<section-slug>/
  01-high-level-class-design.md
  video-02-<class-a-slug>/
    design.md
    implementation.md
  video-03-<class-b-slug>/
    design.md
    implementation.md
```

`01-high-level-class-design.md` is the section-level entrypoint and contains
Video 1: High-Level Class Design.

Do not generate these section-level files:

- `README.md`
- `01-source-check.md`
- `03-video-plan.md`
- `04-optional-coverage.md`
- `05-demo-integration.md`
- `06-tests-or-verification.md`

## Class Folder Rules

Create one direct class subfolder for each required class video.

Class subfolder names use:

```text
video-<vv>-<class-slug>/
```

Rules:

- `<vv>` is the two-digit video number for that class video.
- `<class-slug>` is the current class name converted to lower-kebab-case.
- Keep every class subfolder directly under the section folder.
- Put all files for that class inside its class subfolder.
- Do not nest class subfolders inside other class subfolders.
- Do not combine multiple required classes in one class subfolder.
- Do not put optional classes in required class subfolders.

Class folders contain only:

- `design.md`
- `implementation.md`

Do not create these class files:

- `README.md`
- `verification.md`
- `public-api.md`
- `read-aloud-script.md`

Optional subfolders are allowed only if the user explicitly asks for optional
videos to become generated artifacts.
