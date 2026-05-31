class_name RewardSystem
extends RefCounted


func generate_options(pool_ids: Array[String], count: int, context: GameplayContext) -> Array[RewardOption]:
	var content := ServiceRegistry.get_service("content") as ContentRegistry
	var candidates: Array[RewardDefinition] = []

	for id in pool_ids:
		var def := content.get_resource(id) as RewardDefinition
		if def != null and ConditionEvaluator.evaluate_all(def.conditions, context):
			candidates.append(def)

	var result: Array[RewardOption] = []
	while result.size() < count and candidates.size() > 0:
		var selected := _weighted_pick(candidates)
		candidates.erase(selected)
		result.append(_build_option(selected))

	return result


func apply_selected(option: RewardOption, context: GameplayContext) -> bool:
	if option == null:
		return false
	var executor := ServiceRegistry.get_service("effects") as EffectExecutor
	var results := executor.execute_many(option.effects, context, true)
	for r in results:
		if not r.success:
			return false

	var events := ServiceRegistry.get_service("events") as EventRouter
	if events != null:
		events.emit_reward_selected(option.reward_id, context.source.name if context.source != null else "")
	return true


func _weighted_pick(candidates: Array[RewardDefinition]) -> RewardDefinition:
	var total := 0.0
	for c in candidates:
		total += c.weight
	var random := ServiceRegistry.get_service("random") as RandomService
	var r := random.randf_range(0.0, total) if random != null else randf_range(0.0, total)
	var cursor := 0.0
	for c in candidates:
		cursor += c.weight
		if r <= cursor:
			return c
	return candidates[0]


func _build_option(def: RewardDefinition) -> RewardOption:
	var option := RewardOption.new()
	option.reward_id = def.reward_id
	option.display_name = def.display_name
	option.description = def.description
	option.icon = def.icon
	option.rarity = def.rarity
	option.effects = def.effects.duplicate()
	return option
