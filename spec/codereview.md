# Code Review — Scene8 S5 (Enemy AI)

**Scope:** working-tree changes vs `origin/main` (Scene8 step S5 — enemy AI).
**Reviewer effort:** extra-high recall pass.
**Build/test status:** `4.7.dev5` · full `test_scene8_full_tour_integration.gd` → **6/6 pass**;
`test_tc_int_scene8_05` re-run 5× → **5/5 pass** (no observed flakiness).

## Files under review

- `addons/mkit/modules/ai/brain.gd` — adds `blackboard: Blackboard`.
- `addons/mkit/modules/ai/simple_ai_enemy_brain.gd` — writes intent/target/distance/move_direction
  to the blackboard, adds cached `_get_target()`.
- `game/demo/phase8/entities/states/{enemy_idle,enemy_move,enemy_attack}_state.gd` — new HFSM states (untracked).
- `game/demo/phase8/entities/field_beast.tscn` — HFSM tree, `HitboxComponent`, `SimpleAIEnemyBrain`, `move_speed`.
- `game/demo/entities/player/player.tscn` — adds `HurtboxComponent` so the player can take hits.
- `game/demo/phase8/resources/phase8_rpg_content.tres` — `move_speed` on the field-beast definition.
- `test/integration/test_scene8_full_tour_integration.gd` — new test 05 + `_disable_beast_ai` helper on tests 00–03.
- `docs/ref/{Brain,SimpleAIEnemyBrain}.md`, `spec/scene8test.md` — doc/status updates.

## Resolution

| # | Finding | Status |
|---|---------|--------|
| 1 | `_get_target()` stale freed-target cache | ✅ **Fixed** — `is_instance_valid()` + `erase_value` on miss |
| 2 | Brain `move_direction` blackboard write | ⏸ **Kept by design** — intentional, documented observability (parallels `distance`/`intent` in `Brain.md`) |
| 3 | Shared hardcoded `receiver_id` | ⏸ **Accepted (dormant)** — guarded by single-beast spawn; a real fix needs per-instance `entity_id`+`receiver_id`, out of scope for this slice |
| 4 | Duplicated player/enemy melee states | ⏸ **Deferred** — refactor of working demo content, disproportionate to a demo |
| 5 | Test 05 auto-think race | ✅ **Hardened** — auto-think disabled after the autonomous `_ready` cache is asserted; `think()` driven explicitly |

Re-verified after the fixes: `test_tc_int_scene8_05` 5/5 reruns · full `test_scene8_full_tour_integration.gd` 6/6 · `test_ui_interaction_ai_scene_integration.gd` 5/5 · module unit suite 214/214.

## Verdict

The slice is coherent and the combat/AI wiring is correct: the brain dispatches to its own
`entity_id`, the `CommandReceiver` is registered under the same id, the HFSM routes
MOVE/ATTACK to the right states, and the beast `HitboxComponent` → player `HurtboxComponent`
→ `CombatResolver` → `HealthComponent` chain lands exactly 8 damage (no defense, faction-filtered
so neither the player nor the beast can hit itself). No crashing or happy-path defects found.
Findings below are one latent correctness bug in reusable addon code plus cleanup/altitude items.

---

## Findings

### 1. (Medium — latent correctness, addon) `_get_target()` never refreshes a freed/replaced target

`addons/mkit/modules/ai/simple_ai_enemy_brain.gd:40`

```gdscript
func _get_target() -> Node:
	var stored := blackboard.get_value("target", null) as Node
	if stored != null:            # <-- a freed Node is NOT null here
		return stored
	stored = get_tree().get_first_node_in_group(target_group)
	...
```

`!= null` does not detect a freed Node — after the target is freed (player death+respawn,
zone unload that keeps the beast, target leaving its group), the blackboard still holds a
dangling reference that compares `!= null` as `true`. `_get_target()` then returns the dead
node forever and never re-queries `target_group`. `think()` masks the symptom
(`target as Node2D` → `null` → falls to `idle`) but the brain can never re-acquire a live
target. This is reusable framework code, so every game using `SimpleAIEnemyBrain` inherits it.

The current tests don't hit it because targets aren't freed mid-life.

**Fix:** validate with `is_instance_valid()`:

```gdscript
var stored := blackboard.get_value("target", null) as Node
if is_instance_valid(stored):
	return stored
```

