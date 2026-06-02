extends GutTest

var events: EventRouter


func before_each() -> void:
	events = EventRouter.new()
	add_child_autofree(events)


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


# --- typed emit helpers ---


func test_tc_er_05_emit_room_cleared_fires_signal() -> void:
	watch_signals(events)
	events.emit_room_cleared("room_forest_01")
	assert_signal_emitted_with_parameters(events, "room_cleared", ["room_forest_01"])


func test_tc_er_06_emit_room_cleared_also_emits_domain_event() -> void:
	watch_signals(events)
	events.emit_room_cleared("r01")
	assert_signal_emitted(events, "domain_event_emitted")
	assert_eq(events.recent_events.back().event_type, "room_cleared")


func test_tc_er_07_emit_entity_died_fires_with_id_and_ref() -> void:
	var node := Node.new()
	add_child_autofree(node)
	watch_signals(events)
	events.emit_entity_died("enemy_01", node)
	assert_signal_emitted_with_parameters(events, "entity_died", ["enemy_01", node])


func test_tc_er_08_emit_inventory_changed_fires() -> void:
	watch_signals(events)
	events.emit_inventory_changed("player")
	assert_signal_emitted_with_parameters(events, "inventory_changed", ["player"])


func test_tc_er_09_emit_run_started_fires_and_records() -> void:
	watch_signals(events)
	events.emit_run_started("run_001", 42)
	assert_signal_emitted_with_parameters(events, "run_started", ["run_001", 42])
	var de: DomainEvent = events.recent_events.back()
	assert_eq(de.event_type, "run_started")
	assert_eq(de.payload.get("seed"), 42)


func test_tc_er_10_emit_run_finished_fires_and_records() -> void:
	watch_signals(events)
	events.emit_run_finished("run_001", "victory")
	assert_signal_emitted_with_parameters(events, "run_finished", ["run_001", "victory"])
	assert_eq(events.recent_events.back().payload.get("result"), "victory")


func test_tc_er_11_emit_reward_selected_fires() -> void:
	watch_signals(events)
	events.emit_reward_selected("hp_up", "chest_01")
	assert_signal_emitted_with_parameters(events, "reward_selected", ["hp_up"])


func test_tc_er_12_emit_damage_applied_fires_and_creates_domain_event() -> void:
	var result := _FakeDamageResult.new()
	watch_signals(events)
	events.emit_damage_applied(result)
	assert_signal_emitted(events, "damage_applied")
	assert_eq(events.recent_events.back().event_type, "damage_applied")


class _FakeDamageResult:
	var source: Node = null
	var target: Node = null

	func to_debug_dict() -> Dictionary:
		return {"final": 10.0}
