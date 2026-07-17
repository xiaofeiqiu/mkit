class_name DomainEventAsserts
extends RefCounted
## Test helpers for asserting on EventService.recent_events, replacing the
## removed per-domain typed signals on the kernel event bus.


static func find_events(events: EventService, event_type: String) -> Array[DomainEvent]:
	var matches: Array[DomainEvent] = []
	for e in events.recent_events:
		if e.event_type == event_type:
			matches.append(e)
	return matches


static func last_event(events: EventService, event_type: String) -> DomainEvent:
	var matches := find_events(events, event_type)
	return matches.back() if not matches.is_empty() else null
