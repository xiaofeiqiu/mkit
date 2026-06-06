# Testing mkit (GUT)

All tests use [GUT](https://github.com/bitwes/Gut). They are the gate on "done" —
a change to addon behavior ships with a test, and you run the suite and report
the real result before claiming success.

## Contents
- [Running tests](#running-tests)
- [Where tests live and how they're named](#where-tests-live-and-how-theyre-named)
- [The standard test shape](#the-standard-test-shape)
- [Determinism: stub the random service](#determinism-stub-the-random-service)
- [Docs sync](#docs-sync)
- [Debugging a failing test](#debugging-a-failing-test)

## Running tests

```bash
make ut            # full suite: kernel + modules
make ut-kernel     # kernel only  (test/unit/kernel)
make ut-modules    # modules only (test/unit/modules)
make int           # integration  (test/integration)
make reimport      # rebuild Godot's import / global-class cache (rarely needed by hand)
```

`ut`, `ut-kernel`, `ut-modules`, and `int` each depend on `reimport`, which runs
`$GODOT --headless --import` (and clears `test/integration/tmp_mkit_int_*.tscn`
debris) **before** the suite. That guarantees every `make` run starts from a fresh
`.godot` cache, so a previously crashed run can't leave a stale cache that breaks
the next one (see Debugging). The **direct `-gtest` form below skips this** — if it
hits cache cascades, run `make reimport` first.

The engine binary comes from the `GODOT` env var (the Makefile defaults to the
macOS app path). This is a **Godot 4.7-dev** project — point `GODOT` at a matching
4.7 build or GUT may fail to load:

```bash
GODOT=/path/to/Godot_4.7 make ut
```

Run a single test file or a single test (calling GUT directly):

```bash
$GODOT --headless -s addons/gut/gut_cmdln.gd \
  -gtest=res://test/unit/modules/test_combat_resolver.gd -gexit

$GODOT --headless -s addons/gut/gut_cmdln.gd \
  -gtest=res://test/unit/modules/test_combat_resolver.gd \
  -gunit_test_name=test_tc_cmbt_05 -gexit
```

Use the single-file form while iterating — it's much faster than the whole suite —
then run `make ut` before declaring done.

## Where tests live and how they're named

```
test/unit/kernel/    test_<class>.gd   # kernel classes
test/unit/modules/   test_<class>.gd   # module classes
```

- Files `extends GutTest` and are named `test_<thing>.gd`.
- Test methods are named `test_tc_<area>_<nn>_<description>`, e.g.
  `test_tc_cmbt_01_null_source_returns_zero_damage`. The `<area>` is a short tag
  per system; existing ones include `sr` (service registry), `cr` (command
  router), `er` (event router), `ee` (effect executor), `ar` (action runner),
  `sm` (state machine), `cmbt` (combat), `ab` (ability), `inv` (inventory),
  `loot`, `prog` (progression), `rwd` (reward), `rc` (room controller), `rd`
  (run director), `es` (entity spawner). Reuse the matching tag; the `<nn>` is a
  zero-padded sequence within the file.

## The standard test shape

Copy the nearest existing test file rather than starting blank. The house style:

```gdscript
extends GutTest


# Mock collaborators are INNER CLASSES, not GUT doubles — doubles don't play
# well with typed GDScript here, so subclass the real type and override.
class FixedRandom:
	extends RandomService
	var fixed_value: float = 0.0
	func randf() -> float:
		return fixed_value


var resolver: CombatResolver


func before_each() -> void:
	resolver = CombatResolver.new()        # fresh instances each test


func after_each() -> void:
	ServiceRegistry.clear()                # always reset global registry state


func test_tc_cmbt_01_null_source_returns_zero_damage() -> void:
	var req := DamageRequest.new()
	# ... arrange ...
	var result := resolver.resolve(req)
	assert_eq(result.final_amount, 0.0)
	assert_true(result.trace.has("failure"))
```

Conventions in force across the suite:
- **Setup/teardown:** `before_each()` builds fresh instances;
  `after_each()` calls `ServiceRegistry.clear()` so global state never leaks
  between tests.
- **Node lifecycle:** add scene-tree nodes with `add_child_autofree(node)` so GUT
  frees them automatically.
- **Mocks:** inline `class X: extends <RealType>` inner classes that override the
  methods you need. Don't reach for GUT doubles.
- **Assertions actually used:** `assert_eq`, `assert_true`, `assert_false`,
  `assert_null`, `assert_not_null`, and for signals `watch_signals(obj)` +
  `assert_signal_emitted` / `assert_signal_emitted_with_parameters` /
  `assert_signal_not_emitted` / `assert_signal_emit_count`.
- For entities, build the minimal node layout the system under test expects
  (e.g. `Components/StatsComponent`) — see `_make_entity_with_stats()` helpers in
  the existing tests and the entity layout in `references/architecture.md`.

## Determinism: stub the random service

Anything that rolls (`randf`, `randi_range`, `randf_range`) must be made
deterministic by injecting a seeded/fixed `RandomService` subclass, so a test
reproduces the same result every run. The pattern is a `FixedRandom extends
RandomService` inner class (see above and `test_loot_system.gd` /
`test_combat_resolver.gd`). Where the system reads random via the registry,
register the stub under `"random"` in `before_each`.

## Docs sync

When a test reflects a new or changed public interface, layer contract, or
documented pipeline, update the affected `docs/` pages in the same change. The
code says what is checked; the docs explain the behavior and intent users should
rely on.

## Debugging a failing test

1. Re-run just that test with `-gunit_test_name=` to tighten the loop.
2. A `Parse Error` / "class not found" for **one** type usually means a wrong type
   name or a missing `.uid` — run `make ut` once to let Godot reimport and generate
   `.uid` files (see `references/conventions.md`).
3. If GUT itself won't start, the `GODOT` binary likely isn't a 4.7 build.
4. Flaky output across runs almost always means an un-stubbed `RandomService` or
   leaked global state — confirm `after_each()` clears the registry and that
   rolls are stubbed.
5. **Cascading `Parse Error: Could not parse global class "StatsComponent"/
   "HealthComponent"/…` across many module classes, and/or `Nonexistent function
   '…' in base 'GDScript'` for `IntTestHelpers` calls = a corrupted `.godot`
   import / global-class cache, not a code bug.** Tells: git is clean and the same
   files passed minutes earlier; it follows a crashed/interrupted run (leaked
   ObjectDB/RID + `Error 1`); `IntTestHelpers` references those classes, so when
   they fail to resolve the whole helper fails to compile and all its `static
   func`s "vanish". The `make` targets now fix this automatically (they run
   `reimport` first); for a direct `-gtest` run, do `make reimport` — or
   `$GODOT --headless --import` — and re-run. A plain re-run of GUT may NOT clear
   it; the explicit `--import` does.
6. **Trust the count, not just the color.** A *stale* cache can make GUT print
   "All tests passed" with **fewer scripts than normal** — degraded scripts fail to
   *load* and are silently skipped instead of failing. Baselines: kernel ~7 scripts
   / ~104 tests, modules ~16 / ~216, integration 12 / 46. A dropped count is a
   failure; rebuild the cache (step 5) and re-run.
