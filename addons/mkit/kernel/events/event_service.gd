class_name EventService
extends Node
signal domain_event_emitted(event: DomainEvent)
var recent_events: Array[DomainEvent] = []
var max_recent_events: int = 100
var _subscribers: Dictionary = {}


## Static convenience lookup through the service registry; null when absent.
static func find() -> EventService:
	return ServiceRegistry.get_port(ServiceRegistry.SERVICE_EVENTS) as EventService


func emit_domain_event(event: DomainEvent) -> void:
	if event == null:
		push_warning("EventService.emit_domain_event: event is null")
		return
	recent_events.append(event)
	if recent_events.size() > max_recent_events:
		recent_events.pop_front()
	domain_event_emitted.emit(event)
	_dispatch_to_subscribers(event)


## Convenience wrapper building the DomainEvent inline.
func emit_event(
	event_type: String, source_id: String = "", target_id: String = "", payload: Dictionary = {}
) -> void:
	emit_domain_event(DomainEvent.create(event_type, source_id, target_id, payload))


## Calls `callable(event: DomainEvent)` whenever an event of `event_type` is emitted.
## Subscribing the same callable twice is a no-op.
func subscribe(event_type: String, callable: Callable) -> void:
	if event_type == "" or not callable.is_valid():
		push_warning("EventService.subscribe: invalid event_type or callable")
		return
	var listeners: Array = _subscribers.get(event_type, [])
	if listeners.has(callable):
		return
	listeners.append(callable)
	_subscribers[event_type] = listeners


func unsubscribe(event_type: String, callable: Callable) -> void:
	var listeners: Array = _subscribers.get(event_type, [])
	listeners.erase(callable)
	if listeners.is_empty():
		_subscribers.erase(event_type)


func is_subscribed(event_type: String, callable: Callable) -> bool:
	var listeners: Array = _subscribers.get(event_type, [])
	return listeners.has(callable)


func _dispatch_to_subscribers(event: DomainEvent) -> void:
	var listeners: Array = _subscribers.get(event.event_type, [])
	if listeners.is_empty():
		return
	var stale: Array = []
	for callable: Callable in listeners.duplicate():
		if callable.is_valid():
			callable.call(event)
		else:
			stale.append(callable)
	for callable: Callable in stale:
		unsubscribe(event.event_type, callable)
