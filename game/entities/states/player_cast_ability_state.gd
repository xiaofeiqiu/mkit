class_name PlayerCastAbilityState
extends HfsmState


func enter(context: Dictionary = {}) -> void:
	var command := context.get("command") as GameCommand
	if command == null:
		request_transition.call_deferred("Player/Idle", {"reason": "missing_command"})
		return

	var ability_id := command.get_string("ability_id")
	var controller := (
		owner_entity.get_node_or_null("Controllers/AbilityController") as AbilityController
	)
	if controller == null:
		request_transition.call_deferred("Player/Idle", {"reason": "no_ability_controller"})
		return

	var gameplay_ctx := GameplayContext.from_command(command, owner_entity, _find_nearest_enemy())

	var ok := controller.cast(ability_id, gameplay_ctx)

	# call_deferred: the outer transition_to("Player/CastAbility") hasn't updated
	# current_leaf_state yet when enter() runs. A synchronous request_transition here
	# would see current_leaf_state == Player/Idle and short-circuit as a no-op, leaving
	# the HFSM permanently stuck in CastAbility. Deferring ensures the outer transition
	# finishes writing current_leaf_state = CastAbility first.
	if not ok:
		request_transition.call_deferred("Player/Idle", {"reason": "cast_failed"})
		return

	request_transition.call_deferred("Player/Idle", {"reason": "cast_started"})


func _find_nearest_enemy() -> Node:
	if owner_entity == null or owner_entity.get_tree() == null:
		return null
	var enemies := owner_entity.get_tree().get_nodes_in_group("enemy")
	var best: Node = null
	var best_dist := INF
	for enemy in enemies:
		if enemy is Node2D:
			var d := (owner_entity as Node2D).global_position.distance_to(
				(enemy as Node2D).global_position
			)
			if d < best_dist:
				best = enemy
				best_dist = d
	return best
