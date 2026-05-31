## What: EffectResult is the standard return object for GameEffect execution.
## Responsibilities: report success/failure, identify the effect, carry payload data, and nest child effect results.
## Upstream: GameEffect subclasses and EffectExecutor create it after each effect attempt.
## Downstream: debuggers, tests, UI feedback, and stop-on-failure effect chains inspect the result.
## When to use: Use it whenever effect code needs to return structured status instead of only true/false.
## Example: `return EffectResult.ok("heal", {"amount": 25})` from a custom healing effect.
class_name EffectResult
extends RefCounted

## Purpose: Public runtime field `success`.
## Example: `self.success = true`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var success: bool = true
## Purpose: Public runtime field `effect_id`.
## Example: `self.effect_id = "value"`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var effect_id: String = ""
## Purpose: Public runtime field `failure_reason`.
## Example: `self.failure_reason = "value"`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var failure_reason: String = ""
## Purpose: Public runtime field `payload`.
## Example: `self.payload = {}`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var payload: Dictionary = {}
## Purpose: Public runtime field `child_results`.
## Example: `self.child_results = []`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var child_results: Array[EffectResult] = []


## Purpose: Public method `ok` for external gameplay integration.
## Example: `EffectResult.ok(<id>, <data>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
static func ok(id: String = "", data: Dictionary = {}) -> EffectResult:
	var r := EffectResult.new()
	r.success = true
	r.effect_id = id
	r.payload = data
	return r


## Purpose: Public method `fail` for external gameplay integration.
## Example: `EffectResult.fail(<id>, <reason>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
static func fail(id: String, reason: String) -> EffectResult:
	var r := EffectResult.new()
	r.success = false
	r.effect_id = id
	r.failure_reason = reason
	return r
