class_name DamageResult
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
## Purpose: Public runtime field `final_amount`.
## Example: `self.final_amount = 1.0`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var final_amount: float = 0.0
## Purpose: Public runtime field `damage_type`.
## Example: `self.damage_type = "value"`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var damage_type: String = "physical"
## Purpose: Public runtime field `element_type`.
## Example: `self.element_type = "value"`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var element_type: String = "none"
## Purpose: Public runtime field `was_critical`.
## Example: `self.was_critical = true`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var was_critical: bool = false
## Purpose: Public runtime field `was_evaded`.
## Example: `self.was_evaded = true`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var was_evaded: bool = false
## Purpose: Public runtime field `was_blocked`.
## Example: `self.was_blocked = true`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var was_blocked: bool = false
## Purpose: Public runtime field `was_lethal`.
## Example: `self.was_lethal = true`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var was_lethal: bool = false
## Purpose: Public runtime field `applied_status_effects`.
## Example: `self.applied_status_effects = []`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var applied_status_effects: Array[String] = [] # 命中并通过概率判定的 status_id 列表
## Purpose: Public runtime field `status_applications`.
## Example: `self.status_applications = []`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var status_applications: Array[Dictionary] = [] # 待施加的完整条目: {status_id, stacks, duration}
## Purpose: Public runtime field `trace`.
## Example: `self.trace = {}`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var trace: Dictionary = {}


## Purpose: Public method `to_debug_dict` for external gameplay integration.
## Example: `self.to_debug_dict()`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func to_debug_dict() -> Dictionary:
	return {
		"base_amount": base_amount,
		"final_amount": final_amount,
		"damage_type": damage_type,
		"element_type": element_type,
		"critical": was_critical,
		"evaded": was_evaded,
		"blocked": was_blocked,
		"lethal": was_lethal,
		"applied_status_effects": applied_status_effects,
		"trace": trace
	}
