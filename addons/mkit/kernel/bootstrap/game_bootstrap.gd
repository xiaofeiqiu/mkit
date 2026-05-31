class_name GameBootstrap
extends Node

# Startup orchestrator. Creates kernel services, registers them into the global
# ServiceRegistry, loads + validates content, then enters the initial scene.
#
# Phase 0 scope: only the kernel services implemented so far are constructed
# here. SaveManager and ProgressionSystem are registered in their own phases
# (Save / Meta progression); this file is extended at that point rather than
# rewritten.

@export var resource_databases: Array[ResourceDatabase] = []
@export var initial_scene_path: String = ""


func _ready() -> void:
	boot()


func boot() -> void:
	_register_kernel_services()
	_load_content()
	_validate_content()
	_initialize_runtime_systems()
	_load_profile()
	_enter_initial_scene()


func _register_kernel_services() -> void:
	var events := EventRouter.new()
	var content := ContentRegistry.new()
	var random := RandomService.new()
	var time := TimeService.new()
	var action_runner := ActionRunner.new()
	var effect_executor := EffectExecutor.new()
	var command_router := CommandRouter.new()
	var scene_router := SceneRouter.new()
	var object_pool := ObjectPool.new()

	events.name = "EventRouter"
	content.name = "ContentRegistry"
	action_runner.name = "ActionRunner"
	command_router.name = "CommandRouter"
	scene_router.name = "SceneRouter"
	object_pool.name = "ObjectPool"

	add_child(events)
	add_child(content)
	add_child(action_runner)
	add_child(command_router)
	add_child(scene_router)
	add_child(object_pool)

	ServiceRegistry.register_service("events", events)
	ServiceRegistry.register_service("content", content)
	ServiceRegistry.register_service("random", random)
	ServiceRegistry.register_service("time", time)
	ServiceRegistry.register_service("actions", action_runner)
	ServiceRegistry.register_service("effects", effect_executor)
	ServiceRegistry.register_service("commands", command_router)
	ServiceRegistry.register_service("scenes", scene_router)
	ServiceRegistry.register_service("pool", object_pool)


func _load_content() -> void:
	var registry := ServiceRegistry.get_service("content") as ContentRegistry
	for db in resource_databases:
		if db != null:
			registry.load_database(db)


func _validate_content() -> void:
	var registry := ServiceRegistry.get_service("content") as ContentRegistry
	var result := registry.validate_all()
	if not result.success:
		push_error("Content validation failed: %s" % result.errors)


func _initialize_runtime_systems() -> void:
	pass


func _load_profile() -> void:
	pass


func _enter_initial_scene() -> void:
	if initial_scene_path != "":
		var scene_router := ServiceRegistry.get_service("scenes") as SceneRouter
		if scene_router != null:
			scene_router.change_scene(initial_scene_path)
		else:
			get_tree().change_scene_to_file(initial_scene_path)
