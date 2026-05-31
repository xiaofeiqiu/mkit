## What: LootTableDefinition is authored loot content made of weighted LootEntry resources.
## Responsibilities: define table id, roll count, entries, empty-roll behavior, and empty weight.
## Upstream: designers attach entries and register the table in ContentRegistry.
## Downstream: LootSystem rolls the table and creates LootRollResult item/currency outputs.
## When to use: Use it for enemy drops, chest loot, room rewards, or destructible prop drops.
## Example: `loot_table_id = "slime_drops"`, `rolls = 2`, `entries = [gel_entry, coin_entry]`, `allow_empty = true`.
class_name LootTableDefinition
extends Resource

## Purpose: Inspector-exposed configuration `loot_table_id`.
## Example: `self.loot_table_id = "value"`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var loot_table_id: String = ""
## Purpose: Inspector-exposed configuration `rolls`.
## Example: `self.rolls = 1`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var rolls: int = 1
## Purpose: Inspector-exposed configuration `entries`.
## Example: `self.entries = []`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var entries: Array[LootEntry] = []
## Purpose: Inspector-exposed configuration `allow_empty`.
## Example: `self.allow_empty = true`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var allow_empty: bool = true
## Purpose: Inspector-exposed configuration `empty_weight`.
## Example: `self.empty_weight = 1.0`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var empty_weight: float = 0.0


## Purpose: Public method `get_resource_id` for external gameplay integration.
## Example: `self.get_resource_id()`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func get_resource_id() -> String:
	return loot_table_id
