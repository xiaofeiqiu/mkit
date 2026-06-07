class_name RewardCoordinator
extends RefCounted

var player_group: String = "player"


func apply_reward(option: RewardOption, run_id: String, tree: SceneTree) -> bool:
	var reward_system := ServiceRegistry.get_port(ServiceRegistry.SERVICE_LOOT) as LootService
	if reward_system == null:
		return false
	var player: Node = tree.get_first_node_in_group(player_group) if tree != null else null
	var ctx := GameplayContext.from_nodes(player, player)
	ctx.run_id = run_id
	return reward_system.apply_selected(option, ctx)
