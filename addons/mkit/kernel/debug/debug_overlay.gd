class_name DebugOverlay
extends CanvasLayer

## Purpose: Inspector-exposed configuration `watch_entity_path`.
## Example: `self.watch_entity_path = NodePath(".")`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var watch_entity_path: NodePath
## Purpose: Inspector-exposed configuration `visible_on_start`.
## Example: `self.visible_on_start = true`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var visible_on_start: bool = true

var _label: Label = null
var _events: EventRouter = null


func _ready() -> void:
	_label = Label.new()
	add_child(_label)
	visible = visible_on_start
	if ServiceRegistry.has_service("events"):
		_events = ServiceRegistry.get_service("events") as EventRouter
	if not ServiceRegistry.has_service("debug"):
		ServiceRegistry.register_service("debug", self)


func _process(_delta: float) -> void:
	if visible:
		_label.text = _build_text()


## Purpose: Public method `toggle` for external gameplay integration.
## Example: `self.toggle()`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func toggle() -> void:
	visible = not visible


func _build_text() -> String:
	var lines: Array[String] = []
	var entity := get_node_or_null(watch_entity_path)
	if entity != null:
		var sm := entity.get_node_or_null("StateMachine") as StateMachine
		if sm != null:
			lines.append("State: %s" % sm.get_current_path())
			if sm.last_failed_transition_reason != "":
				lines.append("Last failed transition: %s" % sm.last_failed_transition_reason)
		var receiver := entity.get_node_or_null("CommandReceiver") as CommandReceiver
		if receiver != null and not receiver.command_history.is_empty():
			lines.append("Last command: %s" % receiver.command_history[-1].command_type)
		# HealthComponent is a gameplay-module type added in a later phase. Read it
		# by duck typing so the kernel-level overlay compiles before combat exists.
		var health = entity.get_node_or_null("Components/HealthComponent")
		if health != null and "current_hp" in health and health.has_method("get_max_hp"):
			lines.append("HP: %.0f / %.0f" % [health.current_hp, health.get_max_hp()])
	if _events != null and not _events.recent_events.is_empty():
		var recent := _events.recent_events.slice(max(0, _events.recent_events.size() - 5), _events.recent_events.size())
		var names: Array[String] = []
		for e in recent:
			names.append(e.event_type)
		lines.append("Recent events: %s" % ", ".join(names))
	return "\n".join(lines)
