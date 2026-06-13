class_name RewardCoordinator
extends RefCounted
## 说明：`RewardCoordinator` 是 房间与一局流程系统 的协调器，负责把多个服务或组件的结果串接成一次领域操作。
## 上游：通常由同领域服务、controller、组件或内容资源创建或调用。
## 下游：会连接 mkit 的服务、组件、资源或事件管线，不直接依赖具体游戏内容。
## 使用：当项目需要在房间与一局流程系统中复用这段契约或状态时使用它。
## 示例：`var instance := RewardCoordinator.new()`


## 查找玩家实体时使用的 Godot 分组名称。
var player_group: String = "player"


## 将传入 payload 或 effect 应用到目标对象；返回值、signal 或 event 表示实际结果。
func apply_reward(option: RewardOption, run_id: String, tree: SceneTree) -> bool:
	var reward_system := Mkit.loot()
	if reward_system == null:
		return false
	var player: Node = tree.get_first_node_in_group(player_group) if tree != null else null
	var ctx := GameplayContext.from_nodes(player, player)
	ctx.payload["run_id"] = run_id
	return reward_system.apply_selected(option, ctx)
