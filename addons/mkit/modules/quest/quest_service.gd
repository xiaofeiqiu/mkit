class_name QuestService
extends Saveable
## 说明：`QuestService` 是 任务系统 的运行时服务，负责集中处理该领域的跨节点规则和查询。
## 上游：通常由 GameBootstrap、ModuleBootstrap、Mkit 门面或其他领域服务创建或调用。
## 下游：会连接 ContentService、EventService、组件、定义资源或场景节点，不直接依赖具体游戏内容。
## 使用：当项目需要从多个节点共享同一套领域规则或查询入口时使用它。
## 示例：`ServiceRegistry.register_service(QuestService.SERVICE_ID, QuestService.new())`

## 当 `QuestService` 发生 `quest offered` 事件时发出，供 UI、音频、VFX、任务或测试订阅。
signal quest_offered(quest_id: String)
## 当 `QuestService` 发生 `quest accepted` 事件时发出，供 UI、音频、VFX、任务或测试订阅。
signal quest_accepted(quest_id: String)
## 当 `QuestService` 发生 `objective advanced` 事件时发出，供 UI、音频、VFX、任务或测试订阅。
signal objective_advanced(quest_id: String, objective_id: String, current: int, required: int)
## 当 `QuestService` 发生 `quest completed` 事件时发出，供 UI、音频、VFX、任务或测试订阅。
signal quest_completed(quest_id: String)
## 当 `QuestService` 发生 `quest turned in` 事件时发出，供 UI、音频、VFX、任务或测试订阅。
signal quest_turned_in(quest_id: String)
## 服务注册 id，供 GameBootstrap、ModuleBootstrap、ServiceRegistry 和 Mkit 查找 `QuestService`。
const SERVICE_ID: String = "quest"
## 运行时状态：`log` 表示 `QuestService` 的字段值，由 `QuestService` 的公开 API 读取或维护。
var log: QuestLog = QuestLog.new()
var _quest_contexts: Dictionary = {}
var _content: ContentService = null
var _events: EventService = null
var _effects: EffectService = null


func _ready() -> void:
	if save_id == "":
		save_id = "quest"
	_on_services_ready()


func _on_services_ready() -> void:
	_content = Mkit.content()
	_events = Mkit.events()
	_effects = Mkit.effects()
	_connect_events()


func _connect_events() -> void:
	var events := _get_events()
	if events == null:
		return
	events.subscribe(EventService.ANY_EVENT, notify_event)
	events.subscribe(CombatEvents.ENTITY_DIED, _on_entity_died)


## 检查当前上下文是否允许 `accept`，并保持 `QuestService` 的领域契约一致。
func can_accept(quest_id: String, context: GameplayContext) -> bool:
	var definition := get_definition(quest_id)
	if definition == null:
		return false
	var existing := log.get_state(quest_id)
	if existing != null:
		if existing.status == QuestState.STATUS_ACTIVE or existing.status == QuestState.STATUS_COMPLETED:
			return false
		if existing.status == QuestState.STATUS_TURNED_IN and not definition.repeatable:
			return false
	for prerequisite_id in definition.prerequisite_quest_ids:
		var prerequisite := log.get_state(prerequisite_id)
		if prerequisite == null or prerequisite.status != QuestState.STATUS_TURNED_IN:
			return false
	var ctx := GameplayContext.from_context(context)
	if not ConditionEvaluator.evaluate_all(definition.accept_conditions, ctx):
		return false
	return true


## 执行 `accept_quest` 对应的公开操作，并保持 `QuestService` 的领域契约一致。
func accept_quest(quest_id: String, context: GameplayContext) -> bool:
	if not can_accept(quest_id, context):
		return false
	var definition := get_definition(quest_id)
	var state := log.get_state(quest_id)
	if state == null:
		state = QuestState.create(quest_id)
		log.states[quest_id] = state
	state.status = QuestState.STATUS_ACTIVE
	state.objective_progress = {}
	for objective in definition.objectives:
		state.set_progress(objective.objective_id, 0)
	if context != null:
		_quest_contexts[quest_id] = context
	quest_accepted.emit(quest_id)
	var events := _get_events()
	if events != null:
		events.emit_domain_event(QuestEvents.quest_accepted(quest_id))
	return true


## 执行 `notify_event` 对应的公开操作，并保持 `QuestService` 的领域契约一致。
func notify_event(event: DomainEvent) -> void:
	if event == null:
		return
	if event.event_type == "inventory_changed":
		_notify_item_acquired(event)
	for state in log.get_active():
		var definition := get_definition(state.quest_id)
		if definition == null:
			continue
		var changed := false
		for objective in definition.objectives:
			if not _objective_matches(objective, event):
				continue
			var amount := 1
			if objective.count_payload_key != "":
				amount = int(event.payload.get(objective.count_payload_key, 1))
			if amount <= 0:
				continue
			if _advance_progress(state, objective, amount):
				changed = true
		if changed and definition.auto_complete and is_quest_complete(state.quest_id):
			complete_quest(state.quest_id, _quest_contexts.get(state.quest_id, null))


## 推进对应目标或流程进度，并保持 `QuestService` 的领域契约一致。
func advance_objective(quest_id: String, objective_id: String, amount: int = 1) -> bool:
	if amount <= 0:
		return false
	var state := log.get_state(quest_id)
	if state == null or state.status != QuestState.STATUS_ACTIVE:
		return false
	var definition := get_definition(quest_id)
	if definition == null:
		return false
	var objective := definition.get_objective(objective_id)
	if objective == null:
		return false
	if _advance_progress(state, objective, amount):
		if definition.auto_complete and is_quest_complete(quest_id):
			return complete_quest(quest_id, _quest_contexts.get(quest_id, null))
		return true
	return false


