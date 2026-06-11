class_name RewardSystem
extends RefCounted
## 说明：`RewardSystem` 是 掉落与奖励系统 的系统对象，负责封装该领域可复用的算法或规则。
## 上游：通常由同领域服务、controller、组件或内容资源创建或调用。
## 下游：会连接 mkit 的服务、组件、资源或事件管线，不直接依赖具体游戏内容。
## 使用：当项目需要在掉落与奖励系统中复用这段契约或状态时使用它。
## 示例：`var instance := RewardSystem.new()`



## 根据配置生成运行时结果，并保持 `RewardSystem` 的领域契约一致。
func generate_options(
	pool_ids: Array[String], count: int, context: GameplayContext
) -> Array[RewardOption]:
	if count <= 0 or pool_ids.is_empty():
		return []
	var content := Mkit.content()
	if content == null:
		push_warning("RewardSystem.generate_options: missing ContentService service")
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


## 把输入数据或效果应用到目标对象，并保持 `RewardSystem` 的领域契约一致。
func apply_selected(option: RewardOption, context: GameplayContext) -> bool:
	if option == null:
		return false
	var ctx := GameplayContext.from_context(context)
	var executor: EffectService = null
	executor = Mkit.effects()
	if executor == null:
		executor = EffectService.new()
	var results := executor.execute_many(option.effects, ctx, true)
	for r in results:
		if not r.success:
			return false
	var events := Mkit.events()
	if events != null:
		events.emit_domain_event(
			LootEvents.reward_selected(
				option.reward_id, ctx.source.name if ctx.source != null else ""
			)
		)
	return true


func _weighted_pick(candidates: Array[RewardDefinition]) -> RewardDefinition:
	if candidates.is_empty():
		return null
	var random: RandomService = Mkit.random()
	if random == null:
		return candidates[0]
	var picked := random.weighted_pick(candidates) as RewardDefinition
	return picked if picked != null else candidates[0]


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
