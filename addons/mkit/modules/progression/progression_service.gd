class_name ProgressionService
extends Saveable
## 说明：`ProgressionService` 是 成长系统 的运行时服务，负责集中处理该领域的跨节点规则和查询。
## 上游：通常由 GameBootstrap、ModuleBootstrap、Mkit 门面或其他领域服务创建或调用。
## 下游：会连接 ContentService、EventService、组件、定义资源或场景节点，不直接依赖具体游戏内容。
## 使用：当项目需要从多个节点共享同一套领域规则或查询入口时使用它。
## 示例：`ServiceRegistry.register_service(ProgressionService.SERVICE_ID, ProgressionService.new())`

## 当 `ProgressionService` 发生 `currency changed` 事件时发出，供 UI、音频、VFX、任务或测试订阅。
signal currency_changed(currency_id: String, amount: int)
## 当 `ProgressionService` 发生 `upgrade level changed` 事件时发出，供 UI、音频、VFX、任务或测试订阅。
signal upgrade_level_changed(upgrade_id: String, level: int)
## 当 `ProgressionService` 发生 `content unlocked` 事件时发出，供 UI、音频、VFX、任务或测试订阅。
signal content_unlocked(content_id: String)
## 服务注册 id，供 GameBootstrap、ModuleBootstrap、ServiceRegistry 和 Mkit 查找 `ProgressionService`。
const SERVICE_ID: String = "progression"
## ProgressionService 持有的全局进度状态；包含钱包、升级等级和解锁内容。
var state := ProgressionState.new()


func _ready() -> void:
	if save_id == "":
		save_id = "progression"


## 向当前集合或状态加入传入数据；重复项按该对象规则合并或覆盖。
func add_currency(currency_id: String, amount: int) -> void:
	if currency_id.strip_edges() == "":
		push_warning("ProgressionService.add_currency: currency_id is empty")
		return
	if amount == 0:
		return
	state.add_currency(currency_id, amount)
	currency_changed.emit(currency_id, state.get_currency(currency_id))


## 尝试扣除指定资源或货币；成功会更新余额，失败保持原状态。
func spend_currency(currency_id: String, amount: int) -> bool:
	if currency_id.strip_edges() == "":
		return false
	if amount <= 0:
		return false
	if not state.spend_currency(currency_id, amount):
		return false
	currency_changed.emit(currency_id, state.get_currency(currency_id))
	return true


## 读取当前对象中的 `currency`；未找到时返回 null、空集合或该 API 的默认值。
func get_currency(currency_id: String) -> int:
	if currency_id.strip_edges() == "":
		return 0
	return state.get_currency(currency_id)


## 用 GameplayContext 和当前运行时状态判断是否允许 `unlock`；失败原因由对应查询 API 提供。
func can_unlock(upgrade_id: String) -> bool:
	if upgrade_id.strip_edges() == "":
		return false
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


## 执行 `unlock_or_level_up` API；读取当前运行时状态，并通过返回值、signal 或事件报告结果。
func unlock_or_level_up(upgrade_id: String, context: GameplayContext = null) -> bool:
	if upgrade_id.strip_edges() == "":
		return false
	if not can_unlock(upgrade_id):
		return false
	var definition := get_definition(upgrade_id)
	if definition == null:
		return false
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


## 读取当前对象中的 `definition`；未找到时返回 null、空集合或该 API 的默认值。
func get_definition(upgrade_id: String) -> UpgradeDefinition:
	var content := Mkit.content()
	if content == null:
		return null
	return content.get_resource(upgrade_id) as UpgradeDefinition


func _apply_upgrade_effects(definition: UpgradeDefinition, context: GameplayContext) -> void:
	if definition.effects.is_empty():
		return
	var executor: EffectService = null
	executor = Mkit.effects()
	if executor == null:
		return
	var ctx := GameplayContext.from_context(context)
	executor.execute_many(definition.effects, ctx)


## 导出当前运行时状态给 SaveService；只包含恢复该对象所需字段。
func to_save_data() -> Dictionary:
	return state.to_save_data()


## 从 SaveService 读出的 payload 恢复运行时字段；缺失字段保留当前默认值。
func from_save_data(data: Dictionary) -> void:
	state.from_save_data(data)
