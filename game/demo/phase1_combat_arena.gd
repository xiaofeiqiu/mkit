extends Node2D

# Phase 1 combat slice — the "initial scene" entered by GameBootstrap.
#
# Validation target (spec/implementation_spec.md Phase 1):
#   Player moves. Player attacks. Enemy takes damage. Enemy dies.
#   Damage and death events are emitted.
#
# Green square = player, red square = enemy. Drive it with the keyboard
# (WASD/Arrows to move, Space/J to attack) and watch the console + DebugOverlay.


func _ready() -> void:
	var events := ServiceRegistry.get_service("events") as EventRouter
	if events != null:
		events.damage_applied.connect(_on_damage_applied)
		events.entity_died.connect(_on_entity_died)
	else:
		push_error("CombatArena: EventRouter service missing — was GameBootstrap run?")

	print("=== Combat Arena ===")
	print("Move: WASD / Arrow keys    Attack: Space / J")
	print("Hit the red enemy until it dies; watch damage_applied / entity_died events below.")


func _on_damage_applied(result) -> void:
	if result == null:
		return
	print(
		(
			"[EVENT] damage_applied -> %.1f damage to %s (crit=%s, lethal=%s)"
			% [
				result.final_amount,
				_node_name(result.target),
				str(result.was_critical),
				str(result.was_lethal),
			]
		)
	)


func _on_entity_died(entity_id: String, _entity_ref: Node) -> void:
	print("[EVENT] entity_died -> %s" % entity_id)


func _node_name(n: Node) -> String:
	return str(n.name) if n != null else "?"
