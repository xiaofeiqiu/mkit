class_name AbilityController
extends SaveableComponent
## 说明：`AbilityController` 是 能力系统 的实体控制器，负责协调实体组件、服务和运行时状态。
## 上游：通常由 EntityRoot、CommandReceiver、StateMachine、玩家输入或 AI 创建或调用。
## 下游：会连接组件、ActionService、EffectService、ContentService 和 EventService，不直接依赖具体游戏内容。
## 使用：当项目实体需要把输入、状态机和组件能力组合成可调用行为时使用它。
## 示例：`var instance := AbilityController.new()`

## 当 `AbilityController` 发生 `ability registered` 事件时发出，供 UI、音频、VFX、任务或测试订阅。
signal ability_registered(ability_id: String)
## 当 `AbilityController` 发生 `ability cast started` 事件时发出，供 UI、音频、VFX、任务或测试订阅。
signal ability_cast_started(ability_id: String)
## 当 `AbilityController` 发生 `ability cast finished` 事件时发出，供 UI、音频、VFX、任务或测试订阅。
signal ability_cast_finished(ability_id: String)
## 当 `AbilityController` 发生 `ability failed` 事件时发出，供 UI、音频、VFX、任务或测试订阅。
signal ability_failed(ability_id: String, reason: String)
## 当 `AbilityController` 发生 `cooldown started` 事件时发出，供 UI、音频、VFX、任务或测试订阅。
signal cooldown_started(ability_id: String, duration: float)
## 初始化时授予实体的 AbilityDefinition id 列表；每项需已在 ContentService 注册。
@export var starting_ability_ids: Array[String] = []
## 已实例化的能力表；key 为 ability id，value 为 AbilityInstance。
var abilities: Dictionary = {}
## 当前未结束的施放动作列表；施放完成或取消后移除。
var active_cast_actions: Array[GameAction] = []


func _ready() -> void:
	for id in starting_ability_ids:
		if id.strip_edges() == "":
			push_warning("AbilityController: ignoring empty starting ability id")
			continue
		register_ability(id)


func _process(delta: float) -> void:
	for instance: AbilityInstance in abilities.values():
		if instance != null:
			instance.tick(delta)


## 注册 `ability`，让后续查询或路由可以找到它，并保持 `AbilityController` 的领域契约一致。
func register_ability(ability_id: String) -> bool:
	if ability_id.strip_edges() == "":
		push_warning("AbilityController.register_ability: ability_id is empty")
		return false
	if abilities.has(ability_id):
		return true
	var definition := get_definition(ability_id)
	if definition == null:
		push_warning("AbilityController: definition not found: %s" % ability_id)
		return false
	var instance := AbilityInstance.new()
	instance.setup(definition, owner)
	abilities[ability_id] = instance
	ability_registered.emit(ability_id)
	return true


## 注销 `ability`，停止后续查询或路由使用它，并保持 `AbilityController` 的领域契约一致。
func unregister_ability(ability_id: String) -> void:
	abilities.erase(ability_id)


## 判断是否存在 `ability`，并保持 `AbilityController` 的领域契约一致。
func has_ability(ability_id: String) -> bool:
	return abilities.has(ability_id)


## 检查当前上下文是否允许 `cast`，并保持 `AbilityController` 的领域契约一致。
func can_cast(ability_id: String, context: GameplayContext) -> bool:
	return get_cast_failure_reason(ability_id, context) == ""


## 返回 `cast_failure_reason` 对应的数据或对象，并保持 `AbilityController` 的领域契约一致。
func get_cast_failure_reason(ability_id: String, context: GameplayContext) -> String:
	if context == null:
		return "missing_context"
	if not abilities.has(ability_id):
		return "not_registered: %s" % ability_id
	var instance := abilities[ability_id] as AbilityInstance
	if instance == null:
		return "invalid_ability_instance: %s" % ability_id
	if not instance.enabled:
		return "disabled: %s" % ability_id
	var definition := get_definition(ability_id)
	if definition == null:
		return "missing_definition: %s" % ability_id
	if not instance.is_cooldown_ready():
		return "on_cooldown: %s" % ability_id
	if not _has_enough_cost(definition):
		return "insufficient_%s" % definition.cost_type
	context.payload["ability_id"] = ability_id
	if not ConditionEvaluator.evaluate_all(definition.conditions, context):
		return ", ".join(ConditionEvaluator.collect_failures(definition.conditions, context))
	return ""


