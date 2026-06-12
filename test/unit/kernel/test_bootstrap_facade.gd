extends GutTest


var _registered_node_services: Array[Node] = []


func before_each() -> void:
	_registered_node_services = []
	_cleanup_service_registry()


func after_each() -> void:
	_cleanup_service_registry()
	_free_registered_node_services()


func test_tc_boot_01_build_services_returns_kernel_service_contract() -> void:
	var bootstrap := GameBootstrap.new()
	var services := bootstrap._build_services()

	assert_true(services[EventService.SERVICE_ID] is EventService)
	assert_true(services[ContentService.SERVICE_ID] is ContentService)
	assert_true(services[RandomService.SERVICE_ID] is RandomService)
	assert_true(services[TimeService.SERVICE_ID] is TimeService)
	assert_true(services[ActionService.SERVICE_ID] is ActionService)
	assert_true(services[EffectService.SERVICE_ID] is EffectService)
	assert_true(services[CommandService.SERVICE_ID] is CommandService)
	assert_true(services[SceneService.SERVICE_ID] is SceneService)
	assert_true(services[PoolService.SERVICE_ID] is PoolService)
	assert_true(services[SaveService.SERVICE_ID] is SaveService)
	assert_true(services[AudioService.SERVICE_ID] is AudioService)
	assert_false(services.has(CombatService.SERVICE_ID))
	_free_node_services(services)
	bootstrap.free()


func test_tc_boot_02_register_kernel_services_adds_nodes_and_mkit_resolves_them() -> void:
	var bootstrap := GameBootstrap.new()
	add_child_autofree(bootstrap)
	bootstrap._register_kernel_services()

	assert_eq(Mkit.events(), ServiceRegistry.get_port(EventService.SERVICE_ID))
	assert_eq(Mkit.content(), ServiceRegistry.get_port(ContentService.SERVICE_ID))
	assert_eq(Mkit.random(), ServiceRegistry.get_port(RandomService.SERVICE_ID))
	assert_eq(Mkit.time(), ServiceRegistry.get_port(TimeService.SERVICE_ID))
	assert_eq(Mkit.actions(), ServiceRegistry.get_port(ActionService.SERVICE_ID))
	assert_eq(Mkit.effects(), ServiceRegistry.get_port(EffectService.SERVICE_ID))
	assert_eq(Mkit.commands(), ServiceRegistry.get_port(CommandService.SERVICE_ID))
	assert_eq(Mkit.scenes(), ServiceRegistry.get_port(SceneService.SERVICE_ID))
	assert_eq(Mkit.pool(), ServiceRegistry.get_port(PoolService.SERVICE_ID))
	assert_eq(Mkit.save(), ServiceRegistry.get_port(SaveService.SERVICE_ID))
	assert_eq(Mkit.audio(), ServiceRegistry.get_port(AudioService.SERVICE_ID))
	assert_true(ServiceRegistry.get_node_or_null("EventService") is EventService)
	assert_true(ServiceRegistry.get_node_or_null("ActionService") is ActionService)
	assert_null(Mkit.ui())


func test_tc_boot_03_mkit_module_accessors_return_registered_services() -> void:
	var combat := CombatService.new()
	var progression := ProgressionService.new()
	var quest := QuestService.new()
	var shop := ShopService.new()
	var dialogue := DialogueService.new()
	var world := WorldService.new()
	var loot := LootService.new()
	var death_loot := DeathLootService.new()
	var ui := UIManager.new()

	ServiceRegistry.register_service(CombatService.SERVICE_ID, combat)
	_register_node_service(ProgressionService.SERVICE_ID, progression)
	_register_node_service(QuestService.SERVICE_ID, quest)
	_register_node_service(ShopService.SERVICE_ID, shop)
	_register_node_service(DialogueService.SERVICE_ID, dialogue)
	_register_node_service(WorldService.SERVICE_ID, world)
	ServiceRegistry.register_service(LootService.SERVICE_ID, loot)
	_register_node_service(DeathLootService.SERVICE_ID, death_loot)
	_register_node_service(UIManager.SERVICE_ID, ui)

	assert_eq(Mkit.combat(), combat)
	assert_eq(Mkit.progression(), progression)
	assert_eq(Mkit.quest(), quest)
	assert_eq(Mkit.shop(), shop)
	assert_eq(Mkit.dialogue(), dialogue)
	assert_eq(Mkit.world(), world)
	assert_eq(Mkit.loot(), loot)
	assert_eq(Mkit.death_loot(), death_loot)
	assert_eq(Mkit.ui(), ui)


func _register_node_service(service_id: String, service: Node) -> void:
	_registered_node_services.append(service)
	ServiceRegistry.register_service(service_id, service)


func _free_node_services(services: Dictionary) -> void:
	for service in services.values():
		var node := service as Node
		if node != null:
			node.free()


func _cleanup_service_registry() -> void:
	for child in ServiceRegistry.get_children():
		ServiceRegistry.remove_child(child)
		child.free()
	ServiceRegistry.clear()


func _free_registered_node_services() -> void:
	for service in _registered_node_services:
		if is_instance_valid(service):
			service.free()
	_registered_node_services = []
