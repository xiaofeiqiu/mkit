class_name RewardSystem
extends RefCounted


func generate_options(
	pool_ids: Array[String], count: int, context: GameplayContext
) -> Array[RewardOption]:
	if count <= 0 or pool_ids.is_empty():
		return []
	if ServiceRegistry.get_port(ServiceRegistry.SERVICE_CONTENT) == null:
		push_warning("RewardSystem.generate_options: missing ContentService service")
		return []
	var content := ServiceRegistry.get_port(ServiceRegistry.SERVICE_CONTENT) as ContentService
	if content == null:
		push_warning("RewardSystem.generate_options: ContentService service is invalid")
		return []
	var ctx := GameplayContext.from_context(context)
	var candidates: Array[RewardDefinition] = []
	for id in pool_ids:
		if id.strip_edges() == "":
			continue
		var def := content.get_resource(id) as RewardDefinition
		if def != null and ConditionEvaluator.evaluate_all(def.conditions, ctx):
			candidates.append(def)
	var result: Array[RewardOption] = []
	while result.size() < count and candidates.size() > 0:
		var selected := _weighted_pick(candidates)
		if selected == null:
			break
		candidates.erase(selected)
		result.append(_build_option(selected))
	return result


func apply_selected(option: RewardOption, context: GameplayContext) -> bool:
	if option == null:
		return false
	var ctx := GameplayContext.from_context(context)
	var executor: EffectService = null
	executor = ServiceRegistry.get_port(ServiceRegistry.SERVICE_EFFECTS) as EffectService
	if executor == null:
		executor = EffectService.new()
	var results := executor.execute_many(option.effects, ctx, true)
	for r in results:
		if not r.success:
			return false
	var events: EventService = null
	events = ServiceRegistry.get_port(ServiceRegistry.SERVICE_EVENTS) as EventService
	if events != null:
		events.emit_reward_selected(option.reward_id, ctx.source.name if ctx.source != null else "")
	return true


func _weighted_pick(candidates: Array[RewardDefinition]) -> RewardDefinition:
	if candidates.is_empty():
		return null
	var total := 0.0
	for c in candidates:
		if c != null:
			total += max(0.0, c.weight)
	if total <= 0.0:
		return candidates[0]
	var random: RandomService = ServiceRegistry.get_port(ServiceRegistry.SERVICE_RANDOM) as RandomService
	var r := random.randf_range(0.0, total) if random != null else randf_range(0.0, total)
	var cursor := 0.0
	for c in candidates:
		if c == null:
			continue
		cursor += max(0.0, c.weight)
		if r <= cursor:
			return c
	return candidates[0]


func _build_option(def: RewardDefinition) -> RewardOption:
	var option := RewardOption.new()
	if def == null:
		return option
	option.reward_id = def.reward_id
	option.display_name = def.display_name
	option.description = def.description
	option.icon = def.icon
	option.rarity = def.rarity
	option.effects = def.effects.duplicate()
	return option
