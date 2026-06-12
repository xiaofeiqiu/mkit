class_name AbilityInstance
extends RefCounted
## 说明：`AbilityInstance` 是 能力系统 的运行时实例，负责保存由定义资源派生出的可变状态。
## 上游：通常由同领域服务、controller、组件或内容资源创建或调用。
## 下游：会连接 mkit 的服务、组件、资源或事件管线，不直接依赖具体游戏内容。
## 使用：当项目需要在能力系统中复用这段契约或状态时使用它。
## 示例：`var instance := AbilityInstance.new()`

## 该能力实例来源的 AbilityDefinition id。
var definition_id: String = ""
## 拥有该运行时对象的节点；通常是发起能力、物品或状态的实体。
var owner: Node = null
## 距离下一次可回充或可施放的剩余秒数。
var cooldown_remaining: float = 0.0
## 当前可用层数；施放时减少，冷却周期结束后回充但不超过定义上限。
var current_charges: int = 1
## 运行时能力等级；可用于按等级缩放效果或消耗。
var runtime_level: int = 1
## 是否启用该运行逻辑；关闭后节点保留但不主动思考或执行。
var enabled: bool = true
## 能力实例上的临时覆盖值；key 由调用方约定，用于短期强化或削弱。
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
