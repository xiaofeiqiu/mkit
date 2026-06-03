# Code Review — `dev` branch vs local `main`

**Base:** local `main`  ·  **Target:** working tree of `dev` (committed + uncommitted + untracked)
**Date:** 2026-06-03

一句话总结：新加的 shop 模块有两个真实的高危逻辑缺陷（免费物品永远买不了 + 背包部分装入导致刷钱/刷物品），其余 kernel/progression/测试改动正确。

## Scope reviewed

Diff against `main` covered:

- **Production code (changed):** `addons/mkit/kernel/bootstrap/game_bootstrap.gd`, `addons/mkit/kernel/commands/command_receiver.gd`, `addons/mkit/modules/progression/progression_system.gd`
- **Production code (new, untracked):** `addons/mkit/modules/shop/{shop_controller,shop_definition,shop_entry}.gd`, `addons/mkit/modules/ui/shop_ui.gd`
- **Tests (new / changed):** `test/unit/modules/test_shop_controller.gd`, `test/unit/modules/test_progression_system.gd`, `test/unit/kernel/test_command_router.gd`, `test/integration/*` (new helpers + suites), `test/integration/test_quest_pipeline_integration.gd`
- **Docs / spec:** `docs/pipeline.md`, `docs/ref/*`, `spec/*`

---

## Findings (ranked by severity)

### 1. HIGH — Zero-cost shop entries are unpurchasable; `can_buy` and `buy` disagree