## 判断 `quest_complete` 当前是否成立，并保持 `QuestService` 的领域契约一致。
func is_quest_complete(quest_id: String) -> bool:
	var state := log.get_state(quest_id)
	var definition := get_definition(quest_id)
	if state == null or definition == null:
		return false
	for objective in definition.objectives:
		if objective.optional:
			continue
		if state.get_progress(objective.objective_id) < objective.required_count:
			return false
	return true


## 完成 `quest` 流程，并保持 `QuestService` 的领域契约一致。
func complete_quest(quest_id: String, context: GameplayContext) -> bool:
	var state := log.get_state(quest_id)
	if state == null or state.status != QuestState.STATUS_ACTIVE:
		return false
	if not is_quest_complete(quest_id):
		return false
	state.status = QuestState.STATUS_COMPLETED
	quest_completed.emit(quest_id)
	var events := _get_events()
	if events != null:
		events.emit_domain_event(QuestEvents.quest_completed(quest_id))
	var definition := get_definition(quest_id)
	if definition != null and definition.auto_complete:
		return turn_in_quest(quest_id, context)
	return true


## 执行 `turn_in_quest` 对应的公开操作，并保持 `QuestService` 的领域契约一致。
func turn_in_quest(quest_id: String, context: GameplayContext) -> bool:
	var state := log.get_state(quest_id)
	if state == null or state.status != QuestState.STATUS_COMPLETED:
		return false
	var definition := get_definition(quest_id)
	var source_ctx := context
	if source_ctx == null:
		source_ctx = _quest_contexts.get(quest_id, null)
	var ctx := GameplayContext.from_context(source_ctx)
	if not _run_reward_effects(definition, ctx):
		return false
	state.status = QuestState.STATUS_TURNED_IN
	if definition != null and definition.repeatable:
		state.status = QuestState.STATUS_AVAILABLE
		state.objective_progress = {}
	quest_turned_in.emit(quest_id)
	var events := _get_events()
	if events != null:
		events.emit_domain_event(QuestEvents.quest_turned_in(quest_id))
	return true


## 返回 `definition` 对应的数据或对象，并保持 `QuestService` 的领域契约一致。
func get_definition(quest_id: String) -> QuestDefinition:
	var content := _get_content()
	if content == null:
		return null
	return content.get_resource(quest_id) as QuestDefinition


## 返回 `state` 对应的数据或对象，并保持 `QuestService` 的领域契约一致。
func get_state(quest_id: String) -> QuestState:
	return log.get_state(quest_id)


## 导出当前运行时状态，供 SaveService 写入存档，并保持 `QuestService` 的领域契约一致。
func to_save_data() -> Dictionary:
	return log.to_save_data()


## 从 SaveService 读出的 payload 恢复运行时状态，并保持 `QuestService` 的领域契约一致。
func from_save_data(data: Dictionary) -> void:
	log.from_save_data(data)


func _advance_progress(state: QuestState, objective: QuestObjectiveDefinition, amount: int) -> bool:
	var current := state.get_progress(objective.objective_id)
	if current >= objective.required_count:
		return false
	var updated: int = min(current + amount, objective.required_count)
	state.set_progress(objective.objective_id, updated)
	objective_advanced.emit(
		state.quest_id, objective.objective_id, updated, objective.required_count
	)
	var events := _get_events()
	if events != null:
		events.emit_domain_event(
			QuestEvents.quest_objective_advanced(
				state.quest_id, objective.objective_id, updated, objective.required_count
			)
		)
	return true


func _objective_matches(objective: QuestObjectiveDefinition, event: DomainEvent) -> bool:
	if objective.event_type != event.event_type:
		return false
	if objective.match_key == "":
		return true
	var actual = event.payload.get(objective.match_key, null)
	if actual == null:
		return false
	if actual is Array:
		return actual.has(objective.match_value)
	return str(actual) == objective.match_value


func _on_entity_died(event: DomainEvent) -> void:
	if event == null:
		return
	var entity_id := str(event.payload.get("entity_id", event.source_id))
	var payload := {"entity_id": entity_id}
	for key in ["tags", "faction", "definition_id"]:
		if event.payload.has(key):
			payload[key] = event.payload[key]
	var events := _get_events()
	if events != null:
		events.emit_domain_event(DomainEvent.create(QuestEvents.ENEMY_KILLED, entity_id, "", payload))


func _notify_item_acquired(event: DomainEvent) -> void:
	if str(event.payload.get("change_type", "")) != "added":
		return
	var item_id := str(event.payload.get("item_id", ""))
	if item_id == "":
		return
	var amount := int(event.payload.get("quantity", 1))
	if amount <= 0:
		return
	var payload := event.payload.duplicate(true)
	payload["amount"] = amount
	notify_event(DomainEvent.create("item_acquired", event.source_id, event.target_id, payload))


func _run_reward_effects(definition: QuestDefinition, context: GameplayContext) -> bool:
	if definition == null:
		return false
	if definition.reward_effects.is_empty():
		return true
	var executor := _get_effects()
	if executor == null:
		return false
	var results := executor.execute_many(definition.reward_effects, context, true)
	for result in results:
		if not result.success:
			return false
	return true


func _get_content() -> ContentService:
	if _content == null:
		_content = Mkit.content()
	return _content


func _get_events() -> EventService:
	if _events == null:
		_events = Mkit.events()
	return _events


func _get_effects() -> EffectService:
	if _effects == null:
		_effects = Mkit.effects()
	return _effects
