class_name GameBootstrap
extends Node
## 说明：`GameBootstrap` 是 启动流程 的组合根，负责注册服务、加载内容并进入初始场景。
## 上游：通常由项目主场景或游戏自定义 bootstrap创建或调用。
## 下游：会连接ServiceRegistry、ContentService、SaveService 和 SceneService，不直接依赖具体游戏内容。
## 使用：当项目项目启动时需要注册服务、加载内容和进入初始场景时使用它。
## 示例：`var instance := GameBootstrap.new()`

## 启动时加载进 ContentService 的资源数据库列表；顺序会影响重复 id 的报错位置。
@export var resource_databases: Array[ResourceDatabase] = []
## 启动完成后进入的主场景路径；应填写 res:// 开头的 .tscn 路径。
@export var initial_scene_path: String = ""
## 存档文件路径；通常使用 user://，为空时调用方应显式决定是否跳过读写。
@export var save_path: String = ""


func _ready() -> void:
	boot()


## 启动 runtime：注册 kernel services、加载 ResourceDatabase、配置内容驱动服务、校验 content、尝试读取 save，并延迟进入 initial_scene_path。
## ServiceRegistry 已有 EventService 时会跳过重复注册，避免测试或热重载重复创建服务。
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
	if ServiceRegistry.has_service(EventService.SERVICE_ID):
		print("[mkit] GameBootstrap: services already registered, skipping")
		return
	var services := _build_services()
	for service_id in services:
		_register_service_entry(service_id, services[service_id])
	_notify_services_ready(services)
	print("[mkit] GameBootstrap runtime services: %s" % ", ".join(ServiceRegistry.get_registered_service_ids()))


## 有序的 service id 到服务实例映射。覆写它可以新增或替换服务；Node 服务会挂到 ServiceRegistry 下，RefCounted 服务不会。
## 这里只注册 kernel 服务；gameplay module 服务由 ModuleBootstrap 追加。
func _build_services() -> Dictionary:
	return {
		EventService.SERVICE_ID: EventService.new(),
		ContentService.SERVICE_ID: ContentService.new(),
		RandomService.SERVICE_ID: RandomService.new(),
		TimeService.SERVICE_ID: TimeService.new(),
		ActionService.SERVICE_ID: ActionService.new(),
		EffectService.SERVICE_ID: EffectService.new(),
		CommandService.SERVICE_ID: CommandService.new(),
		SceneService.SERVICE_ID: SceneService.new(),
		PoolService.SERVICE_ID: PoolService.new(),
		SaveService.SERVICE_ID: SaveService.new(),
		AudioService.SERVICE_ID: AudioService.new(),
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


func _notify_services_ready(services: Dictionary) -> void:
	for service_id in services:
		var service := services[service_id] as Object
		if service != null and service.has_method("_on_services_ready"):
			service.call("_on_services_ready")


func _service_node_name(service: Object) -> String:
	var script := service.get_script() as Script
	if script != null and script.get_global_name() != &"":
		return str(script.get_global_name())
	return service.get_class()


func _load_content() -> void:
	var registry := ServiceRegistry.get_port(ContentService.SERVICE_ID) as ContentService
	if registry == null:
		push_error("GameBootstrap._load_content: missing ContentService service")
		return
	for db in resource_databases:
		if db != null:
			registry.load_database(db)


func _configure_content_services() -> void:
	_register_audio_definitions()


func _register_audio_definitions() -> void:
	var registry := ServiceRegistry.get_port(ContentService.SERVICE_ID) as ContentService
	var audio := ServiceRegistry.get_port(AudioService.SERVICE_ID) as AudioService
	if registry == null or audio == null:
		return
	audio.register_audio_definitions(registry.get_all_by_type(AudioDefinition.TYPE_NAME))


func _validate_content() -> void:
	var registry := ServiceRegistry.get_port(ContentService.SERVICE_ID) as ContentService
	if registry == null:
		push_error("GameBootstrap._validate_content: missing ContentService service")
		return
	var result := registry.validate_all()
	if not result.success:
		push_error("Content validation failed: %s" % result.errors)


func _load_profile() -> void:
	var save_manager := ServiceRegistry.get_port(SaveService.SERVICE_ID) as SaveService
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
	var scene_router := ServiceRegistry.get_port(SceneService.SERVICE_ID) as SceneService
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
