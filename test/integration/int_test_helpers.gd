class_name IntTestHelpers
extends RefCounted

const QUEST_BOUNTY_ID := "quest.int.bounty"
const QUEST_OBJECTIVE_KILL_MARKED_ID := "obj.kill_marked"
const QUEST_REWARD_ITEM_ID := "item.int.reward"
const QUEST_MARKED_ENEMY_ID := "enemy.marked"
const QUEST_REWARD_CURRENCY_ID := "gold"
const QUEST_MARKED_TAG := "marked"


class PassingCondition:
	extends Condition
	var failure_reason: String = ""

	func _evaluate_impl(_context: GameplayContext) -> bool:
		return true

	func get_failure_reason(_context: GameplayContext) -> String:
		return failure_reason


class FailingCondition:
	extends Condition
	var failure_reason: String = "condition_failed"

	func _evaluate_impl(_context: GameplayContext) -> bool:
		return false

	func get_failure_reason(_context: GameplayContext) -> String:
		return failure_reason


class ProbeEffect:
	extends GameEffect
	var call_count: int = 0
	var contexts: Array[GameplayContext] = []
	var result_payload: Dictionary = {}

	func _apply_impl(context: GameplayContext) -> EffectResult:
		call_count += 1
		contexts.append(context)
		return EffectResult.ok(effect_id, result_payload.duplicate(true))


class FailingEffect:
	extends GameEffect
	var failure_reason: String = "effect_failed"

	func _apply_impl(_context: GameplayContext) -> EffectResult:
		return EffectResult.fail(effect_id, failure_reason)


class GrantCurrencyEffect:
	extends GameEffect
	var currency_id: String = "gold"
	var amount: int = 0

	func _apply_impl(_context: GameplayContext) -> EffectResult:
		if not ServiceRegistry.has_service("progression"):
			return EffectResult.fail(effect_id, "Missing progression service")
		var progression := ServiceRegistry.get_service("progression") as ProgressionService
		if progression == null:
			return EffectResult.fail(effect_id, "Missing progression service")
		progression.add_currency(currency_id, amount)
		return EffectResult.ok(effect_id, {"currency_id": currency_id, "amount": amount})


class DeterministicRandom:
	extends RandomService
	var randf_values: Array[float] = []
	var randf_range_values: Array[float] = []
	var randi_values: Array[int] = []
	var randi_range_values: Array[int] = []
	var default_randf: float = 0.0
	var default_randi: int = 0

	func set_seed(value: int) -> void:
		seed_value = value

	func randf() -> float:
		if not randf_values.is_empty():
			return float(randf_values.pop_front())
		return default_randf

	func randf_range(from: float, to: float) -> float:
		if not randf_range_values.is_empty():
			return float(randf_range_values.pop_front())
		return lerpf(from, to, clamp(default_randf, 0.0, 1.0))

	func randi() -> int:
		if not randi_values.is_empty():
			return int(randi_values.pop_front())
		return default_randi

	func randi_range(from: int, to: int) -> int:
		if not randi_range_values.is_empty():
			return clampi(int(randi_range_values.pop_front()), from, to)
		return clampi(default_randi, from, to)


static func cleanup_service_registry() -> void:
	remove_file("user://save.json")
	for child in ServiceRegistry.get_children():
		child.queue_free()
	ServiceRegistry.clear()


static func remove_file(path: String) -> void:
	if path.strip_edges() == "":
		return
	if not FileAccess.file_exists(path):
		return
	var absolute_path := path
	if path.begins_with("user://") or path.begins_with("res://"):
		absolute_path = ProjectSettings.globalize_path(path)
	DirAccess.remove_absolute(absolute_path)


static func make_resource_database(
	database_id: String,
	resources: Array[Resource] = [],
	resource_paths: Array[String] = []
) -> ResourceDatabase:
	var database := ResourceDatabase.new()
	database.database_id = database_id
	database.resources = resources
	database.resource_paths = resource_paths
	return database


static func save_resource_to_path(resource: Resource, path: String) -> String:
	var error := ResourceSaver.save(resource, path)
	if error != OK:
		push_error("Failed to save integration resource: %s" % path)
	return path


static func make_item_definition(
	item_id: String,
	stackable: bool = true,
	max_stack: int = 99,
	value: int = 0
) -> ItemDefinition:
	var item := ItemDefinition.new()
	item.item_id = item_id
	item.display_name = item_id
	item.stackable = stackable
	item.max_stack = max_stack
	item.value = value
	return item


static func make_ability_definition(
	ability_id: String,
	display_name: String = "",
	cooldown: float = 1.0,
	effects: Array[GameEffect] = [],
	conditions: Array[Condition] = []
) -> AbilityDefinition:
	var ability := AbilityDefinition.new()
	ability.ability_id = ability_id
	ability.display_name = display_name if display_name != "" else ability_id
	ability.cooldown = cooldown
	var copied_effects: Array[GameEffect] = []
	copied_effects.append_array(effects)
	ability.effects = copied_effects
	var copied_conditions: Array[Condition] = []
	copied_conditions.append_array(conditions)
	ability.conditions = copied_conditions
	return ability


