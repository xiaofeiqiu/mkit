class_name StatusEffectInstance
extends RefCounted

## Purpose: Public runtime field `instance_id`.
## Example: `self.instance_id = "value"`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var instance_id: String = ""
## Purpose: Public runtime field `definition_id`.
## Example: `self.definition_id = "value"`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var definition_id: String = ""
## Purpose: Public runtime field `source`.
## Example: `self.source = null`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var source: Node = null
## Purpose: Public runtime field `target`.
## Example: `self.target = null`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var target: Node = null
## Purpose: Public runtime field `remaining_duration`.
## Example: `self.remaining_duration = 1.0`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var remaining_duration: float = 0.0
## Purpose: Public runtime field `tick_timer`.
## Example: `self.tick_timer = 1.0`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var tick_timer: float = 0.0
## Purpose: Public runtime field `stacks`.
## Example: `self.stacks = 1`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var stacks: int = 1
## Purpose: Public runtime field `applied_modifier_ids`.
## Example: `self.applied_modifier_ids = []`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var applied_modifier_ids: Array[String] = []


## Purpose: Public method `setup` for external gameplay integration.
## Example: `self.setup(<definition>, <source_entity>, <target_entity>, <initial_stacks>, <duration_override>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func setup(definition: StatusEffectDefinition, source_entity: Node, target_entity: Node, initial_stacks: int, duration_override: float = -1.0) -> void:
	instance_id = "%s_%d" % [definition.status_id, Time.get_ticks_usec()]
	definition_id = definition.status_id
	source = source_entity
	target = target_entity
	stacks = initial_stacks
	remaining_duration = duration_override if duration_override > 0 else definition.duration
	tick_timer = definition.tick_interval
