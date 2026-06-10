extends GutTest


const SCENE_TARGET_PATH := "res://test/integration/tmp_mkit_int_scene_router_target.tscn"
const MODAL_SCREEN_PATH := "res://test/integration/tmp_mkit_int_modal_screen.tscn"
const SAVE_PATH := "/tmp/mkit_ui_interaction_ai_scene_integration_save.json"


class RecordingReceiver:
	extends CommandReceiver
	var last_command: GameCommand = null
	var command_types: Array[String] = []

	func handle_unhandled_command(command: GameCommand) -> bool:
		last_command = command
		command_types.append(command.command_type)
		return true


class EffectInteractable:
	extends Interactable
	var effects: Array[GameEffect] = []
	var call_count: int = 0
	var last_context: GameplayContext = null

	func _interact_impl(context: GameplayContext) -> bool:
		call_count += 1
		last_context = context
		var executor := ServiceRegistry.get_service("effects") as EffectService
		if executor == null:
			return false
		var results := executor.execute_many(effects, context, true)
		for result in results:
			if not result.success:
				return false
		return true


func after_each() -> void:
	_cleanup_current_scene()
	IntTestHelpers.remove_file(SCENE_TARGET_PATH)
	IntTestHelpers.remove_file(MODAL_SCREEN_PATH)
	IntTestHelpers.remove_file(SAVE_PATH)
	IntTestHelpers.cleanup_service_registry()


func test_tc_int_ui_01_enemy_brain_dispatches_command_to_receiver() -> void:
	_boot_runtime()
	var router := ServiceRegistry.get_service("commands") as CommandService
	assert_not_null(router)

	var world := Node2D.new()
	world.name = "World"
	add_child_autofree(world)

	var player := _make_ai_target()
	world.add_child(player)

	var enemy := _make_ai_enemy()
	world.add_child(enemy)

	var brain := enemy.get_node("Controllers/SimpleAIEnemyBrain") as SimpleAIEnemyBrain
	var receiver := enemy.get_node("CommandReceiver") as RecordingReceiver
	await get_tree().process_frame

	watch_signals(router)
	brain.think()

	assert_eq(receiver.command_types, [BuiltinCommands.ATTACK])
	assert_not_null(receiver.last_command)
	assert_eq(receiver.last_command.command_type, BuiltinCommands.ATTACK)
	assert_eq(receiver.last_command.source_id, "enemy.int.ai")
	assert_eq(receiver.last_command.target_id, "enemy.int.ai")
	assert_eq(receiver.last_command.payload["target"], player)
	assert_signal_emitted(router, "command_dispatched")
	assert_signal_not_emitted(router, "command_failed")

	player.global_position = Vector2(96.0, 0.0)
	brain.think()

	assert_eq(receiver.command_types, [BuiltinCommands.ATTACK, BuiltinCommands.MOVE])
	assert_eq(receiver.last_command.command_type, BuiltinCommands.MOVE)
	assert_eq(receiver.last_command.get_vector2("direction"), Vector2.RIGHT)
	assert_eq(receiver.command_history.size(), 2)


func test_tc_int_ui_02_interaction_executes_interactable_effects() -> void:
	_boot_runtime()
	var effects := ServiceRegistry.get_service("effects") as EffectService
	assert_not_null(effects)

	var world := Node2D.new()
	world.name = "World"
	add_child_autofree(world)

	var player := _make_interactor_entity()
	var target := _make_interactable_entity()
	world.add_child(player)
	world.add_child(target)

	var interaction := player.get_node("Components/InteractionComponent") as InteractionComponent
	var interactable := (
		target.get_node("InteractionArea/Interactable") as EffectInteractable
	)
	var probe := IntTestHelpers.ProbeEffect.new()
	probe.effect_id = "fx.int.interact_probe"
	probe.result_payload = {"interaction_id": "interactable.int.effect"}
	var interactable_effects: Array[GameEffect] = [probe]
	interactable.effects = interactable_effects

	watch_signals(interaction)
	await _wait_for_physics_overlap()

	assert_eq(interaction.current_interactable, interactable)
	assert_signal_emitted_with_parameters(interaction, "interactable_focused", [interactable])

	assert_true(interaction.try_interact())
	assert_eq(interactable.call_count, 1)
	assert_eq(interactable.last_context.source, player)
	assert_eq(interactable.last_context.target, target)
	assert_eq(probe.call_count, 1)
	assert_eq(probe.contexts[0].source, player)
	assert_eq(probe.contexts[0].target, target)
	assert_eq(effects.recent_results[-1].effect_id, "fx.int.interact_probe")


