extends GutTest


func test_tc_ec_01_entity_root_resolves_contract_nodes() -> void:
	var entity := _build_entity_root()
	var query_node := entity.get_node("Components/HealthComponent")
	var component := EntityContract.get_component(query_node, "HealthComponent") as Node
	var controller := EntityContract.get_controller(query_node, "AbilityController") as Node
	var identity := EntityContract.get_identity(query_node) as EntityIdentity
	var state_machine := EntityContract.get_state_machine(query_node) as StateMachine
	var receiver := EntityContract.get_command_receiver(query_node) as CommandReceiver

	assert_not_null(component)
	assert_eq(component.name, "HealthComponent")
	assert_not_null(controller)
	assert_eq(controller.name, "AbilityController")
	assert_not_null(identity)
	assert_eq(identity.entity_id, "test.entity.001")
	assert_not_null(state_machine)
	assert_eq(state_machine.name, "StateMachine")
	assert_not_null(receiver)
	assert_eq(receiver.name, "CommandReceiver")


func test_tc_ec_02_entity_root_resolves_script_components_and_controllers() -> void:
	var entity := _build_entity_root_with_script_types()
	var query_node := entity.get_node("Components/ScriptProbeComponent")
	var script_component := EntityContract.get_component(query_node, StatsComponent) as Node
	var script_controller := EntityContract.get_controller(entity, InventoryController) as Node

	assert_not_null(script_component)
	assert_true(script_component is StatsComponent)
	assert_not_null(script_controller)
	assert_true(script_controller is InventoryController)


func test_tc_ec_03_nested_entity_nodes_still_resolve_contract_root() -> void:
	var entity := _build_entity_root()
	var nested := Node.new()
	nested.name = "Nested"
	entity.get_node("Controllers").add_child(nested)
	var got_identity := EntityContract.get_identity(nested) as EntityIdentity
	var got_component := EntityContract.get_component(nested, "HealthComponent") as Node

	assert_not_null(got_identity)
	assert_eq(got_identity.entity_id, "test.entity.001")
	assert_not_null(got_component)
	assert_eq(got_component.name, "HealthComponent")


func _build_entity_root() -> EntityRoot:
	var entity := EntityRoot.new()
	entity.name = "TestEntityRoot"

	var identity := EntityIdentity.new()
	identity.name = "EntityIdentity"
	identity.entity_id = "test.entity.001"
	entity.add_child(identity)

	var components := Node.new()
	components.name = "Components"
	var health := HealthComponent.new()
	health.name = "HealthComponent"
	components.add_child(health)
	entity.add_child(components)

	var controllers := Node.new()
	controllers.name = "Controllers"
	var ability := AbilityController.new()
	ability.name = "AbilityController"
	controllers.add_child(ability)
	entity.add_child(controllers)

	var presentation := Node.new()
	presentation.name = "Presentation"
	var animation_player := AnimationPlayer.new()
	animation_player.name = "AnimationPlayer"
	presentation.add_child(animation_player)
	entity.add_child(presentation)

	var state_machine := StateMachine.new()
	state_machine.name = "StateMachine"
	entity.add_child(state_machine)

	var command_receiver := CommandReceiver.new()
	command_receiver.name = "CommandReceiver"
	entity.add_child(command_receiver)

	add_child_autofree(entity)
	return entity


func _build_entity_root_with_script_types() -> EntityRoot:
	var entity := _build_entity_root()
	var components := entity.get_node("Components") as Node
	var script_probe := StatsComponent.new()
	script_probe.name = "ScriptProbeComponent"
	components.add_child(script_probe)
	var controllers := entity.get_node("Controllers") as Node
	var controller_probe := InventoryController.new()
	controller_probe.name = "ScriptProbeController"
	controllers.add_child(controller_probe)
	return entity
