class_name GameBootstrap
extends Node
@export var resource_databases: Array[ResourceDatabase] = []
@export var initial_scene_path: String = ""
var _runtime_context: MkitRuntimeContext = null


func _ready() -> void:
	boot()


func boot() -> void:
	_runtime_context = MkitRuntimeContext.new()
	_register_kernel_services()
	_load_content()
	_validate_content()
	_load_profile()
	_enter_initial_scene.call_deferred()


func _register_kernel_services() -> void:
	if ServiceRegistry == null:
		push_error("GameBootstrap: ServiceRegistry autoload is missing")
		return
	if ServiceRegistry.has_service(ServiceRegistry.SERVICE_EVENTS):
		if _runtime_context != null:
			ServiceRegistry.set_runtime_context(_runtime_context)
			for existing_id in ServiceRegistry.get_port_ids():
				var existing_service := ServiceRegistry.get_port(existing_id)
				if existing_service != null:
					_runtime_context.register_port(existing_id, existing_service)
			print("[mkit] GameBootstrap: runtime context attached to pre-registered services")
		return
	ServiceRegistry.set_runtime_context(_runtime_context)
	for service_data in _build_kernel_services():
		_register_service_entry(
			service_data["id"],
			service_data["service"],
			service_data["add_as_child"],
			service_data.get("node_name", "")
		)
	print("[mkit] GameBootstrap runtime services: %s" % ", ".join(_runtime_context.get_registered_ports()))


func _build_kernel_services() -> Array[Dictionary]:
	return [
		{
			"id": ServiceRegistry.SERVICE_EVENTS,
			"service": EventService.new(),
			"node_name": "EventService",
			"add_as_child": true
		},
		{
			"id": ServiceRegistry.SERVICE_CONTENT,
			"service": ContentService.new(),
			"node_name": "ContentService",
			"add_as_child": true
		},
		{
			"id": ServiceRegistry.SERVICE_RANDOM,
			"service": RandomService.new(),
			"node_name": "",
			"add_as_child": false
		},
		{
			"id": ServiceRegistry.SERVICE_TIME,
			"service": TimeService.new(),
			"node_name": "",
			"add_as_child": false
		},
		{
			"id": ServiceRegistry.SERVICE_ACTIONS,
			"service": ActionService.new(),
			"node_name": "ActionService",
			"add_as_child": true
		},
		{
			"id": ServiceRegistry.SERVICE_EFFECTS,
			"service": EffectService.new(),
			"node_name": "",
			"add_as_child": false
		},
		{
			"id": ServiceRegistry.SERVICE_COMMANDS,
			"service": CommandService.new(),
			"node_name": "CommandService",
			"add_as_child": true
		},
		{
			"id": ServiceRegistry.SERVICE_COMBAT,
			"service": CombatService.new(),
			"node_name": "",
			"add_as_child": false
		},
		{
			"id": ServiceRegistry.SERVICE_SCENES,
			"service": SceneService.new(),
			"node_name": "SceneService",
			"add_as_child": true
		},
		{
			"id": ServiceRegistry.SERVICE_POOL,
			"service": PoolService.new(),
			"node_name": "PoolService",
			"add_as_child": true
		},
		{
			"id": ServiceRegistry.SERVICE_SAVE,
			"service": SaveService.new(),
			"node_name": "SaveService",
			"add_as_child": true
		},
		{
			"id": ServiceRegistry.SERVICE_PROGRESSION,
			"service": ProgressionService.new(),
			"node_name": "ProgressionService",
			"add_as_child": true
		},
		{
			"id": ServiceRegistry.SERVICE_ANALYTICS,
			"service": AnalyticsServiceMock.new(),
			"node_name": "AnalyticsService",
			"add_as_child": true
		},
		{
			"id": ServiceRegistry.SERVICE_ADS,
			"service": AdServiceMock.new(),
			"node_name": "AdService",
			"add_as_child": true
		},
		{
			"id": ServiceRegistry.SERVICE_IAP,
			"service": IAPServiceMock.new(),
			"node_name": "IAPService",
			"add_as_child": true
		},
		{
			"id": ServiceRegistry.SERVICE_CLOUD_SAVE,
			"service": CloudSaveServiceMock.new(),
			"node_name": "CloudSaveService",
			"add_as_child": true
		},
		{
			"id": ServiceRegistry.SERVICE_QUEST,
			"service": QuestService.new(),
			"node_name": "QuestService",
			"add_as_child": true
		},
		{
			"id": ServiceRegistry.SERVICE_SHOP,
			"service": ShopService.new(),
			"node_name": "ShopService",
			"add_as_child": true
		},
		{
			"id": ServiceRegistry.SERVICE_AUDIO,
			"service": AudioService.new(),
			"node_name": "AudioService",
			"add_as_child": true
		},
		{
			"id": ServiceRegistry.SERVICE_DIALOGUE,
			"service": DialogueService.new(),
			"node_name": "DialogueService",
			"add_as_child": true
		},
		{
			"id": ServiceRegistry.SERVICE_WORLD,
			"service": WorldService.new(),
			"node_name": "WorldService",
			"add_as_child": true
		},
		{
			"id": ServiceRegistry.SERVICE_LOOT,
			"service": LootService.new(),
			"node_name": "",
			"add_as_child": false
		}
	]


