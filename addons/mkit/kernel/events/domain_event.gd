class_name DomainEvent
extends RefCounted
var event_type: String = ""
var event_id: String = ""
var timestamp: float = 0.0
var source_id: String = ""
var target_id: String = ""
var payload: Dictionary = {}


static func create(
	type: String, source: String = "", target: String = "", data: Dictionary = {}
) -> DomainEvent:
	var e := DomainEvent.new()
	e.event_type = type
	e.event_id = "%s_%d" % [type, Time.get_ticks_usec()]
	e.timestamp = Time.get_ticks_msec() / 1000.0
	e.source_id = source
	e.target_id = target
	e.payload = data
	return e
