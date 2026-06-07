class_name DebugOverlay
extends CanvasLayer
@export var watch_entity_path: NodePath
@export var status_provider_path: NodePath
@export var visible_on_start: bool = true
@export var show_registered_services: bool = true
var _label: Label = null
var _events: EventService = null


func _ready() -> void:
	_label = Label.new()
	add_child(_label)
	visible = visible_on_start
	if ServiceRegistry.has_service(ServiceRegistry.SERVICE_EVENTS):
		_events = ServiceRegistry.get_port(ServiceRegistry.SERVICE_EVENTS) as EventService
	if not ServiceRegistry.has_service("debug"):
		ServiceRegistry.register_service("debug", self)


func _process(_delta: float) -> void:
	if visible:
		_label.text = _build_text()


func toggle() -> void:
	visible = not visible


func _build_text() -> String:
	var lines: Array[String] = []
	if show_registered_services and ServiceRegistry.has_method("get_port_ids"):
		lines.append("Services: %s" % ", ".join(ServiceRegistry.get_port_ids()))
	_append_status_provider_lines(lines)
	var entity := get_node_or_null(watch_entity_path)
	if entity != null:
		var sm := EntityContract.get_state_machine(entity)
		if sm != null:
			lines.append("State: %s" % sm.get_current_path())
			if sm.last_failed_transition_reason != "":
				lines.append("Last failed transition: %s" % sm.last_failed_transition_reason)
		var receiver := EntityContract.get_command_receiver(entity)
		if receiver != null and not receiver.command_history.is_empty():
			lines.append("Last command: %s" % receiver.command_history[-1].command_type)
		var health := EntityContract.get_component(entity, "HealthComponent")
		if health != null and "current_hp" in health and health.has_method("get_max_hp"):
			lines.append("HP: %.0f / %.0f" % [health.current_hp, health.get_max_hp()])
	if _events != null and not _events.recent_events.is_empty():
		var recent := _events.recent_events.slice(
			max(0, _events.recent_events.size() - 5), _events.recent_events.size()
		)
		var names: Array[String] = []
		for e in recent:
			names.append(e.event_type)
		lines.append("Recent events: %s" % ", ".join(names))
	return "\n".join(lines)


func _append_status_provider_lines(lines: Array[String]) -> void:
	var provider := get_node_or_null(status_provider_path)
	if provider == null or not provider.has_method("get_debug_status_lines"):
		return
	var raw_lines = provider.call("get_debug_status_lines")
	if raw_lines is Array:
		for line in raw_lines:
			lines.append(str(line))
	elif str(raw_lines) != "":
		lines.append(str(raw_lines))
