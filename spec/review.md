# Code Review — Scene8 S3 (Equipment slice)

Scope: working-tree diff for S3 (`game/demo/phase8_village_rpg.gd`,
`game/demo/phase8/resources/phase8_rpg_content.tres`,
`test/integration/test_scene8_full_tour_integration.gd`).

Method: line-by-line + removed-behavior + cross-file + GDScript-pitfall + reuse /
simplification / efficiency / altitude passes, then a gap sweep. Findings ranked
most-severe first. Each confirmed finding names the inputs that trigger it.

Verification state at review time: `make ut` (kernel 102 / modules 213),
`make int` (39), and `--phase8-auto-run` (exit 0, loop complete) all pass — the
top finding is latent on the auto-run path and is therefore **not** caught by the
current gate or tests (see Finding 1's "why green" note).

---

## Finding 1 — equip zeroes the blade's quantity via the shared ItemInstance; unequip then loses it (CONFIRMED, high within demo scope)

`game/demo/phase8_village_rpg.gd` — `_toggle_field_blade()` (equip branch):

```gdscript
if not equipment.equip(blade, WEAPON_SLOT):
    ...
inventory.remove_item_by_instance_id(blade.instance_id, 1)   # <-- mutates the equipped object
```

`EquipmentController.equip()` stores the *same* `ItemInstance` reference in
`equipped["weapon"]`; it does not copy it and does not remove it from the bag.
The very next line then calls `InventoryController.remove_item_by_instance_id`,
which (inventory_controller.gd:116) does:

```gdscript
slot.item.quantity -= quantity   # slot.item IS the equipped blade
```

So after equipping, `equipped["weapon"].quantity == 0`.

**Failure scenario A (item loss on unequip):** press `E` to equip, press `E`
again to unequip. The unequip branch calls
`inventory.add_item(removed)`, but `add_item` rejects quantity ≤ 0
(inventory_controller.gd:36 `if item.quantity <= 0: ... return false`). The blade
is removed from the weapon slot, **never returned to the bag**, and is now
unreachable — `find_item_by_definition` returns null on the next `E`
(`[EQUIP] no field blade to equip`). This directly contradicts the behavior
documented for the `E` toggle in `docs/demo_phase8_testing.md` §6
("再按一次 E 卸下,blade 回到背包").

**Failure scenario B (corrupt save state — bites S7):** with the blade equipped,
`EquipmentController.to_save_data()` serializes the weapon item with
`quantity: 0`. On load, `ItemInstance.from_save_data` restores `quantity = 0`.
Any later unequip → `add_item` then loses it, and the persisted equipped weapon
is semantically a 0-count stack.

**Why the suite is still green:** the auto-run only ever equips (never
unequips), and the `+attack_power` modifier is applied from the item
*definition*, independent of `quantity` — so `attack_power` still reaches 21 and
`get_equipped("weapon")` is still non-null, so `_phase8_loop_complete()` passes.
The S3 integration test never calls `remove_item_by_instance_id` (it equips the
bag instance in place), so it keeps `quantity == 1` and never exercises this
path. The bug lives only in the interactive/`E`-toggle and save paths.

**Recommended fix:** keep `EquipmentController` and `InventoryController`
decoupled the way the framework intends — don't mutate the bag's shared instance.
Drop the `remove_item_by_instance_id` call on equip and the `add_item(removed)`
call on unequip; let the blade live in the bag while the weapon slot references
it (this is what `phase3_inventory_slice.gd` does, minus its duplicate-on-unequip
quirk). If the bag *should* visually empty while the weapon is worn, then instead
remove the slot without decrementing the shared object (e.g. restore
`blade.quantity = 1` after removal, and guard `removed.quantity = max(1, …)`
before `add_item` on unequip) — but the decoupled approach is simpler and
bug-free. Add an `E`-equip→`E`-unequip assertion (blade back in bag, quantity 1)
to lock it down.

---

## Finding 2 — `_field_blade_equipped` latches true and is never cleared on unequip (PLAUSIBLE, low)

`game/demo/phase8_village_rpg.gd` — the flag is set in the equip branch
(`if after > before: _field_blade_equipped = true`) but the unequip branch never
resets it. Today this is harmless because `_phase8_loop_complete()` *also*
requires `equipment.get_equipped(WEAPON_SLOT) != null`, so an
equip-then-unequip can't false-pass the gate. It is a latent inconsistency: the
flag claims "blade equipped" after it has been removed. Either reset it to
`false` in the unequip branch, or derive the gate condition solely from
`get_equipped(...)` and the live `attack_power` and drop the separate flag.

---

## Finding 3 — misleading log on a missing controller (NIT, cosmetic)

`game/demo/phase8_village_rpg.gd` — `_toggle_field_blade()` logs
`"[EQUIP] equipment service missing"` when `_equipment_controller()` /
`_inventory()` are null. These are entity child *nodes*, not registry services;
the wording will misdirect debugging if the player layout ever changes. Reword to
e.g. `"[EQUIP] equipment/inventory controller missing"`. (Won't trigger in
practice — the player scene always carries both.)

---

## Items checked and cleared

- **Loot determinism.** `loot.phase8.field_blade` (`rolls=1`, single entry
  `weight=1.0`, `allow_empty=false`, `empty_weight=0.0`) always yields the blade
  in `LootSystem.roll` (`total_weight=1.0`, `r ≤ cursor` always true). Guaranteed
  drop — correct.
- **`load_steps=64`.** 26 ext + 38 sub (34 original + 4 new) = 64. Matches; the
  DB loads and validates at bootstrap.
- **DB registration.** `Resource_item_field_blade` and `Resource_loot_field_blade`
  are both added to the `[resource].resources` array; sub-resources are declared
  before the references that use them.
- **Stat math / gate threshold.** base 10 + blessing 5 (FLAT_ADD) + blade 6
  (FLAT_ADD) = exactly 21.0; gate `< 21.0` check is exact-float safe. Raising
  15.0→21.0 correctly now requires *both* blessing and equip, and no other caller
  depends on the old 15.0.
- **`_grant_field_loot` refactor.** Behavior preserved: claw still rolled, blade
  added, single `_play_sfx("sfx.phase8.loot")`. `_field_beast_looted` guard still
  makes loot one-shot (no double blade).
- **No double-stack on re-equip.** `EquipmentController.equip` unequips an
  occupied slot before re-applying, and the demo toggle only equips when the slot
  is empty — `attack_power` can't accumulate duplicate `+6` modifiers.
- **Reset clear.** `_reset_demo_state` iterates `equipped.keys().duplicate()`
  before `unequip` (safe mutation during iteration); runs at `_ready` when the
  slot is empty (no-op), correct.
- **Integration test correctness.** Round-trip asserts on `definition_id` /
  `attack_power`, not on object identity against the pre-save `blade` (the
  restored instance is a fresh object) — written correctly. Damage assertions
  match the `base + attack_power − defense` formula.
- **Layering.** All new content lives in `game/demo/phase8/`; no addon code
  touched, no `game → addon` reverse dependency, no concrete content hardcoded in
  `addons/mkit/`.

---

## Recommendation

Address **Finding 1** before relying on the `E` toggle interactively or wiring
the equipped blade through S7 save/load; it is a genuine item-loss /
save-corruption bug, merely masked on the auto-run happy path. Findings 2–3 are
low-risk cleanups that can ride along with the fix.

---

## Resolution (all three addressed)

- **Finding 1 — fixed.** `_toggle_field_blade()` no longer mutates the bag.
  Dropped the `inventory.remove_item_by_instance_id(...)` on equip and the
  `inventory.add_item(removed)` on unequip; `EquipmentController` and
  `InventoryController` are now kept decoupled (the bag keeps the
  `ItemInstance`, the weapon slot references it), so the shared instance's
  `quantity` is never driven to 0. No item loss on unequip; the equipped blade
  serializes at `quantity 1`.
- **Finding 2 — fixed.** The unequip branch now sets
  `_field_blade_equipped = false`, so the flag tracks the live slot.
- **Finding 3 — fixed.** Log reworded to
  `"[EQUIP] equipment/inventory controller missing"`.

**Regression coverage added:**
- Auto-run now runs a full **equip → unequip → re-equip** cycle (was a single
  equip). Under the old bug the blade would be lost on unequip and the final
  re-equip would leave the slot empty → `_phase8_loop_complete()`'s
  `get_equipped(WEAPON_SLOT) != null` check fails → `make phase8-test` would go
  red. Verified: `[EQUIP] equipped … 15 -> 21` / `unequipped … 21 -> 15` /
  `equipped … 15 -> 21`, exit 0, loop complete.
- `test_tc_int_scene8_03` gained assertions that the source `ItemInstance`
  survives an equip/unequip cycle at `quantity == 1` and re-equips.
- `docs/demo_phase8_testing.md` §6 updated to describe the decoupled behavior
  (blade stays in the bag; the slot references it) and the toggle cycle.

**Verification after fix:** `make ut` (kernel 102 / modules 213), `make int`
(39 tests, 716 asserts), `--phase8-auto-run` (exit 0, loop complete) — all pass.
