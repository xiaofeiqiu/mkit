class_name RewardCoordinator
extends RefCounted

var player_group: String = "player"


func apply_reward(option: RewardOption, run_id: String, tree: SceneTree) -> bool:
	var reward_system := ServiceRegistry.get_service("loot") as LootService
	var ctx := GameplayContext.new()
	ctx.run_id = run_id
	var player: Node = tree.get_first_node_in_group(player_group) if tree != null else null
	ctx.source = player
	ctx.target = player
	return reward_system.apply_selected(option, ctx)
