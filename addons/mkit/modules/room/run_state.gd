class_name RunState
extends RefCounted

## Purpose: Public runtime field `run_id`.
## Example: `self.run_id = "value"`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var run_id: String = ""
## Purpose: Public runtime field `seed`.
## Example: `self.seed = 1`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var seed: int = 0
## Purpose: Public runtime field `current_floor`.
## Example: `self.current_floor = 1`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var current_floor: int = 1
## Purpose: Public runtime field `current_room_index`.
## Example: `self.current_room_index = 1`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var current_room_index: int = 0
## Purpose: Public runtime field `current_room_id`.
## Example: `self.current_room_id = "value"`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var current_room_id: String = ""
## Purpose: Public runtime field `elapsed_time`.
## Example: `self.elapsed_time = 1.0`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var elapsed_time: float = 0.0
## Purpose: Public runtime field `temporary_upgrade_ids`.
## Example: `self.temporary_upgrade_ids = []`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var temporary_upgrade_ids: Array[String] = []
## Purpose: Public runtime field `run_currency`.
## Example: `self.run_currency = {}`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var run_currency: Dictionary = {}
## Purpose: Public runtime field `enemy_scaling_level`.
## Example: `self.enemy_scaling_level = 1`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var enemy_scaling_level: int = 1
## Purpose: Public runtime field `room_history`.
## Example: `self.room_history = []`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var room_history: Array[String] = []
## Purpose: Public runtime field `reward_history`.
## Example: `self.reward_history = []`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var reward_history: Array[String] = []
## Purpose: Public runtime field `rng_state`.
## Example: `self.rng_state = {}`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var rng_state: Dictionary = {}
## Purpose: Public runtime field `status`.
## Example: `self.status = "value"`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var status: String = "not_started"

## Purpose: Public method `create` for external gameplay integration.
## Example: `RunState.create(<seed_value>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
static func create(seed_value: int) -> RunState:
	var s := RunState.new()
	s.run_id = "run_%d" % Time.get_ticks_usec()
	s.seed = seed_value
	return s

## Purpose: Public method `to_save_data` for external gameplay integration.
## Example: `self.to_save_data()`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func to_save_data() -> Dictionary:
	return {
		"run_id": run_id,
		"seed": seed,
		"current_floor": current_floor,
		"current_room_index": current_room_index,
		"current_room_id": current_room_id,
		"elapsed_time": elapsed_time,
		"temporary_upgrade_ids": temporary_upgrade_ids,
		"run_currency": run_currency,
		"enemy_scaling_level": enemy_scaling_level,
		"room_history": room_history,
		"reward_history": reward_history,
		"rng_state": rng_state,
		"status": status
	}
