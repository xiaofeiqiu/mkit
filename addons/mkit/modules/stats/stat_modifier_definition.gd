## What: StatModifierDefinition is the authored Resource form of a stat modifier.
## Responsibilities: define operation, value, priority, stacking rule, tags, target stat id, and stable modifier id.
## Upstream: designers attach it to items, statuses, rewards, upgrades, or effect resources.
## Downstream: StatModifier.from_definition and StatsComponent turn it into runtime stat changes.
## When to use: Use it for reusable buffs or item affixes that should be authored as content.
## Example: create a definition with `stat_id = "attack_power"`, `operation = FLAT_ADD`, `value = 5.0` for an iron sword.
class_name StatModifierDefinition
extends Resource

enum Operation {
	FLAT_ADD,
	PERCENT_ADD,
	PERCENT_MULTIPLY,
	OVERRIDE,
	CLAMP_MIN,
	CLAMP_MAX
}

enum StackingRule {
	STACK,
	REPLACE_SAME_SOURCE,
	HIGHEST_ONLY,
	LOWEST_ONLY,
	UNIQUE
}

## Purpose: Inspector-exposed configuration `modifier_id`.
## Example: `self.modifier_id = "value"`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var modifier_id: String = ""
## Purpose: Inspector-exposed configuration `stat_id`.
## Example: `self.stat_id = "value"`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var stat_id: String = ""
## Purpose: Inspector-exposed configuration `operation`.
## Example: `self.operation = null`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var operation: Operation = Operation.FLAT_ADD
## Purpose: Inspector-exposed configuration `value`.
## Example: `self.value = 1.0`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var value: float = 0.0
## Purpose: Inspector-exposed configuration `priority`.
## Example: `self.priority = 1`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var priority: int = 0
## Purpose: Inspector-exposed configuration `stacking_rule`.
## Example: `self.stacking_rule = null`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var stacking_rule: StackingRule = StackingRule.STACK
## Purpose: Inspector-exposed configuration `tags`.
## Example: `self.tags = []`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var tags: Array[String] = []
