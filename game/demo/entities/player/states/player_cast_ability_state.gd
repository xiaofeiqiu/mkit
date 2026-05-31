class_name PlayerCastAbilityState
extends State


func enter(context: Dictionary = {}) -> void:
	var command := context.get("command") as GameCommand
	if command == null:
		request_transition("Player/Idle", {"reason": "missing_command"})
		return

	var ability_id := command.get_string("ability_id")
	var controller := owner_entity.get_node_or_null("Controllers/AbilityController") as AbilityController
	if controller == null:
		request_transition("Player/Idle", {"reason": "no_ability_controller"})
		return

	var gameplay_ctx := GameplayContext.from_command(command, owner_entity, _find_nearest_enemy())
	gameplay_ctx.ability_id = ability_id

	var ok := controller.cast(ability_id, gameplay_ctx)
	if not ok:
		request_transition("Player/Idle", {"reason": "cast_failed"})
		return

	request_transition("Player/Idle", {"reason": "cast_started"})


func _find_nearest_enemy() -> Node:
	if owner_entity == null or owner_entity.get_tree() == null:
		return null
	var enemies := owner_entity.get_tree().get_nodes_in_group("enemy")
	var best: Node = null
	var best_dist := INF
	for enemy in enemies:
		if enemy is Node2D:
			var d := (owner_entity as Node2D).global_position.distance_to((enemy as Node2D).global_position)
			if d < best_dist:
				best = enemy
				best_dist = d
	return best
