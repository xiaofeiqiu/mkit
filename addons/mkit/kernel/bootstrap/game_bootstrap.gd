class_name GameBootstrap
extends Node
@export var resource_databases: Array[ResourceDatabase] = []
@export var initial_scene_path: String = ""


func _ready() -> void:
	boot()


func boot() -> void:
	_register_kernel_services()
	_load_content()
	_validate_content()
	_load_profile()
	_enter_initial_scene.call_deferred()


func _register_kernel_services() -> void:
	if ServiceRegistry == null:
		push_error("GameBootstrap: ServiceRegistry autoload is missing")
		return
	if ServiceRegistry.has_service("events"):
		return
	var events := EventService.new()
	var content := ContentService.new()
	var random := RandomService.new()
	var time := TimeService.new()
	var action_runner := ActionService.new()
	var effect_executor := EffectService.new()
	var command_router := CommandService.new()
	var combat := CombatService.new()
	var scene_router := SceneService.new()
	var object_pool := PoolService.new()
	var save_manager := SaveService.new()
	var progression := ProgressionService.new()
	var analytics := AnalyticsServiceMock.new()
	var ads := AdServiceMock.new()
	var iap := IAPServiceMock.new()
	var cloud_save := CloudSaveServiceMock.new()
	events.name = "EventService"
	content.name = "ContentService"
	action_runner.name = "ActionService"
	command_router.name = "CommandService"
	scene_router.name = "SceneService"
	object_pool.name = "PoolService"
	save_manager.name = "SaveService"
	progression.name = "ProgressionService"
	analytics.name = "AnalyticsService"
	ads.name = "AdService"
	iap.name = "IAPService"
	cloud_save.name = "CloudSaveService"
	ServiceRegistry.add_child(events)
	ServiceRegistry.add_child(content)
	ServiceRegistry.add_child(action_runner)
	ServiceRegistry.add_child(command_router)
	ServiceRegistry.add_child(scene_router)
	ServiceRegistry.add_child(object_pool)
	ServiceRegistry.add_child(save_manager)
	ServiceRegistry.add_child(progression)
	ServiceRegistry.add_child(analytics)
	ServiceRegistry.add_child(ads)
	ServiceRegistry.add_child(iap)
	ServiceRegistry.add_child(cloud_save)
	ServiceRegistry.register_service("events", events)
	ServiceRegistry.register_service("content", content)
	ServiceRegistry.register_service("random", random)
	ServiceRegistry.register_service("time", time)
	ServiceRegistry.register_service("actions", action_runner)
	ServiceRegistry.register_service("effects", effect_executor)
	ServiceRegistry.register_service("commands", command_router)
	ServiceRegistry.register_service("combat", combat)
	ServiceRegistry.register_service("scenes", scene_router)
	ServiceRegistry.register_service("pool", object_pool)
	ServiceRegistry.register_service("save", save_manager)
	ServiceRegistry.register_service("progression", progression)
	ServiceRegistry.register_service("analytics", analytics)
	ServiceRegistry.register_service("ads", ads)
	ServiceRegistry.register_service("iap", iap)
	ServiceRegistry.register_service("cloud_save", cloud_save)
	var quest := QuestService.new()
	quest.name = "QuestService"
	ServiceRegistry.add_child(quest)
	ServiceRegistry.register_service("quest", quest)
	var shop := ShopService.new()
	shop.name = "ShopService"
	ServiceRegistry.add_child(shop)
	ServiceRegistry.register_service("shop", shop)
	var audio := AudioService.new()
	audio.name = "AudioService"
	ServiceRegistry.add_child(audio)
	ServiceRegistry.register_service("audio", audio)
	var dialogue := DialogueService.new()
	dialogue.name = "DialogueService"
	ServiceRegistry.add_child(dialogue)
	ServiceRegistry.register_service("dialogue", dialogue)
	var world := WorldService.new()
	world.name = "WorldService"
	ServiceRegistry.add_child(world)
	ServiceRegistry.register_service("world", world)


func _load_content() -> void:
	var registry := ServiceRegistry.get_service("content") as ContentService
	if registry == null:
		push_error("GameBootstrap._load_content: missing ContentService service")
		return
	for db in resource_databases:
		if db != null:
			registry.load_database(db)


func _validate_content() -> void:
	var registry := ServiceRegistry.get_service("content") as ContentService
	if registry == null:
		push_error("GameBootstrap._validate_content: missing ContentService service")
		return
	var result := registry.validate_all()
	if not result.success:
		push_error("Content validation failed: %s" % result.errors)


func _load_profile() -> void:
	var save_manager: SaveService = null
	if ServiceRegistry.has_service("save"):
		save_manager = ServiceRegistry.get_service("save") as SaveService
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
	if ServiceRegistry.has_service("scenes"):
		scene_router = ServiceRegistry.get_service("scenes") as SceneService
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