## 执行 `cast` 对应的公开操作，并保持 `AbilityController` 的领域契约一致。
func cast(ability_id: String, context: GameplayContext) -> bool:
	if context == null:
		ability_failed.emit(ability_id, "missing_context")
		return false
	var failure := get_cast_failure_reason(ability_id, context)
	if failure != "":
		ability_failed.emit(ability_id, failure)
		return false
	var definition := get_definition(ability_id)
	var instance := abilities[ability_id] as AbilityInstance
	if definition == null or instance == null:
		ability_failed.emit(ability_id, "invalid_ability_data")
		return false
	var action_runner: ActionService = null
	if definition.cast_time > 0.0:
		action_runner = _get_action_runner()
		if action_runner == null:
			ability_failed.emit(ability_id, "missing_action_runner")
			return false
	_pay_cost(definition)
	ability_cast_started.emit(ability_id)
	if definition.cast_time > 0.0:
		_start_cast_action(definition, context, action_runner)
	else:
		var instant := GameAction.new()
		instant.on_complete_effects = definition.effects
		instant.start(_build_action_context(context, definition))
		instant.complete()
		_start_cooldown(instance, definition)
		ability_cast_finished.emit(ability_id)
	return true


## 判断 `cooldown_ready` 当前是否成立，并保持 `AbilityController` 的领域契约一致。
func is_cooldown_ready(ability_id: String) -> bool:
	if not abilities.has(ability_id):
		return false
	return (abilities[ability_id] as AbilityInstance).is_cooldown_ready()


## 返回 `cooldown_remaining` 对应的数据或对象，并保持 `AbilityController` 的领域契约一致。
func get_cooldown_remaining(ability_id: String) -> float:
	if not abilities.has(ability_id):
		return 0.0
	return (abilities[ability_id] as AbilityInstance).cooldown_remaining


## 返回 `definition` 对应的数据或对象，并保持 `AbilityController` 的领域契约一致。
func get_definition(ability_id: String) -> AbilityDefinition:
	var content := Mkit.content()
	if content == null:
		return null
	return content.get_resource(ability_id) as AbilityDefinition


## 导出当前运行时状态，供 SaveService 写入存档，并保持 `AbilityController` 的领域契约一致。
func to_save_data() -> Dictionary:
	var learned: Array[String] = []
	var cooldowns: Dictionary = {}
	var charges: Dictionary = {}
	var recharge_durations: Dictionary = {}
	for ability_id in abilities.keys():
		var key := str(ability_id)
		learned.append(key)
		var instance := abilities[key] as AbilityInstance
		if instance != null and instance.cooldown_remaining > 0.0:
			cooldowns[key] = instance.cooldown_remaining
		if instance != null:
			charges[key] = instance.current_charges
			if instance.get_recharge_duration() > 0.0:
				recharge_durations[key] = instance.get_recharge_duration()
	learned.sort()
	return {"learned": learned, "cooldowns": cooldowns, "charges": charges, "recharge_durations": recharge_durations}