static func make_quest_objective_definition(
	objective_id: String,
	event_type: String,
	match_key: String,
	match_value: String,
	required_count: int = 1
) -> QuestObjectiveDefinition:
	var objective := QuestObjectiveDefinition.new()
	objective.objective_id = objective_id
	objective.event_type = event_type
	objective.match_key = match_key
	objective.match_value = match_value
	objective.required_count = required_count
	return objective


static func make_grant_item_effect(
	effect_id: String,
	item_id: String,
	quantity: int = 1,
	give_to_source: bool = true
) -> GrantItemEffect:
	var effect := GrantItemEffect.new()
	effect.effect_id = effect_id
	effect.item_id = item_id
	effect.quantity = quantity
	effect.give_to_source = give_to_source
	return effect


static func make_grant_currency_effect(
	effect_id: String,
	currency_id: String,
	amount: int
) -> GrantCurrencyEffect:
	var effect := GrantCurrencyEffect.new()
	effect.effect_id = effect_id
	effect.currency_id = currency_id
	effect.amount = amount
	return effect


static func make_quest_definition(
	quest_id: String,
	display_name: String,
	objectives: Array[QuestObjectiveDefinition],
	reward_effects: Array[GameEffect],
	auto_complete: bool = true
) -> QuestDefinition:
	var quest := QuestDefinition.new()
	quest.quest_id = quest_id
	quest.display_name = display_name
	quest.objectives = objectives
	quest.reward_effects = reward_effects
	quest.auto_complete = auto_complete
	return quest


static func make_quest_pipeline_database() -> ResourceDatabase:
	var item := make_item_definition(QUEST_REWARD_ITEM_ID, true, 99)
	var objective := make_quest_objective_definition(
		QUEST_OBJECTIVE_KILL_MARKED_ID, "enemy_killed", "tags", QUEST_MARKED_TAG, 1
	)
	var grant_item := make_grant_item_effect("fx.int.reward_item", QUEST_REWARD_ITEM_ID, 2, true)
	var grant_currency := make_grant_currency_effect(
		"fx.int.reward_gold", QUEST_REWARD_CURRENCY_ID, 7
	)
	var objectives: Array[QuestObjectiveDefinition] = [objective]
	var rewards: Array[GameEffect] = [grant_item, grant_currency]
	var quest := make_quest_definition(QUEST_BOUNTY_ID, "Integration Bounty", objectives, rewards)
	var resources: Array[Resource] = [item, quest]
	return make_resource_database("quest_int", resources)


static func make_entity(
	entity_name: String,
	entity_id: String,
	tags: Array[String] = [],
	faction: String = "neutral"
) -> Node:
	var entity := Node.new()
	entity.name = entity_name
	var identity := EntityIdentity.new()
	identity.name = "EntityIdentity"
	identity.entity_id = entity_id
	identity.faction = faction
	var copied_tags: Array[String] = []
	copied_tags.append_array(tags)
	identity.tags = copied_tags
	entity.add_child(identity)
	ensure_child(entity, "Components")
	ensure_child(entity, "Controllers")
	ensure_child(entity, "Presentation")
	assign_owner(entity, entity)
	return entity


static func make_inventory_entity(
	entity_name: String,
	entity_id: String,
	capacity: int,
	tags: Array[String] = [],
	faction: String = "neutral"
) -> Node:
	var entity := make_entity(entity_name, entity_id, tags, faction)
	add_inventory_controller(entity, capacity)
	assign_owner(entity, entity)
	return entity


static func make_health_entity(
	entity_name: String,
	entity_id: String,
	current_hp: float,
	tags: Array[String] = [],
	faction: String = "neutral"
) -> Node:
	var entity := make_entity(entity_name, entity_id, tags, faction)
	add_health_component(entity, current_hp)
	assign_owner(entity, entity)
	return entity


static func ensure_child(parent: Node, child_name: String) -> Node:
	var existing := parent.get_node_or_null(child_name)
	if existing != null:
		return existing
	var child := Node.new()
	child.name = child_name
	parent.add_child(child)
	return child


static func add_inventory_controller(entity: Node, capacity: int = 30) -> InventoryController:
	var controllers := ensure_child(entity, "Controllers")
	var existing := controllers.get_node_or_null("InventoryController") as InventoryController
	if existing != null:
		existing.capacity = capacity
		return existing
	var inventory := InventoryController.new()
	inventory.name = "InventoryController"
	inventory.capacity = capacity
	controllers.add_child(inventory)
	return inventory


static func add_health_component(entity: Node, current_hp: float = 100.0) -> HealthComponent:
	var components := ensure_child(entity, "Components")
	var existing := components.get_node_or_null("HealthComponent") as HealthComponent
	if existing != null:
		existing.current_hp = current_hp
		return existing
	var health := HealthComponent.new()
	health.name = "HealthComponent"
	health.current_hp = current_hp
	components.add_child(health)
	return health


