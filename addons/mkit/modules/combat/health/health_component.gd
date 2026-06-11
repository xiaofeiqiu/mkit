class_name HealthComponent
extends SaveableComponent
## 说明：`HealthComponent` 是 生命与资源系统 的实体组件，负责挂在实体场景下保存状态并暴露局部能力。
## 上游：通常由实体根节点、控制器、状态机或领域服务创建或调用。
## 下游：会连接EventService、SaveService、controller 或实体展示层，不直接依赖具体游戏内容。
## 使用：当项目实体需要持有可保存或可被 controller 查询的局部状态时使用它。
## 示例：`var instance := HealthComponent.new()`

## 当 `HealthComponent` 发生 `health changed` 事件时发出，供 UI、音频、VFX、任务或测试订阅。
signal health_changed(current: float, max_value: float)
## 当 `HealthComponent` 发生 `damaged` 事件时发出，供 UI、音频、VFX、任务或测试订阅。
signal damaged(result: DamageResult)
## 当 `HealthComponent` 发生 `healed` 事件时发出，供 UI、音频、VFX、任务或测试订阅。
signal healed(amount: float, source: Node)
## 当 `HealthComponent` 发生 `died` 事件时发出，供 UI、音频、VFX、任务或测试订阅。
signal died(owner_entity: Node)
## 编辑器配置：`current_hp` 表示当前值，由 `HealthComponent` 的公开 API 读取或维护。
@export var current_hp: float = 100.0
## 编辑器配置：`destroy_on_death` 表示 `HealthComponent` 的字段值，由 `HealthComponent` 的公开 API 读取或维护。
@export var destroy_on_death: bool = false
## 运行时状态：`dead` 表示 `HealthComponent` 的字段值，由 `HealthComponent` 的公开 API 读取或维护。
var dead: bool = false
## 运行时状态：`stats` 表示 `HealthComponent` 的字段值，由 `HealthComponent` 的公开 API 读取或维护。
var stats: StatsComponent = null


func _ready() -> void:
	if owner != null:
		stats = EntityContract.get_component(owner, "StatsComponent") as StatsComponent
		if stats != null:
			stats.stat_changed.connect(_on_stat_changed)
	current_hp = min(current_hp, get_max_hp())


## 返回 `max_hp` 对应的数据或对象，并保持 `HealthComponent` 的领域契约一致。
func get_max_hp() -> float:
	if stats != null:
		return stats.get_stat_value("max_hp", 100.0)
	return 100.0


## 把输入数据或效果应用到目标对象，并保持 `HealthComponent` 的领域契约一致。
func apply_damage(result: DamageResult) -> void:
	if dead:
		return
	if result == null or result.was_evaded:
		return
	current_hp = max(0.0, current_hp - result.final_amount)
	result.was_lethal = current_hp <= 0.0
	_apply_on_hit_statuses(result)
	damaged.emit(result)
	health_changed.emit(current_hp, get_max_hp())
	var events := Mkit.events()
	if events != null:
		events.emit_domain_event(CombatEvents.damage_applied(result))
	if current_hp <= 0.0:
		die(result.source)


func _apply_on_hit_statuses(result: DamageResult) -> void:
	if result.status_applications.is_empty():
		return
	var controller := EntityContract.get_controller(owner, "StatusEffectController") as StatusEffectController
	if controller == null:
		return
	for entry: Dictionary in result.status_applications:
		var status_id := str(entry.get("status_id", ""))
		if status_id == "":
			continue
		controller.apply_status(
			status_id, result.source, int(entry.get("stacks", 1)), float(entry.get("duration", -1.0))
		)


## 执行 `heal` 对应的公开操作，并保持 `HealthComponent` 的领域契约一致。
func heal(amount: float, source: Node = null) -> void:
	if dead:
		return
	if amount <= 0:
		return
	current_hp = min(get_max_hp(), current_hp + amount)
	healed.emit(amount, source)
	health_changed.emit(current_hp, get_max_hp())


## 执行 `die` 对应的公开操作，并保持 `HealthComponent` 的领域契约一致。
func die(killer: Node = null) -> void:
	if dead:
		return
	dead = true
	current_hp = 0.0
	died.emit(owner)
	var identity := EntityContract.get_identity(owner)
	var entity_id: String = identity.entity_id if identity != null else str(owner.name)
	var events := Mkit.events()
	if events != null:
		events.emit_domain_event(CombatEvents.entity_died(entity_id, owner))
	if destroy_on_death:
		owner.queue_free()


## 执行 `revive` 对应的公开操作，并保持 `HealthComponent` 的领域契约一致。
func revive(percent: float = 1.0) -> void:
	dead = false
	current_hp = get_max_hp() * clamp(percent, 0.0, 1.0)
	health_changed.emit(current_hp, get_max_hp())


## 导出当前运行时状态，供 SaveService 写入存档，并保持 `HealthComponent` 的领域契约一致。
func to_save_data() -> Dictionary:
	return {"current_hp": current_hp, "dead": dead}


## 从 SaveService 读出的 payload 恢复运行时状态，并保持 `HealthComponent` 的领域契约一致。
func from_save_data(data: Dictionary) -> void:
	dead = bool(data.get("dead", dead))
	current_hp = clamp(float(data.get("current_hp", current_hp)), 0.0, get_max_hp())
	if dead:
		current_hp = 0.0
	health_changed.emit(current_hp, get_max_hp())


func _on_stat_changed(stat_id: String, old_value: float, new_value: float) -> void:
	if stat_id == "max_hp":
		current_hp = min(current_hp, new_value)
		health_changed.emit(current_hp, new_value)
