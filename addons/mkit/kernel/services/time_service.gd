class_name TimeService
extends RefCounted

## Purpose: Public runtime field `paused`.
## Example: `self.paused = true`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var paused: bool = false
## Purpose: Public runtime field `gameplay_time_scale`.
## Example: `self.gameplay_time_scale = 1.0`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var gameplay_time_scale: float = 1.0
## Purpose: Public runtime field `elapsed_gameplay_time`.
## Example: `self.elapsed_gameplay_time = 1.0`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var elapsed_gameplay_time: float = 0.0


## Purpose: Public method `set_paused` for external gameplay integration.
## Example: `self.set_paused(<value>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func set_paused(value: bool) -> void:
	paused = value


## Purpose: Public method `set_gameplay_time_scale` for external gameplay integration.
## Example: `self.set_gameplay_time_scale(<value>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func set_gameplay_time_scale(value: float) -> void:
	gameplay_time_scale = max(0.0, value)


## Purpose: Public method `get_scaled_delta` for external gameplay integration.
## Example: `self.get_scaled_delta(<delta>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func get_scaled_delta(delta: float) -> float:
	if paused:
		return 0.0
	return delta * gameplay_time_scale


## Purpose: Public method `advance` for external gameplay integration.
## Example: `self.advance(<delta>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func advance(delta: float) -> float:
	var scaled := get_scaled_delta(delta)
	elapsed_gameplay_time += scaled
	return scaled


## Purpose: Public method `get_unix_time` for external gameplay integration.
## Example: `self.get_unix_time()`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func get_unix_time() -> int:
	return Time.get_unix_time_from_system()
