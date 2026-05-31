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
	# Defer the scene change: boot() typically runs from _ready(), during which
	# the SceneTree is still busy adding this node, and change_scene_to_file()
	# (which frees the current scene) is not allowed mid-mutation. Deferring runs
	# it once the tree settles.
	_enter_initial_scene.call_deferred()


func _register_kernel_services() -> void:
	# Idempotent: a GameBootstrap may run again (e.g. a second bootstrap scene).
	# Services live as long as the app, so don't rebuild them.
	if ServiceRegistry.has_service("events"):
		return

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

	# Parent the Node-based services under the persistent ServiceRegistry autoload,
	# NOT under this bootstrap node. The bootstrap node is freed when it changes to
	# the initial scene; parenting here would free the services with it and leave
	# the registry holding freed references.
	ServiceRegistry.add_child(events)
	ServiceRegistry.add_child(content)
	ServiceRegistry.add_child(action_runner)
	ServiceRegistry.add_child(command_router)
	ServiceRegistry.add_child(scene_router)
	ServiceRegistry.add_child(object_pool)

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
	if initial_scene_path == "":
		return
	if not ResourceLoader.exists(initial_scene_path, "PackedScene"):
		push_error("GameBootstrap.initial_scene_path must point to an existing PackedScene resource, but got: %s" % initial_scene_path)
		return

	# Guard against the bootstrap loop: if initial_scene_path resolves to the same
	# scene that already contains this GameBootstrap, changing to it re-runs boot()
	# in the freshly loaded copy, which changes scene again, forever. A bootstrap
	# scene must point at a DIFFERENT gameplay/menu scene.
	if _is_same_scene_as_self(initial_scene_path):
		push_error("GameBootstrap.initial_scene_path (%s) points to the scene that already contains this GameBootstrap. Refusing to reload it (that would be an infinite bootstrap loop). Put GameBootstrap in a minimal scene and point initial_scene_path at a different scene." % initial_scene_path)
		return

	var scene_router := ServiceRegistry.get_service("scenes") as SceneRouter
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
