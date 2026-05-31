## What: LootRollResult is the runtime output of a LootSystem roll.
## Responsibilities: carry rolled item instances, currency amounts, and debug roll details.
## Upstream: LootSystem creates it after rolling a LootTableDefinition.
## Downstream: inventory grants, reward UI, analytics, and tests inspect or apply the rolled contents.
## When to use: Use it as a structured result instead of returning raw item arrays from loot rolls.
## Example: `var result := loot.roll_table("slime_drops", ctx); for item in result.item_instances: inventory.add_item(item)`.
class_name LootRollResult
extends RefCounted

## Purpose: Public runtime field `item_instances`.
## Example: `self.item_instances = []`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var item_instances: Array[ItemInstance] = []
## Purpose: Public runtime field `currency`.
## Example: `self.currency = {}`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var currency: Dictionary = {}
## Purpose: Public runtime field `debug_rolls`.
## Example: `self.debug_rolls = []`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var debug_rolls: Array[Dictionary] = []
