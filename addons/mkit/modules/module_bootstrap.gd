class_name ModuleBootstrap
extends GameBootstrap
## Composition root for the built-in gameplay modules. GameBootstrap registers
## kernel services only; this subclass appends the module services. Games that
## use the built-in modules should boot through this (or their own subclass).


func _build_services() -> Dictionary:
	var services := super()
	services[ServiceRegistry.SERVICE_COMBAT] = CombatService.new()
	services[ServiceRegistry.SERVICE_PROGRESSION] = ProgressionService.new()
	services[ServiceRegistry.SERVICE_QUEST] = QuestService.new()
	services[ServiceRegistry.SERVICE_SHOP] = ShopService.new()
	services[ServiceRegistry.SERVICE_DIALOGUE] = DialogueService.new()
	services[ServiceRegistry.SERVICE_WORLD] = WorldService.new()
	services[ServiceRegistry.SERVICE_LOOT] = LootService.new()
	return services