## 从 SaveService 读出的 payload 恢复运行时状态，并保持 `AbilityController` 的领域契约一致。
func from_save_data(data: Dictionary) -> void:
	abilities.clear()
	for ability_id in data.get("learned", []):
		register_ability(str(ability_id))
	var cooldowns: Dictionary = data.get("cooldowns", {})
	for ability_id in cooldowns.keys():
		var key := str(ability_id)
		if abilities.has(key):
			var instance := abilities[key] as AbilityInstance
			if instance != null:
				var remaining := max(0.0, float(cooldowns[ability_id]))
				instance.cooldown_remaining = remaining
				instance.set_recharge_duration(_restore_recharge_duration(key, data, remaining))
				if remaining > 0.0:
					instance.current_charges = 0
	var charges: Dictionary = data.get("charges", {})
	for ability_id in charges.keys():
		var key := str(ability_id)
		if abilities.has(key):
			var instance := abilities[key] as AbilityInstance
			var definition := get_definition(key)
			if instance != null and definition != null:
				instance.current_charges = clampi(int(charges[ability_id]), 0, max(1, definition.charges))


func _build_action_context(context: GameplayContext, definition: AbilityDefinition) -> ActionContext:
	var ctx := ActionContext.from_context(context)
	ctx.payload["ability_id"] = definition.ability_id
	return ctx


func _restore_recharge_duration(
	ability_id: String, data: Dictionary, fallback_remaining: float
) -> float:
	var recharge_durations: Dictionary = data.get("recharge_durations", {})
	if recharge_durations.has(ability_id):
		return max(0.0, float(recharge_durations[ability_id]))
	var definition := get_definition(ability_id)
	if definition != null and fallback_remaining > 0.0:
		return max(0.0, definition.cooldown)
	return 0.0


func _start_cooldown(instance: AbilityInstance, definition: AbilityDefinition) -> void:
	if instance == null or definition == null:
		return
	var stats: StatsComponent = null
	if owner != null:
		stats = EntityContract.get_component(owner, "StatsComponent") as StatsComponent
	var cdr := 0.0
	if stats != null:
		cdr = stats.get_stat_value("cooldown_reduction", 0.0)
	instance.start_cooldown(definition, cdr)
	cooldown_started.emit(definition.ability_id, instance.cooldown_remaining)


func _start_cast_action(
	definition: AbilityDefinition, context: GameplayContext, action_runner: ActionService
) -> void:
	if definition == null or context == null:
		var failed_id := definition.ability_id if definition != null else ""
		ability_failed.emit(failed_id, "invalid_cast_context")
		return
	if action_runner == null:
		ability_failed.emit(definition.ability_id, "missing_action_runner")
		return
	var action := CastAction.new()
	action.duration = definition.cast_time
	action.on_complete_effects = definition.effects
	action.completed.connect(
		func(_a: GameAction) -> void:
			active_cast_actions.erase(_a)
			var ability_instance := abilities.get(definition.ability_id, null) as AbilityInstance
			if ability_instance != null:
				_start_cooldown(ability_instance, definition)
			ability_cast_finished.emit(definition.ability_id)
	)
	action.cancelled.connect(
		func(_a: GameAction, reason: String) -> void:
			active_cast_actions.erase(_a)
			ability_failed.emit(definition.ability_id, "cast_cancelled:%s" % reason)
	)
	active_cast_actions.append(action)
	action_runner.start_action(action, _build_action_context(context, definition))


func _get_action_runner() -> ActionService:
	return Mkit.actions()


func _has_enough_cost(definition: AbilityDefinition) -> bool:
	if definition == null:
		return false
	if definition.cost_type == "none" or definition.cost_amount <= 0:
		return true
	if owner == null:
		return false
	var resources := (
		EntityContract.get_component(owner, "ResourcePoolComponent") as ResourcePoolComponent
	)
	if resources == null:
		return false
	return resources.has_resource(definition.cost_type, definition.cost_amount)


func _pay_cost(definition: AbilityDefinition) -> void:
	if definition == null:
		return
	if definition.cost_type == "none" or definition.cost_amount <= 0:
		return
	if owner == null:
		return
	var resources := (
		EntityContract.get_component(owner, "ResourcePoolComponent") as ResourcePoolComponent
	)
	if resources != null:
		resources.spend(definition.cost_type, definition.cost_amount)
