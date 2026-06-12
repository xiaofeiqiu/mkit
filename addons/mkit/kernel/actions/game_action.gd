class_name GameAction
extends RefCounted
## 说明：`GameAction` 是动作管线的行为基类，负责统一启动、更新、取消、完成和附带效果触发。
## 上游：通常由需要前摇、持续时间、取消窗口或统一 effect 链的 controller、状态或内容资源创建。
## 下游：会通过 `EffectService` 触发配置好的 `GameEffect`，不直接依赖具体游戏内容。
## 使用：当行为需要跨帧生命周期、可取消流程或数据驱动效果链时使用；普通同步查询或数值变化可直接调用组件、领域服务或 `EffectService`。
## 示例：`var instance := GameAction.new()`

## 当 `GameAction` 发生 `completed` 事件时发出，供 UI、音频、VFX、任务或测试订阅。
signal completed(action: GameAction)
## 当 `GameAction` 发生 `cancelled` 事件时发出，供 UI、音频、VFX、任务或测试订阅。
signal cancelled(action: GameAction, reason: String)
## 引用的 action id；为空字符串表示未绑定，使用前应由调用方处理缺失情况。
var action_id: String = ""
## 当前执行上下文；动作启动后供阶段逻辑、条件和效果读取。
var context: ActionContext = null
## 动作已运行的秒数；每次 update 后累加，用于判断持续时间和阶段切换。
var elapsed: float = 0.0
## 动作是否已经完成；完成后 ActionService 会从 active_actions 中移除它。
var finished: bool = false
## 动作是否已经被取消；取消完成后不会再触发正常完成逻辑。
var cancelled_flag: bool = false
## 取消动作时可匹配的标签；用于按类型批量终止动作。
var cancel_tags: Array[String] = []
## 动作启动时按顺序执行的效果列表。
var on_start_effects: Array[GameEffect] = []
## 动作正常完成时按顺序执行的效果列表。
var on_complete_effects: Array[GameEffect] = []
## 动作被取消时按顺序执行的效果列表。
var on_cancel_effects: Array[GameEffect] = []
var _effect_service: EffectService = null


## 执行 `start` 对应的公开操作，并保持 `GameAction` 的领域契约一致。
func start(ctx: ActionContext) -> void:
	context = ctx
	elapsed = 0.0
	finished = false
	cancelled_flag = false
	_on_start()
	_fire_effects(on_start_effects + _resolve_effects(context))


## 推进当前对象的运行时状态，并保持 `GameAction` 的领域契约一致。
func update(delta: float) -> void:
	if finished or cancelled_flag:
		return
	elapsed += delta
	_on_update(delta)


## 取消当前或匹配条件的运行时流程，并保持 `GameAction` 的领域契约一致。
func cancel(reason: String = "") -> void:
	if finished or cancelled_flag:
		return
	cancelled_flag = true
	_on_cancel(reason)
	_fire_effects(on_cancel_effects)
	cancelled.emit(self, reason)


## 执行 `complete` 对应的公开操作，并保持 `GameAction` 的领域契约一致。
func complete() -> void:
	if finished or cancelled_flag:
		return
	finished = true
	_on_complete()
	_fire_effects(on_complete_effects + _resolve_effects(context))
	completed.emit(self)


## 判断 `finished` 当前是否成立，并保持 `GameAction` 的领域契约一致。
func is_finished() -> bool:
	return finished or cancelled_flag


## 检查当前上下文是否允许 `cancel_with`，并保持 `GameAction` 的领域契约一致。
func can_cancel_with(tag: String) -> bool:
	return cancel_tags.has(tag)


func _fire_effects(effects: Array[GameEffect]) -> void:
	if effects.is_empty():
		return
	var svc := _get_effect_service()
	if svc == null:
		return
	svc.execute_many(effects, context)


func _get_effect_service() -> EffectService:
	if _effect_service == null and ServiceRegistry.has_service(EffectService.SERVICE_ID):
		_effect_service = ServiceRegistry.get_port(EffectService.SERVICE_ID) as EffectService
	return _effect_service


func _resolve_effects(_ctx: ActionContext) -> Array[GameEffect]:
	return []


## 动作启动时的覆写 hook，并保持 `GameAction` 的领域契约一致。
func _on_start() -> void:
	pass


## 动作更新时的覆写 hook，并保持 `GameAction` 的领域契约一致。
func _on_update(delta: float) -> void:
	pass


## 动作取消时的覆写 hook，并保持 `GameAction` 的领域契约一致。
func _on_cancel(reason: String) -> void:
	pass


## 动作完成时的覆写 hook，并保持 `GameAction` 的领域契约一致。
func _on_complete() -> void:
	pass
