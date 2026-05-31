class_name DamageRequest
extends RefCounted

## Purpose: Public runtime field `source`.
## Example: `self.source = null`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var source: Node = null
## Purpose: Public runtime field `target`.
## Example: `self.target = null`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var target: Node = null
## Purpose: Public runtime field `base_amount`.
## Example: `self.base_amount = 1.0`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var base_amount: float = 0.0
## Purpose: Public runtime field `damage_type`.
## Example: `self.damage_type = "value"`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var damage_type: String = "physical"
## Purpose: Public runtime field `element_type`.
## Example: `self.element_type = "value"`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var element_type: String = "none"
## Purpose: Public runtime field `can_crit`.
## Example: `self.can_crit = true`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var can_crit: bool = true
## Purpose: Public runtime field `can_evade`.
## Example: `self.can_evade = true`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var can_evade: bool = true
## Purpose: Public runtime field `can_block`.
## Example: `self.can_block = true`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var can_block: bool = true
## Purpose: Public runtime field `tags`.
## Example: `self.tags = []`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var tags: Array[String] = []
## Purpose: Public runtime field `on_hit_statuses`.
## Example: `self.on_hit_statuses = []`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var on_hit_statuses: Array[Dictionary] = [] # 每项: {status_id, chance, stacks, duration}
## Purpose: Public runtime field `payload`.
## Example: `self.payload = {}`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var payload: Dictionary = {}
