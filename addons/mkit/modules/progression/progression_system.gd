class_name ProgressionSystem
extends Saveable

signal currency_changed(currency_id: String, amount: int)
signal upgrade_level_changed(upgrade_id: String, level: int)
signal content_unlocked(content_id: String)

var state := ProgressionState.new()
var content: ContentRegistry = null


func _ready() -> void:
	if save_id == "":
		save_id = "progression"
	if ServiceRegistry.has_service("content"):
		content = ServiceRegistry.get_service("content") as ContentRegistry


func add_currency(currency_id: String, amount: int) -> void:
	state.add_currency(currency_id, amount)
	currency_changed.emit(currency_id, state.get_currency(currency_id))


func get_currency(currency_id: String) -> int:
	return state.get_currency(currency_id)


func can_unlock(upgrade_id: String) -> bool:
	var definition := get_definition(upgrade_id)
	if definition == null:
		return false
	var current_level := state.get_upgrade_level(upgrade_id)
	if current_level >= definition.max_level:
		return false
	for prerequisite in definition.prerequisite_upgrade_ids:
		if state.get_upgrade_level(prerequisite) <= 0:
			return false
	var next_level := current_level + 1
	return state.get_currency(definition.currency_id) >= definition.get_cost_for_level(next_level)


func unlock_or_level_up(upgrade_id: String, context: GameplayContext = null) -> bool:
	if not can_unlock(upgrade_id):
		return false
	var definition := get_definition(upgrade_id)
	var next_level := state.get_upgrade_level(upgrade_id) + 1
	var cost := definition.get_cost_for_level(next_level)
	if not state.spend_currency(definition.currency_id, cost):
		return false

	state.set_upgrade_level(upgrade_id, next_level)
	for content_id in definition.unlock_content_ids:
		state.unlock_content(content_id)
		content_unlocked.emit(content_id)

	_apply_upgrade_effects(definition, context)
	currency_changed.emit(definition.currency_id, state.get_currency(definition.currency_id))
	upgrade_level_changed.emit(upgrade_id, next_level)
	return true


func get_definition(upgrade_id: String) -> UpgradeDefinition:
	if content == null:
		content = ServiceRegistry.get_service("content") as ContentRegistry
	if content == null:
		return null
	return content.get_resource(upgrade_id) as UpgradeDefinition


func _apply_upgrade_effects(definition: UpgradeDefinition, context: GameplayContext) -> void:
	if definition.effects.is_empty():
		return
	var executor := ServiceRegistry.get_service("effects") as EffectExecutor
	if executor == null:
		return
	var ctx := context if context != null else GameplayContext.new()
	executor.execute_many(definition.effects, ctx)


func to_save_data() -> Dictionary:
	return state.to_save_data()


func from_save_data(data: Dictionary) -> void:
	state.from_save_data(data)