func test_tc_int_ui_03_scene_router_emits_success_and_failure_paths() -> void:
	_boot_runtime()
	_save_plain_scene(SCENE_TARGET_PATH, "SceneRouterTarget")
	var router := ServiceRegistry.get_service("scenes") as SceneService
	assert_not_null(router)

	watch_signals(router)
	assert_false(router.change_scene(""))
	assert_signal_emitted_with_parameters(router, "scene_change_failed", ["", "empty_scene_path"])

	assert_true(router.change_scene(SCENE_TARGET_PATH))
	assert_eq(router.current_scene_path, SCENE_TARGET_PATH)
	assert_signal_emitted_with_parameters(
		router, "scene_change_requested", [SCENE_TARGET_PATH]
	)
	assert_signal_emitted_with_parameters(router, "scene_changed", [SCENE_TARGET_PATH])
	for _i in 2:
		await get_tree().process_frame
	_cleanup_current_scene()

	router.transition_locked = true
	assert_false(router.change_scene(SCENE_TARGET_PATH))
	assert_signal_emitted_with_parameters(
		router, "scene_change_failed", [SCENE_TARGET_PATH, "transition_locked"]
	)
	router.transition_locked = false


func test_tc_int_ui_04_modal_ui_pauses_and_closes_to_resume_time() -> void:
	_boot_runtime()
	_save_control_scene(MODAL_SCREEN_PATH, "ModalScreen")
	var time := ServiceRegistry.get_service("time") as TimeService
	var ui := _make_ui_manager({"modal.int.pause": MODAL_SCREEN_PATH})
	assert_not_null(time)
	assert_not_null(ui)

	watch_signals(ui)
	var screen := ui.open_screen("modal.int.pause", {"source": "integration"}, true)

	assert_not_null(screen)
	assert_true(ui.is_screen_open("modal.int.pause"))
	assert_true(time.paused)
	assert_eq(ui.modal_screens, ["modal.int.pause"])
	assert_signal_emitted_with_parameters(ui, "screen_opened", ["modal.int.pause"])

	ui.close_screen("modal.int.pause")

	assert_false(ui.is_screen_open("modal.int.pause"))
	assert_false(time.paused)
	assert_true(ui.modal_screens.is_empty())
	assert_signal_emitted_with_parameters(ui, "screen_closed", ["modal.int.pause"])


func test_tc_int_ui_05_ui_manager_registers_ui_service() -> void:
	var ui := _make_ui_manager({})
	await get_tree().process_frame

	assert_true(ServiceRegistry.has_service("ui"))
	assert_eq(ServiceRegistry.get_service("ui"), ui)


func _boot_runtime() -> ModuleBootstrap:
	var bootstrap := ModuleBootstrap.new()
	bootstrap.save_path = SAVE_PATH
	add_child_autofree(bootstrap)
	return bootstrap


func _make_ai_target() -> Node2D:
	var player := IntTestHelpers.make_health_entity("Player", "player.int.ai", 100.0)
	player.name = "Player"
	player.global_position = Vector2(24.0, 0.0)
	player.add_to_group("player")
	return player


