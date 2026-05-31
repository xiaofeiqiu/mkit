class_name StatusEffectDefinition
extends Resource

enum StackRule {
	REFRESH_DURATION,
	ADD_STACK,
	REPLACE,
	IGNORE,
	EXTEND_DURATION,
	INDEPENDENT_STACKS
}

## Purpose: Inspector-exposed configuration `status_id`.
## Example: `self.status_id = "value"`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var status_id: String = ""
## Purpose: Inspector-exposed configuration `display_name`.
## Example: `self.display_name = "value"`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var display_name: String = ""
## Purpose: Inspector-exposed configuration `duration`.
## Example: `self.duration = 1.0`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var duration: float = 5.0
## Purpose: Inspector-exposed configuration `tick_interval`.
## Example: `self.tick_interval = 1.0`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var tick_interval: float = 1.0
## Purpose: Inspector-exposed configuration `max_stacks`.
## Example: `self.max_stacks = 1`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var max_stacks: int = 1
## Purpose: Inspector-exposed configuration `stack_rule`.
## Example: `self.stack_rule = null`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var stack_rule: StackRule = StackRule.REFRESH_DURATION
## Purpose: Inspector-exposed configuration `tags`.
## Example: `self.tags = []`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var tags: Array[String] = []
## Purpose: Inspector-exposed configuration `effects_on_apply`.
## Example: `self.effects_on_apply = []`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var effects_on_apply: Array[GameEffect] = []
## Purpose: Inspector-exposed configuration `effects_on_tick`.
## Example: `self.effects_on_tick = []`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var effects_on_tick: Array[GameEffect] = []
## Purpose: Inspector-exposed configuration `effects_on_remove`.
## Example: `self.effects_on_remove = []`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var effects_on_remove: Array[GameEffect] = []
## Purpose: Inspector-exposed configuration `stat_modifiers`.
## Example: `self.stat_modifiers = []`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var stat_modifiers: Array[StatModifierDefinition] = []
