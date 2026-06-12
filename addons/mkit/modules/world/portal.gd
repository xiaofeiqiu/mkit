class_name Portal
extends Interactable
## 说明：`Portal` 是 世界与场景系统 的公开 API 类型，负责承载该领域的可复用运行时数据或行为。
## 上游：通常由同领域服务、controller、组件或内容资源创建或调用。
## 下游：会连接 mkit 的服务、组件、资源或事件管线，不直接依赖具体游戏内容。
## 使用：当项目需要在世界与场景系统中复用这段契约或状态时使用它。
## 示例：`var instance := Portal.new()`

## 传送目标 ZoneDefinition id；为空时 Portal 不应执行切区。
@export var target_zone_id: String = ""
## 目标区域内的 SpawnPoint id；为空或 default 使用默认出生点。
@export var target_spawn_id: String = "default"


func _interact_impl(_context: GameplayContext) -> bool:
	if target_zone_id == "":
		return false
	var world := Mkit.world()
	if world == null:
		return false
	return world.go_to_zone(target_zone_id, target_spawn_id)
