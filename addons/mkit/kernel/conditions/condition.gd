class_name Condition
extends Resource

## Purpose: Inspector-exposed configuration `condition_id`.
## Example: `self.condition_id = "value"`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var condition_id: String = ""
## Purpose: Inspector-exposed configuration `invert`.
## Example: `self.invert = true`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var invert: bool = false


## Purpose: Public method `evaluate` for external gameplay integration.
## Example: `self.evaluate(<context>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func evaluate(context: GameplayContext) -> bool:
	var result := _evaluate_impl(context)
	if invert:
		return not result
	return result


func _evaluate_impl(context: GameplayContext) -> bool:
	return true


## Purpose: Public method `get_failure_reason` for external gameplay integration.
## Example: `self.get_failure_reason(<context>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func get_failure_reason(context: GameplayContext) -> String:
	return "Condition failed: %s" % condition_id