(and clear/overwrite the stale key when re-querying).

### 2. (Low — cleanup/altitude, addon) AI memory is split across two un-synced `Blackboard` instances; `move_direction` write is dead

`addons/mkit/modules/ai/simple_ai_enemy_brain.gd:33`, `brain.gd:8` vs `state_machine.gd:10`

`Brain.blackboard` and `StateMachine.blackboard` are two distinct `Blackboard.new()` objects.
The brain writes `move_direction` to *its* blackboard (line 33), but the move state reads
`move_direction` from the *StateMachine's* blackboard (`state.gd:16` → `machine.blackboard`),
which is fed independently from the MOVE command payload. So the brain's `move_direction`
write is dead — movement only works via the command payload. `target/intent/distance` on the
brain blackboard are genuinely useful (observed by tests/DebugOverlay), but the `move_direction`
line is misleading: it looks like it couples the brain to the HFSM and does not.

**Fix:** drop the `blackboard.set_value("move_direction", direction)` line, or document that the
brain blackboard is a read-only observation scratchpad distinct from the HFSM blackboard.

### 3. (Low — reusability, dormant) Hardcoded `receiver_id` shared by every FieldBeast instance

`game/demo/phase8/entities/field_beast.tscn:36` (`receiver_id = "enemy.phase8.field_beast"`)

The brain dispatches commands to its own `entity_id`, and `CommandRouter` maps an id to a
single receiver (last-registered wins, `command_router.gd:15`). Every `FieldBeast` instance
carries the same hardcoded `receiver_id`, so with multiple beasts alive their brains would all
drive one receiver while the others sit inert. Newly *reachable* because the AI now self-issues
commands (previously nothing auto-dispatched to this id). The demo dodges it only because
`_spawn_field_beast()` (`phase8_village_rpg.gd:841`) enforces a single beast.

**Fix:** if multi-enemy is ever needed, derive a per-instance receiver id (e.g. from the spawned
node's instance id) at spawn time rather than baking it into the shared scene.

### 4. (Low — altitude/cleanup, game) Enemy melee states duplicate the player melee states

`game/demo/phase8/entities/states/enemy_attack_state.gd` vs `game/demo/entities/player/states/player_attack_state.gd`

The new enemy idle/move/attack states largely re-implement the player states' command handling,
facing-from-context logic, `TimedAttackAction` wiring, and the magic `28.0` melee offset
(`enemy_attack_state.gd:14`). Acceptable for demo content, but the shared melee attack-state
behavior is a candidate for a reusable base state so the reach offset and action setup live in
one place.

### 5. (Informational — test) Test 05 drives `brain.think()` manually while the AI is left enabled

`test/integration/test_scene8_full_tour_integration.gd:447`

Unlike tests 00–03 (which call `_disable_beast_ai`), test 05 leaves `Brain.enabled == true`, so
`Brain._process` auto-fires `think()` on idle frames during the `await ... physics_frame` waits,
racing the manual `think()` calls and the exact command-history / state / `hp_before - 8.0`
assertions. It holds because the choreography keeps an auto-started attack action from reaching
its 0.05 s active window within the ~2-frame measured budget — verified stable (5/5 reruns under
fixed headless deltas). Flagged as fragile-by-construction: a change to `think_interval`, the
action durations, or the frame budget could break it. Optional hardening: disable the brain and
drive `think()` purely manually (as the other tests do), or assert ranges rather than exact deltas.

---

## Non-issues confirmed during review

- **Self-damage / friendly fire:** faction filtering (`HitboxComponent._is_valid_target`) blocks
  the player's own hitbox (`target_factions ["enemy"]`) from its new hurtbox, and the beast's
  hitbox (`["player"]`) from its own/other beasts' hurtboxes. Default collision layers (all 1)
  are fine because the faction filter, not layers, gates hits.
- **Lingering active hitbox:** `TimedAttackAction` disables the hitbox on startup, on `complete`,
  and on `cancel` — no residual active hitbox after an attack.
- **Damage math:** beast `base_damage 8` + beast `attack_power 0` − player `defense 0` = exactly
  `8.0`, matching the test assertion.
- **`move_speed` consistency:** the field-beast scene `StatsComponent` and the `EntityDefinition`
  in `phase8_rpg_content.tres` both carry `move_speed = 120.0`, so the spawned beast reports 120
  with empty base-overrides (asserted by test 04).
