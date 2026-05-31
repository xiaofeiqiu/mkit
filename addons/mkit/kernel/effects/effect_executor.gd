## What: EffectExecutor runs GameEffect resources and optionally keeps a short trace of recent results.
## Responsibilities: execute one or many effects, honor stop-on-failure, and record EffectResult history for debugging.
## Upstream: abilities, items, rewards, status effects, and progression upgrades submit effects with a GameplayContext.
## Downstream: concrete effects mutate health, inventory, stats, scene nodes, or event streams.
## When to use: Use it whenever content-driven resources need to apply a list of effects consistently.
## Example: `executor.execute_many(fireball.effects, GameplayContext.new().with_source(caster).with_target(enemy))`.
class_name EffectExecutor
extends RefCounted

## Purpose: Public runtime field `trace_enabled`.
## Example: `self.trace_enabled = true`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var trace_enabled: bool = true
## Purpose: Public runtime field `recent_results`.
## Example: `self.recent_results = []`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var recent_results: Array[EffectResult] = []
## Purpose: Public runtime field `max_recent_results`.
## Example: `self.max_recent_results = 1`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var max_recent_results: int = 100


## Purpose: Public method `execute` for external gameplay integration.
## Example: `self.execute(<effect>, <context>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func execute(effect: GameEffect, context: GameplayContext) -> EffectResult:
	if effect == null:
		return EffectResult.fail("null_effect", "Effect is null")

	var result := effect.apply(context)
	_record_result(result)
	return result


## Purpose: Public method `execute_many` for external gameplay integration.
## Example: `self.execute_many(<effects>, <context>, <stop_on_failure>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func execute_many(effects: Array[GameEffect], context: GameplayContext, stop_on_failure: bool = false) -> Array[EffectResult]:
	var results: Array[EffectResult] = []
	for effect in effects:
		var result := execute(effect, context)
		results.append(result)
		if stop_on_failure and not result.success:
			break
	return results


func _record_result(result: EffectResult) -> void:
	if not trace_enabled:
		return
	recent_results.append(result)
	if recent_results.size() > max_recent_results:
		recent_results.pop_front()
