## What: ItemDefinition is authored content describing an item type.
## Responsibilities: define display data, type, rarity, icon, stack rules, equipment slot, tags, use conditions/effects, and stat modifiers.
## Upstream: designers create item resources and ContentRegistry registers them.
## Downstream: InventoryController, EquipmentController, LootSystem, GrantItemEffect, and UI query item metadata.
## When to use: Use it for every inventory/equipment/consumable/material item id.
## Example: `item_id = "iron_sword"`, `item_type = "weapon"`, `equipment_slot = "weapon"`, `stat_modifiers = [attack_plus_5]`.
class_name ItemDefinition
extends Resource

## Purpose: Inspector-exposed configuration `item_id`.
## Example: `self.item_id = "value"`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var item_id: String = ""
## Purpose: Inspector-exposed configuration `display_name`.
## Example: `self.display_name = "value"`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var display_name: String = ""
## Purpose: Inspector-exposed configuration `description`.
## Example: `self.description = "value"`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export_multiline var description: String = ""
## Purpose: Inspector-exposed configuration `item_type`.
## Example: `self.item_type = "value"`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var item_type: String = "material" # weapon, armor, consumable, material, quest
## Purpose: Inspector-exposed configuration `rarity`.
## Example: `self.rarity = "value"`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var rarity: String = "common"
## Purpose: Inspector-exposed configuration `icon`.
## Example: `self.icon = null`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var icon: Texture2D
## Purpose: Inspector-exposed configuration `stackable`.
## Example: `self.stackable = true`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var stackable: bool = true
## Purpose: Inspector-exposed configuration `max_stack`.
## Example: `self.max_stack = 1`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var max_stack: int = 99
## Purpose: Inspector-exposed configuration `equipment_slot`.
## Example: `self.equipment_slot = "value"`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var equipment_slot: String = ""
## Purpose: Inspector-exposed configuration `tags`.
## Example: `self.tags = []`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var tags: Array[String] = []
## Purpose: Inspector-exposed configuration `use_conditions`.
## Example: `self.use_conditions = []`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var use_conditions: Array[Condition] = []
## Purpose: Inspector-exposed configuration `use_effects`.
## Example: `self.use_effects = []`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var use_effects: Array[GameEffect] = []
## Purpose: Inspector-exposed configuration `stat_modifiers`.
## Example: `self.stat_modifiers = []`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var stat_modifiers: Array[StatModifierDefinition] = []


## Purpose: Public method `get_resource_id` for external gameplay integration.
## Example: `self.get_resource_id()`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func get_resource_id() -> String:
	return item_id
