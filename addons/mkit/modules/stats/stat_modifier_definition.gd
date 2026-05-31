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
