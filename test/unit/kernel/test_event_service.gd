extends GutTest

var events: EventService
var _received: Array = []


func before_each() -> void:
	events = EventService.new()
	add_child_autofree(events)
	_received = []


func _record_event(event: DomainEvent) -> void:
	_received.append(event)


# --- emit_domain_event ---


func test_tc_er_01_domain_event_emitted_signal_fires() -> void:
	var evt := DomainEvent.create("test_event", "src", "tgt", {"key": 1})
	watch_signals(events)
	events.emit_domain_event(evt)
	assert_signal_emitted(events, "domain_event_emitted")
	assert_signal_emitted_with_parameters(events, "domain_event_emitted", [evt])


func test_tc_er_02_recent_events_grows() -> void:
	for i in 3:
		events.emit_domain_event(DomainEvent.create("e", "s", "t", {}))
	assert_eq(events.recent_events.size(), 3)


func test_tc_er_03_recent_events_capped_at_max() -> void:
	events.max_recent_events = 5
	for i in 8:
		events.emit_domain_event(DomainEvent.create("e", "s", "t", {}))
	assert_eq(events.recent_events.size(), 5)


func test_tc_er_04_oldest_event_discarded_when_full() -> void:
	events.max_recent_events = 2
	var evt1 := DomainEvent.create("first", "s", "t", {})
	var evt2 := DomainEvent.create("second", "s", "t", {})
	var evt3 := DomainEvent.create("third", "s", "t", {})
	events.emit_domain_event(evt1)
	events.emit_domain_event(evt2)
	events.emit_domain_event(evt3)
	assert_eq(events.recent_events[0], evt2)
	assert_eq(events.recent_events[1], evt3)


func test_tc_er_05_null_event_is_ignored() -> void:
	watch_signals(events)
	events.emit_domain_event(null)
	assert_signal_not_emitted(events, "domain_event_emitted")
	assert_eq(events.recent_events.size(), 0)


# --- emit_event convenience ---


func test_tc_er_06_emit_event_builds_domain_event() -> void:
	events.emit_event("room_cleared", "r01", "t01", {"reason": "all_dead"})
	var de: DomainEvent = events.recent_events.back()
	assert_eq(de.event_type, "room_cleared")
	assert_eq(de.source_id, "r01")
	assert_eq(de.target_id, "t01")
	assert_eq(de.payload.get("reason"), "all_dead")


# --- subscribe / unsubscribe ---


func test_tc_er_07_subscriber_receives_matching_event() -> void:
	events.subscribe("entity_died", _record_event)
	var evt := DomainEvent.create("entity_died", "e01", "", {})
	events.emit_domain_event(evt)
	assert_eq(_received.size(), 1)
	assert_eq(_received[0], evt)


func test_tc_er_08_subscriber_ignores_other_event_types() -> void:
	events.subscribe("entity_died", _record_event)
	events.emit_event("room_cleared", "r01")
	assert_eq(_received.size(), 0)


func test_tc_er_09_duplicate_subscribe_is_noop() -> void:
	events.subscribe("entity_died", _record_event)
	events.subscribe("entity_died", _record_event)
	events.emit_event("entity_died", "e01")
	assert_eq(_received.size(), 1)


func test_tc_er_10_unsubscribe_stops_delivery() -> void:
	events.subscribe("entity_died", _record_event)
	events.unsubscribe("entity_died", _record_event)
	events.emit_event("entity_died", "e01")
	assert_eq(_received.size(), 0)


func test_tc_er_11_is_subscribed_reflects_state() -> void:
	assert_false(events.is_subscribed("entity_died", _record_event))
	events.subscribe("entity_died", _record_event)
	assert_true(events.is_subscribed("entity_died", _record_event))
	events.unsubscribe("entity_died", _record_event)
	assert_false(events.is_subscribed("entity_died", _record_event))


func test_tc_er_12_subscriber_also_gets_signal_dispatch() -> void:
	events.subscribe("entity_died", _record_event)
	watch_signals(events)
	events.emit_event("entity_died", "e01")
	assert_signal_emitted(events, "domain_event_emitted")
	assert_eq(_received.size(), 1)


func test_tc_er_13_any_event_subscriber_receives_all_events_once() -> void:
	events.subscribe(EventService.ANY_EVENT, _record_event)
	events.subscribe("entity_died", _record_event)

	events.emit_event("entity_died", "e01")
	events.emit_event("room_cleared", "r01")

	assert_eq(_received.size(), 2)
	assert_eq((_received[0] as DomainEvent).event_type, "entity_died")
	assert_eq((_received[1] as DomainEvent).event_type, "room_cleared")
