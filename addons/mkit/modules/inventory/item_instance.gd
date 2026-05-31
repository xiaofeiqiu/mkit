## What: ItemInstance is the runtime copy of an ItemDefinition in inventory, equipment, or loot.
## Responsibilities: store unique instance id, definition id, quantity, rolled affixes, durability, upgrade level, metadata, and save data.
## Upstream: LootSystem, GrantItemEffect, InventoryController, shops, or tests create item instances.
## Downstream: InventoryController, EquipmentController, save/load, and UI use item instance state.
## When to use: Use it whenever the game owns a concrete item stack or individual item.
## Example: `var potion := ItemInstance.create("health_potion", 3); inventory.add_item(potion)`.
class_name ItemInstance
extends RefCounted

## Purpose: Public runtime field `instance_id`.
## Example: `self.instance_id = "value"`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var instance_id: String = ""
## Purpose: Public runtime field `definition_id`.
## Example: `self.definition_id = "value"`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var definition_id: String = ""
## Purpose: Public runtime field `quantity`.
## Example: `self.quantity = 1`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var quantity: int = 1
## Purpose: Public runtime field `rolled_affixes`.
## Example: `self.rolled_affixes = []`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var rolled_affixes: Array[StatModifier] = []
## Purpose: Public runtime field `durability`.
## Example: `self.durability = 1.0`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var durability: float = 1.0
## Purpose: Public runtime field `upgrade_level`.
## Example: `self.upgrade_level = 1`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var upgrade_level: int = 0
## Purpose: Public runtime field `metadata`.
## Example: `self.metadata = {}`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var metadata: Dictionary = {}


## Purpose: Public method `create` for external gameplay integration.
## Example: `ItemInstance.create(<def_id>, <qty>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
static func create(def_id: String, qty: int = 1) -> ItemInstance:
	var item := ItemInstance.new()
	item.instance_id = "item_%d" % Time.get_ticks_usec()
	item.definition_id = def_id
	item.quantity = qty
	return item


## Purpose: Public method `to_save_data` for external gameplay integration.
## Example: `self.to_save_data()`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func to_save_data() -> Dictionary:
	return {
		"instance_id": instance_id,
		"definition_id": definition_id,
		"quantity": quantity,
		"durability": durability,
		"upgrade_level": upgrade_level,
		"metadata": metadata
	}


## Purpose: Public method `from_save_data` for external gameplay integration.
## Example: `ItemInstance.from_save_data(<data>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
static func from_save_data(data: Dictionary) -> ItemInstance:
	var item := ItemInstance.new()
	item.instance_id = str(data.get("instance_id", ""))
	item.definition_id = str(data.get("definition_id", ""))
	item.quantity = int(data.get("quantity", 1))
	item.durability = float(data.get("durability", 1.0))
	item.upgrade_level = int(data.get("upgrade_level", 0))
	item.metadata = data.get("metadata", {})
	return item
