class_name InventorySlot
extends RefCounted

## Purpose: Public runtime field `index`.
## Example: `self.index = 1`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var index: int = -1
## Purpose: Public runtime field `item`.
## Example: `self.item = null`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var item: ItemInstance = null


## Purpose: Public method `is_empty` for external gameplay integration.
## Example: `self.is_empty()`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func is_empty() -> bool:
	return item == null


## Purpose: Public method `clear` for external gameplay integration.
## Example: `self.clear()`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func clear() -> void:
	item = null