func _register_service_entry(
	service_id: String, service: Object, add_as_child: bool, node_name: String = ""
) -> void:
	if service == null:
		push_warning("GameBootstrap._register_service_entry: service is null for %s" % service_id)
		return
	if add_as_child:
		var node := service as Node
		if node == null:
			push_warning(
				"GameBootstrap._register_service_entry: %s expected Node but got %s"
				% [service_id, service.get_class()]
			)
			return
		node.name = node_name if node_name != "" else str(service.get_class())
		ServiceRegistry.add_child(node)
	ServiceRegistry.register_service(service_id, service)


func _load_content() -> void:
	var registry := ServiceRegistry.get_port(ServiceRegistry.SERVICE_CONTENT) as ContentService
	if registry == null:
		push_error("GameBootstrap._load_content: missing ContentService service")
		return
	for db in resource_databases:
		if db != null:
			registry.load_database(db)


func _validate_content() -> void:
	var registry := ServiceRegistry.get_port(ServiceRegistry.SERVICE_CONTENT) as ContentService
	if registry == null:
		push_error("GameBootstrap._validate_content: missing ContentService service")
		return
	var result := registry.validate_all()
	if not result.success:
		push_error("Content validation failed: %s" % result.errors)


func _load_profile() -> void:
	var save_manager := ServiceRegistry.get_port(ServiceRegistry.SERVICE_SAVE) as SaveService
	if save_manager == null:
		return
	var tree := get_tree()
	if tree != null and FileAccess.file_exists(save_manager.save_path):
		save_manager.load_game(tree.root)


func _enter_initial_scene() -> void:
	if initial_scene_path == "":
		return
	if not ResourceLoader.exists(initial_scene_path, "PackedScene"):
		push_error(
			(
				"GameBootstrap.initial_scene_path must point to an existing PackedScene resource, but got: %s"
				% initial_scene_path
			)
		)
		return
	if _is_same_scene_as_self(initial_scene_path):
		push_error(
			(
				"GameBootstrap.initial_scene_path (%s) points to the scene that already contains this GameBootstrap. Refusing to reload it (that would be an infinite bootstrap loop). Put GameBootstrap in a minimal scene and point initial_scene_path at a different scene."
				% initial_scene_path
			)
		)
		return
	var scene_router: SceneService = null
	scene_router = ServiceRegistry.get_port(ServiceRegistry.SERVICE_SCENES) as SceneService
	if scene_router != null:
		scene_router.change_scene(initial_scene_path)
	else:
		get_tree().change_scene_to_file(initial_scene_path)


func _is_same_scene_as_self(target_path: String) -> bool:
	var tree := get_tree()
	if tree == null or tree.current_scene == null:
		return false
	var current_path := tree.current_scene.scene_file_path
	if current_path == "":
		return false
	return _normalize_scene_path(target_path) == _normalize_scene_path(current_path)


func _normalize_scene_path(path: String) -> String:
	if path.begins_with("uid://"):
		var id := ResourceUID.text_to_id(path)
		if ResourceUID.has_id(id):
			return ResourceUID.get_id_path(id)
	return path
