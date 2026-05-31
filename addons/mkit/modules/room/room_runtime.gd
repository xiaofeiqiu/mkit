class_name RoomRuntime
extends RefCounted

## Purpose: Public runtime field `room_runtime_id`.
## Example: `self.room_runtime_id = "value"`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var room_runtime_id: String = ""
## Purpose: Public runtime field `definition_id`.
## Example: `self.definition_id = "value"`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var definition_id: String = ""
## Purpose: Public runtime field `cleared`.
## Example: `self.cleared = true`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var cleared: bool = false
## Purpose: Public runtime field `entered`.
## Example: `self.entered = true`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var entered: bool = false
## Purpose: Public runtime field `active_enemy_ids`.
## Example: `self.active_enemy_ids = []`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var active_enemy_ids: Array[String] = []
## Purpose: Public runtime field `reward_options`.
## Example: `self.reward_options = []`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var reward_options: Array[RewardOption] = []

## Purpose: Public method `create` for external gameplay integration.
## Example: `RoomRuntime.create(<definition_id>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
static func create(definition_id: String) -> RoomRuntime:
	var r := RoomRuntime.new()
	r.room_runtime_id = "room_%d" % Time.get_ticks_usec()
	r.definition_id = definition_id
	return r