static func add_stats_component(entity: Node, base_stats: Dictionary = {}) -> StatsComponent:
	var components := ensure_child(entity, "Components")
	var existing := components.get_node_or_null("StatsComponent") as StatsComponent
	if existing != null:
		existing.base_stats = base_stats.duplicate(true)
		return existing
	var stats := StatsComponent.new()
	stats.name = "StatsComponent"
	if not base_stats.is_empty():
		stats.base_stats = base_stats.duplicate(true)
	components.add_child(stats)
	return stats


static func add_resource_pool_component(
	entity: Node,
	starting_values: Dictionary = {}
) -> ResourcePoolComponent:
	var components := ensure_child(entity, "Components")
	var existing := components.get_node_or_null("ResourcePoolComponent") as ResourcePoolComponent
	if existing != null:
		existing.starting_values = starting_values.duplicate(true)
		return existing
	var pool := ResourcePoolComponent.new()
	pool.name = "ResourcePoolComponent"
	pool.starting_values = starting_values.duplicate(true)
	components.add_child(pool)
	return pool


static func add_ability_controller(
	entity: Node,
	starting_ability_ids: Array[String] = []
) -> AbilityController:
	var controllers := ensure_child(entity, "Controllers")
	var existing := controllers.get_node_or_null("AbilityController") as AbilityController
	if existing != null:
		var copied_existing_ids: Array[String] = []
		copied_existing_ids.append_array(starting_ability_ids)
		existing.starting_ability_ids = copied_existing_ids
		return existing
	var controller := AbilityController.new()
	controller.name = "AbilityController"
	var copied_ids: Array[String] = []
	copied_ids.append_array(starting_ability_ids)
	controller.starting_ability_ids = copied_ids
	controllers.add_child(controller)
	return controller


static func add_status_effect_controller(entity: Node) -> StatusEffectController:
	var controllers := ensure_child(entity, "Controllers")
	var existing := controllers.get_node_or_null("StatusEffectController") as StatusEffectController
	if existing != null:
		return existing
	var controller := StatusEffectController.new()
	controller.name = "StatusEffectController"
	controllers.add_child(controller)
	return controller


static func add_equipment_controller(entity: Node) -> EquipmentController:
	var controllers := ensure_child(entity, "Controllers")
	var existing := controllers.get_node_or_null("EquipmentController") as EquipmentController
	if existing != null:
		return existing
	var controller := EquipmentController.new()
	controller.name = "EquipmentController"
	controllers.add_child(controller)
	return controller


static func add_animation_player(entity: Node) -> AnimationPlayer:
	var presentation := ensure_child(entity, "Presentation")
	var existing := presentation.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if existing != null:
		add_animation(existing, "cast")
		return existing
	var animation_player := AnimationPlayer.new()
	animation_player.name = "AnimationPlayer"
	presentation.add_child(animation_player)
	add_animation(animation_player, "cast")
	return animation_player


static func add_animation(animation_player: AnimationPlayer, animation_name: String) -> void:
	if animation_player.has_animation(animation_name):
		return
	var library: AnimationLibrary = null
	if animation_player.has_animation_library(""):
		library = animation_player.get_animation_library("")
	else:
		library = AnimationLibrary.new()
		animation_player.add_animation_library("", library)
	var animation := Animation.new()
	animation.length = 0.01
	library.add_animation(animation_name, animation)


static func add_hitbox_component(
	entity: Node,
	layer: int = 1,
	mask: int = 1,
	radius: float = 8.0
) -> HitboxComponent:
	var components := ensure_child(entity, "Components")
	var existing := components.get_node_or_null("HitboxComponent") as HitboxComponent
	if existing != null:
		return existing
	var hitbox := HitboxComponent.new()
	hitbox.name = "HitboxComponent"
	hitbox.collision_layer = layer
	hitbox.collision_mask = mask
	components.add_child(hitbox)
	add_circle_collision_shape(hitbox, radius)
	return hitbox


static func add_hurtbox_component(
	entity: Node,
	layer: int = 1,
	mask: int = 1,
	radius: float = 8.0
) -> HurtboxComponent:
	var components := ensure_child(entity, "Components")
	var existing := components.get_node_or_null("HurtboxComponent") as HurtboxComponent
	if existing != null:
		return existing
	var hurtbox := HurtboxComponent.new()
	hurtbox.name = "HurtboxComponent"
	hurtbox.collision_layer = layer
	hurtbox.collision_mask = mask
	components.add_child(hurtbox)
	add_circle_collision_shape(hurtbox, radius)
	return hurtbox


static func add_circle_collision_shape(area: Area2D, radius: float = 8.0) -> CollisionShape2D:
	var existing := area.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if existing != null:
		return existing
	var shape := CircleShape2D.new()
	shape.radius = radius
	var collision := CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	collision.shape = shape
	area.add_child(collision)
	return collision


static func assign_owner(node: Node, owner_node: Node) -> void:
	for child in node.get_children():
		child.owner = owner_node
		assign_owner(child, owner_node)
