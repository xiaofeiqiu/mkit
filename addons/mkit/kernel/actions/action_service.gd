class_name ActionService
extends Node
## 说明：`ActionService` 是 动作管线 的运行时服务，负责集中处理该领域的跨节点规则和查询。
## 上游：通常由 GameBootstrap、ModuleBootstrap、Mkit 门面或其他领域服务创建或调用。
## 下游：会连接 ContentService、EventService、组件、定义资源或场景节点，不直接依赖具体游戏内容。
## 使用：当项目需要从多个节点共享同一套领域规则或查询入口时使用它。
## 示例：`ServiceRegistry.register_service(ActionService.SERVICE_ID, ActionService.new())`

## 当 `ActionService` 发生 `action started` 事件时发出，供 UI、音频、VFX、任务或测试订阅。
signal action_started(action: GameAction)
## 当 `ActionService` 发生 `action completed` 事件时发出，供 UI、音频、VFX、任务或测试订阅。
signal action_completed(action: GameAction)
## 当 `ActionService` 发生 `action cancelled` 事件时发出，供 UI、音频、VFX、任务或测试订阅。
signal action_cancelled(action: GameAction, reason: String)
## 服务注册 id，供 GameBootstrap、ModuleBootstrap、ServiceRegistry 和 Mkit 查找 `ActionService`。
const SERVICE_ID: String = "actions"
## 运行时状态：`active_actions` 表示是否启用或当前激活状态，由 `ActionService` 的公开 API 读取或维护。
var active_actions: Array[GameAction] = []
var _time: TimeService = null
var _effects: EffectService = null


func _on_services_ready() -> void:
	_resolve_time_service()
	_resolve_effect_service()


## 启动 `action` 流程，并保持 `ActionService` 的领域契约一致。
func start_action(action: GameAction, context: ActionContext) -> GameAction:
	if action == null:
		push_warning("ActionService.start_action: action is null")
		return null
	if context == null:
		push_warning("ActionService.start_action: context is null")
		return null
	_resolve_effect_service()
	action._effect_service = _effects
	active_actions.append(action)
	if not action.cancelled.is_connected(_on_action_cancelled):
		action.cancelled.connect(_on_action_cancelled)
	action.start(context)
	action_started.emit(action)
	return action


func _process(delta: float) -> void:
	_resolve_time_service()
	var scaled_delta := _time.get_scaled_delta(delta) if _time != null else delta
	for action in active_actions.duplicate():
		if action == null:
			active_actions.erase(action)
			continue
		action.update(scaled_delta)
		if action.is_finished():
			active_actions.erase(action)
			if not action.cancelled_flag:
				action_completed.emit(action)


## 取消当前或匹配条件的运行时流程，并保持 `ActionService` 的领域契约一致。
func cancel_actions_for_source(source: Node, reason: String = "") -> void:
	if source == null:
		push_warning("ActionService.cancel_actions_for_source: source is null")
		return
	for action in active_actions.duplicate():
		if action.context != null and action.context.source == source:
			action.cancel(reason)


func _on_action_cancelled(action: GameAction, reason: String) -> void:
	action_cancelled.emit(action, reason)


func _resolve_time_service() -> void:
	if _time == null and ServiceRegistry.has_service(TimeService.SERVICE_ID):
		_time = ServiceRegistry.get_port(TimeService.SERVICE_ID) as TimeService


func _resolve_effect_service() -> void:
	if _effects == null and ServiceRegistry.has_service(EffectService.SERVICE_ID):
		_effects = ServiceRegistry.get_port(EffectService.SERVICE_ID) as EffectService
