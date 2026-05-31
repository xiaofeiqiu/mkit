## What: LootEntry is one weighted item or content entry inside a LootTableDefinition.
## Responsibilities: define content id, weight, min/max quantity, and optional conditions.
## Upstream: designers add entries to loot table resources.
## Downstream: LootSystem filters valid entries and rolls quantities from them.
## When to use: Use it for each possible drop in an enemy, chest, or room loot table.
## Example: `content_id = "health_potion"`, `weight = 3.0`, `min_quantity = 1`, `max_quantity = 2`.
class_name LootEntry
extends Resource

## Purpose: Inspector-exposed configuration `content_id`.
## Example: `self.content_id = "value"`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var content_id: String = ""
## Purpose: Inspector-exposed configuration `weight`.
## Example: `self.weight = 1.0`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var weight: float = 1.0
## Purpose: Inspector-exposed configuration `min_quantity`.
## Example: `self.min_quantity = 1`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var min_quantity: int = 1
## Purpose: Inspector-exposed configuration `max_quantity`.
## Example: `self.max_quantity = 1`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var max_quantity: int = 1
## Purpose: Inspector-exposed configuration `conditions`.
## Example: `self.conditions = []`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var conditions: Array[Condition] = []
