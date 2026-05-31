## What: StatModifier is a runtime instance of a stat change applied to a StatsComponent.
## Responsibilities: carry modifier id, stat id, source id, operation, value, priority, stack rule, duration, and tags.
## Upstream: StatModifierDefinition, status effects, equipment, effects, and upgrades create modifiers.
## Downstream: StatsComponent sorts, stacks, expires, and applies modifiers during stat calculation.
## When to use: Use it for the live applied form of authored or scripted stat changes.
## Example: `stats.add_modifier(StatModifier.from_definition(haste_def, "potion_speed", 8.0))`.
class_name StatModifier
extends RefCounted

## Purpose: Public runtime field `modifier_id`.
## Example: `self.modifier_id = "value"`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var modifier_id: String = ""
## Purpose: Public runtime field `stat_id`.
## Example: `self.stat_id = "value"`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var stat_id: String = ""
## Purpose: Public runtime field `source_id`.
## Example: `self.source_id = "value"`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var source_id: String = ""
## Purpose: Public runtime field `operation`.
## Example: `self.operation = null`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var operation: StatModifierDefinition.Operation
## Purpose: Public runtime field `value`.
## Example: `self.value = 1.0`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var value: float = 0.0
## Purpose: Public runtime field `priority`.
## Example: `self.priority = 1`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var priority: int = 0
## Purpose: Public runtime field `stacking_rule`.
## Example: `self.stacking_rule = null`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var stacking_rule: StatModifierDefinition.StackingRule
## Purpose: Public runtime field `remaining_duration`.
## Example: `self.remaining_duration = 1.0`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var remaining_duration: float = -1.0
## Purpose: Public runtime field `tags`.
## Example: `self.tags = []`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var tags: Array[String] = []


## Purpose: Public method `from_definition` for external gameplay integration.
## Example: `StatModifier.from_definition(<definition>, <source>, <duration>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
static func from_definition(definition: StatModifierDefinition, source: String, duration: float = -1.0) -> StatModifier:
	var m := StatModifier.new()
	m.modifier_id = definition.modifier_id
	m.stat_id = definition.stat_id
	m.source_id = source
	m.operation = definition.operation
	m.value = definition.value
	m.priority = definition.priority
	m.stacking_rule = definition.stacking_rule
	m.remaining_duration = duration
	m.tags = definition.tags.duplicate()
	return m
