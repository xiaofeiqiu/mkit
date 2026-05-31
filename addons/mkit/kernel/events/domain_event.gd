class_name DomainEvent
extends RefCounted

## Purpose: Public runtime field `event_type`.
## Example: `self.event_type = "value"`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var event_type: String = ""
## Purpose: Public runtime field `event_id`.
## Example: `self.event_id = "value"`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var event_id: String = ""
## Purpose: Public runtime field `timestamp`.
## Example: `self.timestamp = 1.0`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var timestamp: float = 0.0
## Purpose: Public runtime field `source_id`.
## Example: `self.source_id = "value"`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var source_id: String = ""
## Purpose: Public runtime field `target_id`.
## Example: `self.target_id = "value"`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var target_id: String = ""
## Purpose: Public runtime field `payload`.
## Example: `self.payload = {}`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var payload: Dictionary = {}


## Purpose: Public method `create` for external gameplay integration.
## Example: `DomainEvent.create(<type>, <source>, <target>, <data>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
static func create(type: String, source: String = "", target: String = "", data: Dictionary = {}) -> DomainEvent:
	var e := DomainEvent.new()
	e.event_type = type
	e.event_id = "%s_%d" % [type, Time.get_ticks_usec()]
	e.timestamp = Time.get_ticks_msec() / 1000.0
	e.source_id = source
	e.target_id = target
	e.payload = data
	return e
