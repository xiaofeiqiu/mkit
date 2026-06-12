class_name ModuleBootstrap
extends GameBootstrap
## 说明：`ModuleBootstrap` 是内置 gameplay modules 的组合根，在 GameBootstrap 的 kernel 服务之后追加模块服务。
## 上游：通常由 `game/bootstrap.tscn` 或项目自定义 bootstrap 场景实例化。
## 下游：会注册 combat、progression、quest、shop、dialogue、world、loot 等模块服务。
## 使用：当项目需要启用 mkit 内置 gameplay modules 时，继承或直接使用它。
## 示例：在主场景挂载 `ModuleBootstrap`，配置 ResourceDatabase 后进入初始场景。


func _build_services() -> Dictionary:
	var services := super()
	services[CombatService.SERVICE_ID] = CombatService.new()
	services[ProgressionService.SERVICE_ID] = ProgressionService.new()
	services[QuestService.SERVICE_ID] = QuestService.new()
	services[ShopService.SERVICE_ID] = ShopService.new()
	services[DialogueService.SERVICE_ID] = DialogueService.new()
	services[WorldService.SERVICE_ID] = WorldService.new()
	services[LootService.SERVICE_ID] = LootService.new()
	services[DeathLootService.SERVICE_ID] = DeathLootService.new()
	return services
