## What: GameEffect is the base Resource for data-driven gameplay effects.
## Responsibilities: hold shared metadata, evaluate preconditions, and delegate actual behavior to _apply_impl.
## Upstream: ability, item, reward, status, and upgrade definitions store arrays of GameEffect resources.
## Downstream: EffectExecutor calls apply(), while subclasses such as DealDamageEffect and HealEffect implement behavior.
## When to use: Extend it when a new content action should be reusable from multiple systems.
## Example: `class_name KnockbackEffect extends GameEffect` and override `_apply_impl(ctx)` to push `ctx.target`.
class_name GameEffect
extends Resource

## Purpose: Inspector-exposed configuration `effect_id`.
## Example: `self.effect_id = "value"`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var effect_id: String = ""
## Purpose: Inspector-exposed configuration `conditions`.
## Example: `self.conditions = []`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var conditions: Array[Condition] = []
## Purpose: Inspector-exposed configuration `tags`.
## Example: `self.tags = []`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var tags: Array[String] = []


## Purpose: Public method `apply` for external gameplay integration.
## Example: `self.apply(<context>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func apply(context: GameplayContext) -> EffectResult:
	if not ConditionEvaluator.evaluate_all(conditions, context):
		var failures := ConditionEvaluator.collect_failures(conditions, context)
		return EffectResult.fail(effect_id, ", ".join(failures))
	return _apply_impl(context)


func _apply_impl(context: GameplayContext) -> EffectResult:
	return EffectResult.ok(effect_id)
