class_name CombatService
extends RefCounted
## 说明：`CombatService` 是 战斗系统 的运行时服务，负责集中处理该领域的跨节点规则和查询。
## 上游：通常由 GameBootstrap、ModuleBootstrap、Mkit 门面或其他领域服务创建或调用。
## 下游：会连接 ContentService、EventService、组件、定义资源或场景节点，不直接依赖具体游戏内容。
## 使用：当项目需要从多个节点共享同一套领域规则或查询入口时使用它。
## 示例：`ServiceRegistry.register_service(CombatService.SERVICE_ID, CombatService.new())`

## 服务注册 id，供 GameBootstrap、ModuleBootstrap、ServiceRegistry 和 Mkit 查找 `CombatService`。
const SERVICE_ID: String = "combat"


## 解析一次 DamageRequest：读取 source/target StatsComponent，应用 attack_power、damage_multiplier、crit、defense 和 on-hit status rolls。
## request、source 或 target 缺失时返回带 failure trace 的 DamageResult；本方法只计算结果，不直接扣血。
func resolve(request: DamageRequest) -> DamageResult:
	var result := DamageResult.new()
	if request == null or request.source == null or request.target == null:
		result.trace["failure"] = "missing source or target"
		return result

	result.source = request.source
	result.target = request.target
	result.base_amount = request.base_amount
	result.damage_type = request.damage_type
	result.element_type = request.element_type
	result.trace["base"] = request.base_amount
	result.trace["damage_source_node"] = _safe_node_name(request.source)
	result.trace["damage_target_node"] = _safe_node_name(request.target)

	if request.can_evade and _roll_chance(_stat(_get_stats(request.target), "evade_chance", 0.0)):
		result.was_evaded = true
		result.final_amount = 0.0
		result.trace["evaded"] = true
		return result

	var source_stats := _get_stats(request.source)
	var target_stats := _get_stats(request.target)
	var attack_power := _stat(source_stats, "attack_power", 0.0)
	var damage_multiplier := _stat(source_stats, "damage_multiplier", 1.0)
	var defense := _stat(target_stats, "defense", 0.0)
	var crit_chance := _stat(source_stats, "crit_chance", 0.0)
	var crit_damage := _stat(source_stats, "crit_damage", 1.5)

	var amount := request.base_amount
	amount += attack_power
	result.trace["after_attack_power"] = amount
	amount *= damage_multiplier
	result.trace["after_damage_multiplier"] = amount

	if request.can_crit and _roll_chance(crit_chance):
		result.was_critical = true
		amount *= crit_damage
		result.trace["crit_roll"] = true

	result.trace["after_crit"] = amount
	amount = max(0.0, amount - defense)
	result.trace["after_defense"] = amount
	result.final_amount = max(0.0, amount)
	result.trace["final"] = result.final_amount

	_resolve_status_applications(request, result)
	return result


func _resolve_status_applications(request: DamageRequest, result: DamageResult) -> void:
	if result.was_evaded or result.was_blocked:
		return
	for entry in request.on_hit_statuses:
		var status_id := str(entry.get("status_id", ""))
		if status_id == "":
			continue
		var chance := float(entry.get("chance", 1.0))
		if not _roll_chance(chance):
			continue
		result.applied_status_effects.append(status_id)
		result.status_applications.append({
			"status_id": status_id,
			"stacks": max(1, int(entry.get("stacks", 1))),
			"duration": float(entry.get("duration", -1.0)),
		})
		result.trace["applied_status_effects"] = result.applied_status_effects.duplicate()


func _get_stats(entity: Node) -> StatsComponent:
	if entity == null:
		return null
	return EntityContract.get_component(entity, "StatsComponent") as StatsComponent


func _stat(stats: StatsComponent, stat_id: String, default_value: float) -> float:
	if stats == null:
		return default_value
	return stats.get_stat_value(stat_id, default_value)


func _roll_chance(chance: float) -> bool:
	var random: RandomService = null
	random = Mkit.random()
	if random != null:
		return random.randf() < chance
	return randf() < chance


func _safe_node_name(node: Node) -> String:
	return node.name if node != null else "null"
