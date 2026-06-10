class_name WorldEvents
extends RefCounted
## World-owned domain event catalog: event type constants + DomainEvent constructors.

const ROOM_CLEARED := "room_cleared"
const ZONE_CHANGED := "zone_changed"
const RUN_STARTED := "run_started"
const RUN_FINISHED := "run_finished"


static func room_cleared(room_id: String) -> DomainEvent:
	return DomainEvent.create(ROOM_CLEARED, room_id, "", {})


static func zone_changed(from_zone_id: String, to_zone_id: String) -> DomainEvent:
	return DomainEvent.create(
		ZONE_CHANGED,
		from_zone_id,
		to_zone_id,
		{"from_zone_id": from_zone_id, "to_zone_id": to_zone_id}
	)


static func run_started(run_id: String, seed: int) -> DomainEvent:
	return DomainEvent.create(RUN_STARTED, run_id, "", {"seed": seed})


static func run_finished(run_id: String, result: String) -> DomainEvent:
	return DomainEvent.create(RUN_FINISHED, run_id, "", {"result": result})
