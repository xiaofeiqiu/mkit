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
