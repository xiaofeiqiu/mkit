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
## QuestService 持有的任务日志状态。
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


## 检查 quest definition、现有状态、前置任务和 accept_conditions；不会修改 QuestLog。
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


## 接受可用任务：创建或重置 QuestState、初始化 objective 进度、保存 context，并发 `quest_accepted` signal/event。
## can_accept 返回 false 时保持 QuestLog 不变并返回 false。
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


## 处理 EventService 派发的 DomainEvent；inventory_changed 会桥接物品目标，其他事件按 objective match 推进 active quest。
## auto_complete 任务在目标满足后会立即调用 complete_quest。
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


## 手动推进指定 objective 进度；只处理 active quest，进度达到需求时发 `objective_advanced` 并可能 auto complete。
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


## 检查所有非 optional objective 是否达到 required_count；缺 state 或 definition 时返回 false。
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


## 把 active 且目标满足的 quest 标记为 completed，并发 `quest_completed` signal/event。
## auto_complete 的 definition 会继续调用 turn_in_quest 结算奖励。
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


## 结算 completed quest 的 reward_effects；全部成功后标记 turned_in 并发 `quest_turned_in` signal/event。
## repeatable quest 会回到 available 并清空 objective_progress。
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


## 从 ContentService 读取 QuestDefinition；服务未注册或 quest id 缺失时返回 null。
func get_definition(quest_id: String) -> QuestDefinition:
	var content := _get_content()
	if content == null:
		return null
	return content.get_resource(quest_id) as QuestDefinition


## 从 QuestLog 读取指定 quest 的运行时状态；尚未接触该任务时返回 null。
func get_state(quest_id: String) -> QuestState:
	return log.get_state(quest_id)


## 导出 QuestLog 状态，供 SaveService 写入 `quest` root save id。
func to_save_data() -> Dictionary:
	return log.to_save_data()


## 从存档 payload 恢复 QuestLog；未知字段由 QuestLog 自身忽略。
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
