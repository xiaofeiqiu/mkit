class_name GameBootstrap
extends Node
@export var resource_databases: Array[ResourceDatabase] = []
@export var initial_scene_path: String = ""
@export var save_path: String = ""


func _ready() -> void:
	boot()


func boot() -> void:
	_register_kernel_services()
	_load_content()
	_configure_content_services()
	_validate_content()
	_load_profile()
	_enter_initial_scene.call_deferred()


func _register_kernel_services() -> void:
	if ServiceRegistry == null:
		push_error("GameBootstrap: ServiceRegistry autoload is missing")
		return
	if ServiceRegistry.has_service(ServiceRegistry.SERVICE_EVENTS):
		print("[mkit] GameBootstrap: services already registered, skipping")
		return
	var services := _build_kernel_services()
	for service_id in services:
		_register_service_entry(service_id, services[service_id])
	print("[mkit] GameBootstrap runtime services: %s" % ", ".join(ServiceRegistry.get_registered_service_ids()))


## Ordered id -> service instance table. Override to add or replace services;
## Node services are added as children of ServiceRegistry, RefCounted ones are not.
func _build_kernel_services() -> Dictionary:
	return {
		ServiceRegistry.SERVICE_EVENTS: EventService.new(),
		ServiceRegistry.SERVICE_CONTENT: ContentService.new(),
		ServiceRegistry.SERVICE_RANDOM: RandomService.new(),
		ServiceRegistry.SERVICE_TIME: TimeService.new(),
		ServiceRegistry.SERVICE_ACTIONS: ActionService.new(),
		ServiceRegistry.SERVICE_EFFECTS: EffectService.new(),
		ServiceRegistry.SERVICE_COMMANDS: CommandService.new(),
		ServiceRegistry.SERVICE_COMBAT: CombatService.new(),
		ServiceRegistry.SERVICE_SCENES: SceneService.new(),
		ServiceRegistry.SERVICE_POOL: PoolService.new(),
		ServiceRegistry.SERVICE_SAVE: SaveService.new(),
		ServiceRegistry.SERVICE_PROGRESSION: ProgressionService.new(),
		ServiceRegistry.SERVICE_ANALYTICS: AnalyticsServiceMock.new(),
		ServiceRegistry.SERVICE_ADS: AdServiceMock.new(),
		ServiceRegistry.SERVICE_IAP: IAPServiceMock.new(),
		ServiceRegistry.SERVICE_CLOUD_SAVE: CloudSaveServiceMock.new(),
		ServiceRegistry.SERVICE_QUEST: QuestService.new(),
		ServiceRegistry.SERVICE_SHOP: ShopService.new(),
		ServiceRegistry.SERVICE_AUDIO: AudioService.new(),
		ServiceRegistry.SERVICE_DIALOGUE: DialogueService.new(),
		ServiceRegistry.SERVICE_WORLD: WorldService.new(),
		ServiceRegistry.SERVICE_LOOT: LootService.new(),
	}


func _register_service_entry(service_id: String, service: Object) -> void:
	if service == null:
		push_warning("GameBootstrap._register_service_entry: service is null for %s" % service_id)
		return
	var node := service as Node
	if node != null:
		node.name = _service_node_name(service)
		ServiceRegistry.add_child(node)
	ServiceRegistry.register_service(service_id, service)


func _service_node_name(service: Object) -> String:
	var script := service.get_script() as Script
	if script != null and script.get_global_name() != &"":
		return str(script.get_global_name())
	return service.get_class()


func _load_content() -> void:
	var registry := ServiceRegistry.get_port(ServiceRegistry.SERVICE_CONTENT) as ContentService
	if registry == null:
		push_error("GameBootstrap._load_content: missing ContentService service")
		return
	for db in resource_databases:
		if db != null:
			registry.load_database(db)


func _configure_content_services() -> void:
	_register_audio_definitions()


func _register_audio_definitions() -> void:
	var registry := ServiceRegistry.get_port(ServiceRegistry.SERVICE_CONTENT) as ContentService
	var audio := ServiceRegistry.get_port(ServiceRegistry.SERVICE_AUDIO) as AudioService
	if registry == null or audio == null:
		return
	audio.register_audio_definitions(registry.get_all_by_type(AudioDefinition.TYPE_NAME))


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
	if save_path != "":
		save_manager.save_path = save_path
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
	var scene_router := ServiceRegistry.get_port(ServiceRegistry.SERVICE_SCENES) as SceneService
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