func _make_ai_enemy() -> Node2D:
	var enemy := IntTestHelpers.make_entity("Enemy", "enemy.int.ai")
	enemy.global_position = Vector2.ZERO
	var old_receiver := enemy.get_node("CommandReceiver") as CommandReceiver
	if old_receiver != null:
		enemy.remove_child(old_receiver)
		old_receiver.free()
	var receiver := RecordingReceiver.new()
	receiver.name = "CommandReceiver"
	receiver.receiver_id = "enemy.int.ai"
	receiver.auto_register = true
	enemy.add_child(receiver)
	var brain := SimpleAIEnemyBrain.new()
	brain.name = "SimpleAIEnemyBrain"
	brain.enabled = false
	brain.attack_range = 48.0
	brain.detection_range = 160.0
	var controllers := enemy.get_node("Controllers") as Node
	controllers.add_child(brain)
	IntTestHelpers.assign_owner(enemy, enemy)
	return enemy


func _make_interactor_entity() -> Node2D:
	var player := IntTestHelpers.make_entity("Interactor", "interactor.int", [])
	player.name = "Interactor"
	player.global_position = Vector2.ZERO
	var components := player.get_node("Components") as Node
	var interaction := components.get_node_or_null("InteractionComponent") as InteractionComponent
	if interaction == null:
		interaction = InteractionComponent.new()
		interaction.name = "InteractionComponent"
		components.add_child(interaction)
		IntTestHelpers.add_circle_collision_shape(interaction, 16.0)
	interaction.collision_layer = 1
	interaction.collision_mask = 2
	interaction.monitoring = true
	interaction.monitorable = true
	IntTestHelpers.assign_owner(player, player)
	return player


func _make_interactable_entity() -> Node2D:
	var target := Node2D.new()
	target.name = "InteractableTarget"
	target.global_position = Vector2.ZERO
	var area := Area2D.new()
	area.name = "InteractionArea"
	area.collision_layer = 2
	area.collision_mask = 1
	area.monitoring = true
	area.monitorable = true
	target.add_child(area)
	IntTestHelpers.add_circle_collision_shape(area, 16.0)
	var interactable := EffectInteractable.new()
	interactable.name = "Interactable"
	interactable.interaction_id = "interactable.int.effect"
	area.add_child(interactable)
	IntTestHelpers.assign_owner(target, target)
	return target


func _wait_for_physics_overlap() -> void:
	for _i in 3:
		await get_tree().physics_frame


func _save_plain_scene(path: String, node_name: String) -> void:
	var root := Node2D.new()
	root.name = node_name
	_save_packed_scene(root, path)


func _save_control_scene(path: String, node_name: String) -> void:
	var root := Control.new()
	root.name = node_name
	_save_packed_scene(root, path)


func _save_packed_scene(root: Node, path: String) -> void:
	var packed := PackedScene.new()
	assert_eq(packed.pack(root), OK)
	assert_eq(ResourceSaver.save(packed, path), OK)
	root.free()


func _make_ui_manager(screen_map: Dictionary) -> UIManager:
	var ui := UIManager.new()
	ui.name = "UIManager"
	ui.screen_scene_map = screen_map
	var screen_root := Node.new()
	screen_root.name = "ScreenRoot"
	ui.add_child(screen_root)
	add_child_autofree(ui)
	return ui


func _cleanup_current_scene() -> void:
	var tree := get_tree()
	if tree == null:
		return
	_free_temp_scene_node(tree.current_scene)
	for child in tree.root.get_children():
		_free_temp_scene_node(child)


func _free_temp_scene_node(scene: Node) -> void:
	if scene == null or not is_instance_valid(scene):
		return
	if not _is_temp_scene_node(scene):
		return
	if scene.get_parent() != null:
		scene.get_parent().remove_child(scene)
	scene.free()


func _is_temp_scene_node(scene: Node) -> bool:
	return (
		scene.scene_file_path == SCENE_TARGET_PATH
		or scene.scene_file_path == MODAL_SCREEN_PATH
		or scene.name == "SceneRouterTarget"
		or scene.name == "ModalScreen"
	)
