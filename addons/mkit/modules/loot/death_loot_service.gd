class_name DeathLootService
extends Node
## 说明：`DeathLootService` 是 掉落与奖励系统 的运行时服务，负责把死亡事件桥接为掉落事件。
## 上游：通常由 ModuleBootstrap 注册，并监听 CombatEvents.ENTITY_DIED。
## 下游：会调用 LootService roll 掉落表，并通过 EventService 发布 LootEvents.LOOT_DROPPED。
## 使用：把 DeathLootRuleDefinition 加入 ResourceDatabase 后，本服务会按数据规则自动处理死亡掉落。
## 示例：`ServiceRegistry.register_service(DeathLootService.SERVICE_ID, DeathLootService.new())`

## 服务注册 id，供 ModuleBootstrap、ServiceRegistry 和 Mkit 查找 `DeathLootService`。
const SERVICE_ID: String = "death_loot"
## 最近产生的死亡掉落结果；用于调试和测试。
var recent_drops: Array[LootDropResult] = []
## 最近掉落结果保留数量上限。
var max_recent_drops: int = 100


func _ready() -> void:
	_connect_events()


func _on_services_ready() -> void:
	_connect_events()


func _exit_tree() -> void:
	var events := _get_events()
	if events != null:
		events.unsubscribe(CombatEvents.ENTITY_DIED, _on_entity_died)


## 处理死亡事件并返回本次生成的掉落结果，便于测试和自定义调用。
func process_death_event(event: DomainEvent) -> Array[LootDropResult]:
	var drops: Array[LootDropResult] = []
	if event == null:
		return drops
	var content := _get_content()
	var loot := _get_loot()
	if content == null or loot == null:
		return drops
	var rules := _get_sorted_rules(content)
	if rules.is_empty():
		return drops
	for rule in rules:
		var ctx := _build_context(event, rule)
		if not rule.matches_death_event(event, ctx):
			continue
		for table_id in rule.loot_table_ids:
			var id := table_id.strip_edges()
			if id == "":
				continue
			ctx.payload["loot_table_id"] = id
			var drop := _roll_drop(rule, id, event, ctx, loot)
			if drop.has_content():
				drops.append(drop)
				_record_drop(drop)
				_emit_drop(drop)
		if rule.stop_after_match:
			break
	return drops


func _connect_events() -> void:
	var events := _get_events()
	if events == null:
		return
	if not events.is_subscribed(CombatEvents.ENTITY_DIED, _on_entity_died):
		events.subscribe(CombatEvents.ENTITY_DIED, _on_entity_died)


func _on_entity_died(event: DomainEvent) -> void:
	process_death_event(event)


func _get_sorted_rules(content: ContentService) -> Array[DeathLootRuleDefinition]:
	var rules: Array[DeathLootRuleDefinition] = []
	for raw in content.get_all_by_type("DeathLootRuleDefinition"):
		var rule := raw as DeathLootRuleDefinition
		if rule != null:
			rules.append(rule)
	rules.sort_custom(func(a: DeathLootRuleDefinition, b: DeathLootRuleDefinition) -> bool:
		return a.priority > b.priority
	)
	return rules


func _build_context(event: DomainEvent, rule: DeathLootRuleDefinition) -> GameplayContext:
	var ctx := GameplayContext.new()
	var entity_ref := event.payload.get("entity_ref") as Node
	var killer_ref := event.payload.get("killer_ref") as Node
	ctx.source = killer_ref if killer_ref != null else entity_ref
	ctx.target = entity_ref
	ctx.instigator = killer_ref
	ctx.tags = event.payload.get("tags", [])
	ctx.payload = event.payload.duplicate(true)
	ctx.payload["death_entity_id"] = str(event.payload.get("entity_id", event.source_id))
	ctx.payload["death_definition_id"] = str(event.payload.get("definition_id", ""))
	ctx.payload["killer_id"] = str(event.payload.get("killer_id", ""))
	ctx.payload["rule_id"] = rule.rule_id if rule != null else ""
	return ctx


func _roll_drop(
	rule: DeathLootRuleDefinition,
	table_id: String,
	event: DomainEvent,
	context: GameplayContext,
	loot: LootService
) -> LootDropResult:
	var drop := LootDropResult.new()
	drop.rule_id = rule.rule_id if rule != null else ""
	drop.loot_table_id = table_id
	drop.entity_id = str(event.payload.get("entity_id", event.source_id))
	drop.entity_definition_id = str(event.payload.get("definition_id", ""))
	drop.entity_ref = event.payload.get("entity_ref") as Node
	drop.killer_id = str(event.payload.get("killer_id", ""))
	drop.killer_ref = event.payload.get("killer_ref") as Node
	drop.roll_result = loot.roll_table(table_id, context)
	return drop


func _record_drop(drop: LootDropResult) -> void:
	recent_drops.append(drop)
	if recent_drops.size() > max_recent_drops:
		recent_drops.pop_front()


func _emit_drop(drop: LootDropResult) -> void:
	var events := _get_events()
	if events != null:
		events.emit_domain_event(LootEvents.loot_dropped(drop))


func _get_events() -> EventService:
	if not ServiceRegistry.has_service(EventService.SERVICE_ID):
		return null
	return ServiceRegistry.get_port(EventService.SERVICE_ID) as EventService


func _get_content() -> ContentService:
	if not ServiceRegistry.has_service(ContentService.SERVICE_ID):
		return null
	return ServiceRegistry.get_port(ContentService.SERVICE_ID) as ContentService


func _get_loot() -> LootService:
	if not ServiceRegistry.has_service(LootService.SERVICE_ID):
		return null
	return ServiceRegistry.get_port(LootService.SERVICE_ID) as LootService