**File:** [addons/mkit/modules/shop/shop_controller.gd:62](addons/mkit/modules/shop/shop_controller.gd#L62)

`buy()` debits currency with `progression.spend_currency(current_shop.currency_id, total_cost)`. But `ProgressionSystem.spend_currency` rejects any non-positive amount:

```gdscript
# progression_system.gd
if amount <= 0:
    return false
```

So when `total_cost == 0` the spend returns `false`, `buy()` emits `transaction_failed(item_id, "Insufficient currency")` and returns `false` — even though the buyer has more than enough money.

`total_cost` is `0` whenever the effective buy price is `0`, which happens in two common cases:
- `ShopEntry.price_override == 0` (a deliberately free item), and
- no override + `ItemDefinition.value == 0` — and `value` **defaults to 0** ([item_definition.gd](addons/mkit/modules/inventory/item_definition.gd)), so any item that simply never set a price lands here.

Worse, `_buy_block_reason` passes for this case: its affordability check is `get_currency(...) < get_buy_price(...) * quantity` → `currency < 0`, always false. So `can_buy()` returns **true** while `buy()` returns **false** for the identical inputs — an API contract violation that will surface as a "you can't afford this" error on a free item.

**Failure scenario:** Shop entry for a starter item with `value = 0` (or `price_override = 0`). Player clicks buy → `can_buy` says yes → `buy` fails with "Insufficient currency" → item can never be acquired.

**Why tests miss it:** `test_shop_controller.gd` always creates items with `value > 0` and entries with positive `price_override`, so the zero-price branch is never exercised.

**Suggested fix:** In `buy()`, only attempt to spend when `total_cost > 0` (skip the debit for free items), or have `ProgressionSystem.spend_currency` treat `amount == 0` as a successful no-op. Align `_buy_block_reason` with whichever rule is chosen.

---

### 2. HIGH — Currency/item dupe: full refund after a *partial* inventory add

**File:** [addons/mkit/modules/shop/shop_controller.gd:67-70](addons/mkit/modules/shop/shop_controller.gd#L67-L70) (gate at [shop_controller.gd:147](addons/mkit/modules/shop/shop_controller.gd#L147))

`buy()` spends the full cost, then calls `inventory.add_item(item)`; if that returns `false` it refunds the **entire** `total_cost` and returns. This assumes `add_item` is all-or-nothing. It is not.

- The gate `_buy_block_reason` only checks `inventory.can_add_item(ItemInstance.create(item_id, quantity))`. `can_add_item` returns `true` if **any one** stackable slot has room *or* **any one** empty slot exists ([inventory_controller.gd:27-29](addons/mkit/modules/inventory/inventory_controller.gd#L27-L29) → `find_stackable_slot`/`find_first_empty_slot`). It does **not** verify the full `quantity` fits.
- `add_item` ([inventory_controller.gd:56-93](addons/mkit/modules/inventory/inventory_controller.gd#L56-L93)) mutates slots as it goes (`slot.item.quantity += moved`, fills empty slots), and if it runs out of room mid-way it returns `false` **after** having already placed part of the quantity.

So `buy()` can: debit full cost → `add_item` places *some* items and returns `false` → `buy()` refunds the *full* cost and keeps the partially-added items. Net result: player gets free items, currency unchanged, and shop stock is not decremented either (the `entry.stock` decrement at line 72 is skipped on the failure path).

**Failure scenario (broadly reachable):**
- Non-stackable item, buyer has 3 empty slots, buy `quantity = 5`. `can_add_item` sees an empty slot → `true`. `buy` debits 5×price, `add_item` fills 3 slots then returns `false`, `buy` refunds 5×price. Player keeps 3 free items.
- Stackable: existing stack at `quantity 90 / max_stack 99` and no empty slots, buy `quantity = 50`. `can_add_item` true (slot has room) → `add_item` tops the stack to 99 (added 9), returns `false` → full refund → 9 free items.

**Why tests miss it:** the shop tests never buy a quantity larger than the available inventory space.

**Suggested fix:** Make the gate quantity-aware (a `can_add_item` that checks total free space for the requested quantity), or make `add_item` atomic (compute placement first, place only if all fits), or refund only the portion that failed and roll back the partial placement. A capacity-aware check is the deeper fix since `can_add_item` over-reporting capacity is the root cause shared by both readings.

---

### 3. LOW — `ShopUI` never assigns `buyer`, so UI purchases always fail

**File:** [addons/mkit/modules/ui/shop_ui.gd:45](addons/mkit/modules/ui/shop_ui.gd#L45) (and `bind()` at [shop_ui.gd:7](addons/mkit/modules/ui/shop_ui.gd#L7))

`_render()` wires each button to `controller.buy(entry_id, 1, buyer)`, but `buyer` defaults to `null` and `bind()` never sets it; no other code in the repo assigns `ShopUI.buyer` either. Every button press therefore routes to `buy(..., null)` → `_buy_block_reason` → `_get_inventory(null)` returns `null` → `"Buyer has no inventory"` → `transaction_failed`. The shop UI cannot complete a purchase out of the box.

**Failure scenario:** Open shop UI, click any item → silent `transaction_failed("Buyer has no inventory")`, nothing bought.

**Suggested fix:** Accept the buyer in `bind(shop_controller, buyer)` (or via an explicit setter) and store it, so the wired callback has a valid buyer. If the public-field-set-by-caller pattern is intentional, document/guard it and emit a clearer failure when `buyer == null`.

---

## Changes reviewed and judged correct

- **`command_receiver.gd`** — now marks the command consumed when `handle_unhandled_command` returns `true`. Correct and consistent with the state-machine branch; no code depends on `consumed` staying `false` after fallback handling (only `test_command_router.gd` / `test_gameplay_pipeline_integration.gd` read `.consumed`, and they expect `true`). `CommandRouter.dispatch` return value is unchanged.
- **`progression_system.spend_currency`** — input guards (empty id, non-positive amount) plus delegation to `ProgressionState.spend_currency` (which rejects overspend) are correct; signal emitted only on success. (Its `amount <= 0` guard is, however, the trigger for Finding 1.)
- **`game_bootstrap.gd`** — registering `ShopController` under id `"shop"` follows the existing pattern used for `QuestSystem` ("quest"); no architectural regression.
- **`test_quest_pipeline_integration.gd` refactor + `int_test_helpers.gd`** — equivalent setup extracted to shared helpers; `cleanup_service_registry()` mirrors the prior inline teardown. Note the pre-existing `ServiceRegistry.clear()` teardown caveat (bootstrap child nodes) recorded in project memory still applies but is unchanged by this diff.

---

## Summary

| # | Severity | Location | Issue |
|---|----------|----------|-------|
| 1 | HIGH | shop_controller.gd:62 | Free (price 0 / default value) items are unpurchasable; `can_buy` ≠ `buy` |
| 2 | HIGH | shop_controller.gd:67-70 | Full refund after partial `add_item` → currency/item dupe |
| 3 | LOW  | shop_ui.gd:45 | `buyer` never set → all UI purchases fail |

Findings 1 and 2 are both reachable with default/common data and are uncovered by the new tests; recommend fixing before merge and adding regression tests for the zero-price and over-capacity buy paths.
