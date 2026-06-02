# mkit code style, .uid files, and docs

The conventions that make a change look like it was always part of the codebase.
When unsure, open the nearest existing file and mirror it — consistency here is a
feature, not a preference.

## Contents
- [GDScript style](#gdscript-style)
- [The comment-free rule](#the-comment-free-rule)
- [.uid files](#uid-files)
- [Scenes (.tscn) and resources](#scenes-tscn-and-resources)
- [Keeping docs in sync](#keeping-docs-in-sync)
- [Language policy for docs](#language-policy-for-docs)

## GDScript style

- **GDScript 2.0, strongly typed.** Type every variable, parameter, and return.
  Use `:=` for inferred locals, explicit `: Type` on fields and signatures.
  ```gdscript
  var entity_id: String = ""
  var tags: Array[String] = []
  func can_cast(context: GameplayContext) -> bool:
      return true
  ```
- **`class_name` + `extends`.** Core files declare `class_name Xxx` and
  `extends XxxBase` so types are globally referenceable (tests and other modules
  rely on this).
- **Tabs for indentation** (Godot standard). `.editorconfig` sets UTF-8; line
  endings are normalized to LF via `.gitattributes`.
- **No bare `Dictionary` through core APIs.** A payload Dictionary is tolerable
  at the very edge, but wrap it in a typed object before it crosses a public
  boundary — passing loose dicts around defeats the type safety the rest of the
  framework leans on.
- **Private members** are prefixed with `_` (`_default`, `_roll_chance`), and
  shared singletons are often exposed via a `static func get_default()` rather
  than constructed everywhere.

## The comment-free rule

The addon source is **deliberately comment-free** — all `.gd` files under
`addons/mkit/` contain zero comments (verified: a grep for comment lines returns
0). Names and types are expected to carry the meaning. **Do not add explanatory
comments to addon code**, even when it feels helpful; it will be stripped and it
breaks the house style.

Two tools enforce/clean this (both default to the `addons/mkit` root, or take a
path arg):

```bash
python3 tools/strip_comments.py [path]   # strip all # and ## comments (string-literal aware)
python3 tools/clean_comments.py [path]   # remove auto-generated doc comment blocks + headers
```

`clean_comments.py` exists because generated code may include doc comment blocks;
it removes them so the committed source stays clean. If you ever generate code,
run the cleaner before committing.

Note this rule is scoped to the **addon**. Test helpers and `game/` may carry the
occasional comment, but the prevailing style is still terse and self-describing —
match the file you're in.

## .uid files

Godot 4.4+ assigns every script a stable UID stored in a sibling `<file>.gd.uid`
(and resources get `.tres`/`.tscn`-level UIDs). These files **are committed** —
there are ~225 of them in the repo, and scenes reference scripts by UID, so a
missing `.uid` can break a scene load or a typed reference.

Workflow when you add a new `.gd`:
1. Write the script.
2. Let Godot generate the `.uid` by importing the project once — running
   `make ut` headless is the simplest trigger.
3. Commit the `.gd` **and** its generated `.gd.uid` together.

Never hand-author a UID value, and don't delete a `.uid` without deleting (or
regenerating) its script — a dangling reference is worse than a missing file.

## Scenes (.tscn) and resources

- Entities follow the fixed node layout (`EntityIdentity`, `Components/`,
  `Controllers/`, `Presentation/`) — see `references/architecture.md`. Modules
  locate siblings by hardcoded relative paths from `owner`, so the layout is load-
  bearing.
- Concrete game content is authored as Resources under `game/` and loaded via
  `ResourceDatabase` → `ContentRegistry`, never hardcoded into addon scripts.
- `.tscn`/`.tres` are text and diffable — prefer small, reviewable scene changes
  and keep generated `.import`/`.uid` siblings in the commit.

## Keeping docs in sync

When you change a public interface, update the docs so the generated reference
stays truthful:

- `docs/ref/<ClassName>.md` — one file per class. Mirror the existing section
  structure exactly:
  ```
  # ClassName
  ## 概念说明      (what it is / why it exists)
  ## 设计目的      (design intent)
  ## 文件          (res:// path to the source)
  ## 接口          (```gdscript class_name / extends / public funcs ```)
  ## 函数使用场景   (per-function: when/why each is called)
  ## 使用示例      (```gdscript usage example ```)
  ```
- Layer/pipeline overviews — `docs/kernel_layer.md`, `docs/module_layer.md`,
  `docs/platform_adapter_layer.md`, `docs/pipeline.md`. If you add a new pipeline
  or a new class to a layer, add it here with a link to its ref doc.
- Preview docs locally with `make docs-server` (serves `docs/` at
  http://localhost:8060).

Scope the update to what actually changed — a renamed method means fixing the
`## 接口` and `## 函数使用场景` entries, not rewriting the file.

## Language policy for docs

The docs are **bilingual**: Chinese for conceptual prose (概念说明 / 设计目的 /
function-purpose notes), English for code, identifiers, and file paths. The rule
is **match the file/section you're editing** — keep Chinese where it already is,
keep code and identifiers English, and don't translate an existing Chinese
section into English (or vice versa) as a side effect of a code change. New files
mirror the structure and language mix of their nearest sibling. This keeps the
corpus consistent for the people who maintain it.
