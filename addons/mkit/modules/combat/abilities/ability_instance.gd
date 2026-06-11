class_name AbilityInstance
extends RefCounted
## 说明：`AbilityInstance` 是 能力系统 的运行时实例，负责保存由定义资源派生出的可变状态。
## 上游：通常由同领域服务、controller、组件或内容资源创建或调用。
## 下游：会连接 mkit 的服务、组件、资源或事件管线，不直接依赖具体游戏内容。
## 使用：当项目需要在能力系统中复用这段契约或状态时使用它。
## 示例：`var instance := AbilityInstance.new()`

## 运行时状态：`definition_id` 表示稳定 id，由 `AbilityInstance` 的公开 API 读取或维护。
var definition_id: String = ""
## 运行时状态：`owner` 表示 `AbilityInstance` 的字段值，由 `AbilityInstance` 的公开 API 读取或维护。
var owner: Node = null
## 运行时状态：`cooldown_remaining` 表示冷却时间，由 `AbilityInstance` 的公开 API 读取或维护。
var cooldown_remaining: float = 0.0
## 运行时状态：`current_charges` 表示当前值，由 `AbilityInstance` 的公开 API 读取或维护。
var current_charges: int = 1
## 运行时状态：`runtime_level` 表示运行时数据，由 `AbilityInstance` 的公开 API 读取或维护。
var runtime_level: int = 1
## 运行时状态：`enabled` 表示是否启用，由 `AbilityInstance` 的公开 API 读取或维护。
var enabled: bool = true
## 运行时状态：`temporary_modifiers` 表示 `AbilityInstance` 的字段值，由 `AbilityInstance` 的公开 API 读取或维护。
var temporary_modifiers: Dictionary = {}
var _definition: AbilityDefinition = null
var _recharge_duration: float = 0.0


## 初始化运行时依赖和起始状态，并保持 `AbilityInstance` 的领域契约一致。
func setup(definition: AbilityDefinition, owner_entity: Node) -> void:
	definition_id = definition.ability_id
	owner = owner_entity
	current_charges = _max_charges(definition)
	cooldown_remaining = 0.0
	_recharge_duration = 0.0
	_definition = definition


## 执行 `tick` 对应的公开操作，并保持 `AbilityInstance` 的领域契约一致。
func tick(delta: float) -> void:
	if cooldown_remaining > 0.0:
		cooldown_remaining = max(0.0, cooldown_remaining - delta)
		if cooldown_remaining <= 0.0 and _definition != null:
			restore_charge(_definition)
			if current_charges < _max_charges(_definition) and _recharge_duration > 0.0:
				cooldown_remaining = _recharge_duration


## 判断 `cooldown_ready` 当前是否成立，并保持 `AbilityInstance` 的领域契约一致。
func is_cooldown_ready() -> bool:
	return current_charges > 0


## 返回 `recharge_duration` 对应的数据或对象，并保持 `AbilityInstance` 的领域契约一致。
func get_recharge_duration() -> float:
	return _recharge_duration


## 设置 `recharge_duration` 对应的数据或对象，并保持 `AbilityInstance` 的领域契约一致。
func set_recharge_duration(value: float) -> void:
	_recharge_duration = max(0.0, value)


## 启动 `cooldown` 流程，并保持 `AbilityInstance` 的领域契约一致。
func start_cooldown(definition: AbilityDefinition, cooldown_reduction: float = 0.0) -> void:
	var max_charges := _max_charges(definition)
	var final_cd := max(0.0, definition.cooldown * (1.0 - cooldown_reduction))
	_recharge_duration = final_cd
	current_charges = max(0, current_charges - 1)
	if final_cd <= 0.0:
		current_charges = max_charges
		cooldown_remaining = 0.0
		return
	if current_charges < max_charges:
		cooldown_remaining = final_cd
	else:
		cooldown_remaining = 0.0


## 执行 `restore_charge` 对应的公开操作，并保持 `AbilityInstance` 的领域契约一致。
func restore_charge(definition: AbilityDefinition) -> void:
	var max_charges := _max_charges(definition)
	current_charges = min(max_charges, current_charges + 1)
	if current_charges >= max_charges:
		cooldown_remaining = 0.0


func _max_charges(definition: AbilityDefinition) -> int:
	return max(1, definition.charges)
